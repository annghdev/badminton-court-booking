CREATE OR ALTER PROCEDURE GetBookingScheduleForAdmin
    @FacilityId INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chuyển đổi thời gian hiện tại sang UTC+7
    DECLARE @CurrentDateTime DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time'; -- UTC+7
    DECLARE @CurrentTime TIME = CAST(@CurrentDateTime AS TIME);
    DECLARE @CurrentDate DATE = CAST(@CurrentDateTime AS DATE);
    DECLARE @TodayDayName VARCHAR(20) = DATENAME(WEEKDAY, @Date);

    WITH AllSlots AS (
        SELECT c.Id AS CourtId, 
               c.Name AS CourtName, 
               ts.Id AS TimeSlotId, 
               ts.StartTime, 
               ts.EndTime
        FROM Courts c
        CROSS JOIN TimeSlots ts
        WHERE c.FacilityId = @FacilityId
    ),
    ActiveHolds AS (
        SELECT CourtId, TimeSlotId, HoldId, HeldBy
        FROM (
            SELECT CourtId, TimeSlotId, Id AS HoldId, HeldBy,
                   ROW_NUMBER() OVER(PARTITION BY CourtId, TimeSlotId ORDER BY Id) AS rn
            FROM BookingHolds
            WHERE ExpiresAt > @CurrentDateTime
              AND (
                  (BookingType = 1 AND CAST(BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) = @Date)
                  OR (BookingType IN (2, 3) AND DayOfWeek = @TodayDayName 
                      AND CAST(BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= @Date
                      AND (EndAt IS NULL OR CAST(EndAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) >= @Date))
              )
        ) AS sub
        WHERE rn = 1
    ),
    ActiveBookings AS (
        SELECT bd.CourtId, 
               bd.TimeSlotId, 
               b.Status, 
               b.Type, 
               bd.BeginAt, 
               bd.EndAt, 
               bd.DayOfWeek,
               b.Id AS BookingId,
               bd.Id AS BookingDetailId
        FROM BookingDetails bd
        JOIN Bookings b ON bd.BookingId = b.Id
        WHERE b.Status NOT IN (5, 6)
          AND (
                (b.Type = 1 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) = @Date)
             OR (b.Type = 2 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= @Date 
                          AND CAST(bd.EndAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) >= @Date 
                          AND bd.DayOfWeek = @TodayDayName)
             OR (b.Type = 3 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= @Date 
                          AND bd.DayOfWeek = @TodayDayName)
          )
    )
    SELECT 
        s.CourtId,
        s.CourtName,
        s.TimeSlotId,
        s.StartTime,
        s.EndTime,
        CASE 
            WHEN h.HoldId IS NOT NULL THEN 2
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 1) THEN 3
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 2) THEN 4
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 3) THEN 6
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 4) THEN 5
            WHEN s.StartTime < @CurrentTime AND @Date <= @CurrentDate THEN 0
            WHEN @Date < @CurrentDate THEN 0
            ELSE 1
        END AS [Status],
        h.HoldId,
        h.HeldBy,
        ab.BookingId,
        ab.BookingDetailId
    FROM AllSlots s
    LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId AND h.TimeSlotId = s.TimeSlotId
    LEFT JOIN ActiveBookings ab ON ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId
    ORDER BY s.CourtId, s.TimeSlotId;
END;
GO

