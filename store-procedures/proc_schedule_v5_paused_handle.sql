USE FocusBadminton
GO

CREATE OR ALTER PROCEDURE GetAllCourtScheduleInDay
    @FacilityId INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Xác định ngày và giờ hiện tại theo múi giờ Việt Nam
    DECLARE @TodayDayName VARCHAR(20) = DATENAME(WEEKDAY, @Date);
    DECLARE @CurrentTime TIME = CONVERT(TIME, SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
    DECLARE @CurrentDate DATE = CONVERT(DATE, SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');

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
            WHERE ExpiresAt > SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time'
              AND (
                  (BookingType = 1 AND CAST(BeginAt AS DATE) = @Date)
                  OR (BookingType IN (2, 3) AND DayOfWeek = @TodayDayName 
                      AND CAST(BeginAt AS DATE) <= @Date
                      AND (EndAt IS NULL OR CAST(EndAt AS DATE) >= @Date))
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
                (b.Type = 1 AND CAST(bd.BeginAt AS DATE) = @Date)
             OR (b.Type = 2 AND CAST(bd.BeginAt AS DATE) <= @Date 
                          AND CAST(bd.EndAt AS DATE) >= @Date 
                          AND bd.DayOfWeek = @TodayDayName)
             OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= @Date 
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
            WHEN h.HoldId IS NOT NULL THEN 2 -- Đang giữ
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab WHERE ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId AND ab.Status = 2) THEN 4 -- Đã đặt (đã duyệt)
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab WHERE ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId AND ab.Status = 1) THEN 3 -- Đang đặt (chưa duyệt)
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab WHERE ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId AND ab.Status = 4) THEN 5 -- Đã kết thúc
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab WHERE ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId AND ab.Status = 3) THEN 6 -- Tạm ngưng
            WHEN s.StartTime < @CurrentTime AND @Date <= @CurrentDate THEN 0 -- Quá thời gian hiện tại
            WHEN @Date < @CurrentDate THEN 0 -- Ngày quá khứ
            ELSE 1 -- Trống
        END AS [Status],
        h.HoldId,
        h.HeldBy,
        STRING_AGG(CAST(ab.BookingId AS VARCHAR), ',') AS BookingIds,
        STRING_AGG(CAST(ab.BookingDetailId AS VARCHAR), ',') AS BookingDetailIds
    FROM AllSlots s
    LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId AND h.TimeSlotId = s.TimeSlotId
    LEFT JOIN ActiveBookings ab ON ab.CourtId = s.CourtId AND ab.TimeSlotId = s.TimeSlotId
    GROUP BY s.CourtId, s.CourtName, s.TimeSlotId, s.StartTime, s.EndTime, h.HoldId, h.HeldBy
    ORDER BY s.CourtId, s.TimeSlotId;
END;
GO

CREATE OR ALTER PROCEDURE GetSingleCourtScheduleInRange
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

    DECLARE @CurrentTime TIME = CONVERT(TIME, SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');
    DECLARE @CurrentDate DATE = CONVERT(DATE, SYSDATETIMEOFFSET() AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time');

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
              AND bh.ExpiresAt > SYSDATETIMEOFFSET()
              AND (
                  (bh.BookingType = 1 AND CAST(bh.BeginAt AS DATE) = s.ScheduleDate)
                  OR (bh.BookingType IN (2, 3) AND bh.DayOfWeek = s.DayOfWeek 
                      AND CAST(bh.BeginAt AS DATE) <= s.ScheduleDate
                      AND (bh.EndAt IS NULL OR CAST(bh.EndAt AS DATE) >= s.ScheduleDate))
              )
            ORDER BY bh.Id DESC
        ) h
    ),
    ActiveBookings AS (
        SELECT 
            bd.CourtId,
            bd.TimeSlotId,
            b.Status,
            b.Type,
            bd.BeginAt,
            bd.EndAt,
            bd.DayOfWeek,
            b.Id AS BookingId,
            bd.Id AS BookingDetailId,
            CAST(bd.BeginAt AS DATE) AS ScheduleDate
        FROM BookingDetails bd
        JOIN Bookings b ON bd.BookingId = b.Id
        WHERE b.Status NOT IN (5, 6)
          AND bd.CourtId = @CourtId
          AND (
                (b.Type = 1 AND CAST(bd.BeginAt AS DATE) BETWEEN @StartDate AND @EndDate)
             OR (b.Type = 2 AND CAST(bd.BeginAt AS DATE) <= @EndDate 
                          AND CAST(bd.EndAt AS DATE) >= @StartDate)
             OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= @EndDate)
          )
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
        WHEN h.HoldId IS NOT NULL THEN 2 -- Đang giữ
        WHEN MAX(CASE WHEN ab.Status = 2 THEN 1 ELSE 0 END) = 1 THEN 4 -- Đã đặt (đã duyệt)
        WHEN MAX(CASE WHEN ab.Status = 1 THEN 1 ELSE 0 END) = 1 THEN 3 -- Đang đặt (chưa duyệt)
        WHEN MAX(CASE WHEN ab.Status = 4 THEN 1 ELSE 0 END) = 1 THEN 5 -- Đã kết thúc
        WHEN MAX(CASE WHEN ab.Status = 3 THEN 1 ELSE 0 END) = 1 THEN 6 -- Tạm ngưng
        WHEN s.StartTime < @CurrentTime AND s.ScheduleDate = @CurrentDate THEN 0 -- Quá thời gian hiện tại
        WHEN s.ScheduleDate < @CurrentDate THEN 0 -- Ngày quá khứ
        ELSE 1 -- Trống
    END AS [Status],
    h.HoldId,
    h.HeldBy,
    STRING_AGG(CASE WHEN ab.Status IN (1,2,3,4) THEN CAST(ab.BookingId AS VARCHAR) ELSE NULL END, ',') AS BookingIds,
    STRING_AGG(CASE WHEN ab.Status IN (1,2,3,4) THEN CAST(ab.BookingDetailId AS VARCHAR) ELSE NULL END, ',') AS BookingDetailIds
FROM AllSlots s
LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId 
                       AND h.TimeSlotId = s.TimeSlotId 
                       AND h.ScheduleDate = s.ScheduleDate
LEFT JOIN ActiveBookings ab ON ab.CourtId = s.CourtId 
                            AND ab.TimeSlotId = s.TimeSlotId 
                            AND (
                                (ab.Type = 1 AND CAST(ab.BeginAt AS DATE) = s.ScheduleDate)
                                OR (ab.Type IN (2, 3) AND s.DayOfWeek = ab.DayOfWeek 
                                    AND s.ScheduleDate >= CAST(ab.BeginAt AS DATE) 
                                    AND (ab.EndAt IS NULL OR s.ScheduleDate <= CAST(ab.EndAt AS DATE)))
                            )
GROUP BY s.ScheduleDate, s.DayOfWeek, s.CourtId, s.CourtName, s.TimeSlotId, s.StartTime, s.EndTime, h.HoldId, h.HeldBy
ORDER BY s.ScheduleDate, s.TimeSlotId;
END;
GO

EXEC GetSingleCourtScheduleInRange
    @CourtId = 1, 
    @StartDate = '2025-03-11', 
    @EndDate = '2025-03-13';


EXEC GetSingleCourtScheduleInDay
    @CourtId = 1, 
    @Date = '2025-03-11';