CREATE OR ALTER PROCEDURE GetBookingScheduleForCourtInRange
    @CourtId INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartDate > @EndDate
    BEGIN
        SELECT 0 AS result, N'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc.' AS Message;
        RETURN;
    END

    DECLARE @CurrentDateTime DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time';
    DECLARE @CurrentTime TIME = CAST(@CurrentDateTime AS TIME);
    DECLARE @CurrentDate DATE = CAST(@CurrentDateTime AS DATE);

    WITH DateRange AS (
        SELECT @StartDate AS ScheduleDate
        UNION ALL
        SELECT DATEADD(DAY, 1, ScheduleDate)
        FROM DateRange
        WHERE ScheduleDate < @EndDate
    ),
    AllSlots AS (
        SELECT 
            dr.ScheduleDate,
            DATENAME(WEEKDAY, dr.ScheduleDate) AS DayOfWeek,
            c.Id AS CourtId,
            c.Name AS CourtName,
            ts.Id AS TimeSlotId,
            ts.StartTime,
            ts.EndTime
        FROM DateRange dr
        CROSS JOIN Courts c
        CROSS JOIN TimeSlots ts
        WHERE c.Id = @CourtId
    ),
    ActiveHolds AS (
        SELECT 
            s.ScheduleDate,
            s.CourtId,
            s.TimeSlotId,
            h.HoldId,
            h.HeldBy
        FROM AllSlots s
        OUTER APPLY (
            SELECT TOP 1 
                bh.Id AS HoldId,
                bh.HeldBy
            FROM BookingHolds bh
            WHERE bh.CourtId = s.CourtId
              AND bh.TimeSlotId = s.TimeSlotId
              AND bh.ExpiresAt > @CurrentDateTime
              AND (
                  (bh.BookingType = 1 AND CAST(bh.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) = s.ScheduleDate)
                  OR (bh.BookingType IN (2, 3) AND bh.DayOfWeek = s.DayOfWeek 
                      AND CAST(bh.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= s.ScheduleDate
                      AND (bh.EndAt IS NULL OR CAST(bh.EndAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) >= s.ScheduleDate))
              )
            ORDER BY bh.Id DESC
        ) h
    ),
    ActiveBookings AS (
        SELECT 
            s.ScheduleDate,
            s.CourtId,
            s.TimeSlotId,
            ab.Status,
            ab.Type,
            ab.BeginAt,
            CAST(ab.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATETIME) AS BeginAtLocal, -- Thêm cột local để debug
            ab.EndAt,
            ab.DayOfWeek,
            ab.BookingId,
            ab.BookingDetailId
        FROM AllSlots s
        OUTER APPLY (
            SELECT TOP 1 
                b.Status,
                b.Type,
                bd.BeginAt,
                bd.EndAt,
                bd.DayOfWeek,
                b.Id AS BookingId,
                bd.Id AS BookingDetailId
            FROM BookingDetails bd
            JOIN Bookings b ON bd.BookingId = b.Id
            WHERE b.Status NOT IN (5, 6)
              AND bd.CourtId = s.CourtId
              AND bd.TimeSlotId = s.TimeSlotId
              AND (
                  (b.Type = 1 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) = s.ScheduleDate)
                  OR (b.Type = 2 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= s.ScheduleDate 
                              AND CAST(bd.EndAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) >= s.ScheduleDate 
                              AND bd.DayOfWeek = s.DayOfWeek)
                  OR (b.Type = 3 AND CAST(bd.BeginAt AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time' AS DATE) <= s.ScheduleDate 
                              AND bd.DayOfWeek = s.DayOfWeek)
              )
            ORDER BY b.Id DESC
        ) ab
    )
    SELECT 
        s.ScheduleDate,
        s.DayOfWeek,
        s.CourtId,
        s.CourtName,
        s.TimeSlotId,
        s.StartTime,
        s.EndTime,
        CASE 
            WHEN h.HoldId IS NOT NULL THEN 2
            WHEN ab.Status = 1 THEN 3
            WHEN ab.Status = 2 THEN 4
            WHEN ab.Status = 3 THEN 6
            WHEN ab.Status = 4 THEN 5
            WHEN s.StartTime < @CurrentTime AND s.ScheduleDate = @CurrentDate THEN 0
            WHEN s.ScheduleDate < @CurrentDate THEN 0
            ELSE 1
        END AS [Status],
        h.HoldId,
        h.HeldBy,
        ab.BookingId,
        ab.BookingDetailId,
        ab.BeginAtLocal -- Thêm để kiểm tra
    FROM AllSlots s
    LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId 
                           AND h.TimeSlotId = s.TimeSlotId 
                           AND h.ScheduleDate = s.ScheduleDate
    LEFT JOIN ActiveBookings ab ON ab.CourtId = s.CourtId 
                                AND ab.TimeSlotId = s.TimeSlotId 
                                AND ab.ScheduleDate = s.ScheduleDate
    ORDER BY s.ScheduleDate, s.TimeSlotId;
END;
GO