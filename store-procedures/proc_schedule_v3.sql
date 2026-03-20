use FocusBadminton
go
-----------------------------------------------------
-- Procedure: Lấy lịch đặt sân cho Admin
-----------------------------------------------------
CREATE OR ALTER PROCEDURE GetBookingScheduleForAdmin
    @FacilityId INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Xác định tên ngày trong tuần của @Date (ví dụ: Monday, Tuesday,...)
    DECLARE @TodayDayName VARCHAR(20) = DATENAME(WEEKDAY, @Date);
    DECLARE @CurrentTime TIME = CAST(SYSDATETIMEOFFSET() AS TIME);
    DECLARE @CurrentDate DATE = CAST(SYSDATETIMEOFFSET() AS DATE);

    -- Tập hợp tất cả các sân và khung giờ của cơ sở
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
    -- Lấy các record giữ sân (BookingHolds) đang hoạt động cho ngày có DayOfWeek khớp
ActiveHolds AS (
        SELECT CourtId, TimeSlotId, HoldId, HeldBy
        FROM (
            SELECT CourtId, TimeSlotId, Id AS HoldId, HeldBy,
                   ROW_NUMBER() OVER(PARTITION BY CourtId, TimeSlotId ORDER BY Id) AS rn
            FROM BookingHolds
            WHERE ExpiresAt > SYSDATETIMEOFFSET()
              AND (
                  -- BookingType = 1: Chỉ hiển thị nếu ngày @Date khớp với BeginAt
                  (BookingType = 1 AND CAST(BeginAt AS DATE) = @Date)
                  -- BookingType = 2 hoặc 3: Kiểm tra DayOfWeek và khoảng thời gian
                  OR (BookingType IN (2, 3) AND DayOfWeek = @TodayDayName 
                      AND CAST(BeginAt AS DATE) <= @Date
                      AND (EndAt IS NULL OR CAST(EndAt AS DATE) >= @Date))
              )
        ) AS sub
        WHERE rn = 1
    ),
    -- Lấy các booking đã được đặt (trừ trạng thái hủy) cho 3 loại đặt
    ActiveBookings AS (
        SELECT bd.CourtId, bd.TimeSlotId, b.Status, b.Type, bd.BeginAt, bd.EndAt, bd.DayOfWeek
        FROM BookingDetails bd
        JOIN Bookings b ON bd.BookingId = b.Id
        WHERE b.Status NOT IN (5,6)  -- Loại trừ trạng thái hủy
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
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 1) THEN 3 -- Đang đặt (chưa duyệt)
			WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 2) THEN 4 -- Đã đặt (đã duyệt)
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 3) THEN 6 -- Tạm ngưng
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 4) THEN 5 -- Đã kết thúc
			WHEN s.StartTime < @CurrentTime and @Date <= @CurrentDate THEN 0 -- quá thời gian hiện tại 
			WHEN @Date < @CurrentDate THEN 0
            ELSE 1 -- Trống
        END AS [Status],
        h.HoldId,
        h.HeldBy
    FROM AllSlots s
    LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId AND h.TimeSlotId = s.TimeSlotId
    ORDER BY s.CourtId, s.TimeSlotId;
END;
GO

CREATE OR ALTER PROCEDURE GetBookingScheduleForCourt
    @CourtId INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xác định tên ngày trong tuần của @Date (ví dụ: Monday, Tuesday, ...)
    DECLARE @TodayDayName VARCHAR(20) = DATENAME(WEEKDAY, @Date);
    DECLARE @CurrentTime TIME = CAST(SYSDATETIMEOFFSET() AS TIME);
    DECLARE @CurrentDate DATE = CAST(SYSDATETIMEOFFSET() AS DATE);
    
    -- Lấy tất cả các khung giờ của sân (Court)
    WITH AllSlots AS (
        SELECT
            @CourtId AS CourtId,
            c.Name AS CourtName,
            ts.Id AS TimeSlotId,
            ts.StartTime,
            ts.EndTime
        FROM Courts c
        CROSS JOIN TimeSlots ts
        WHERE c.Id = @CourtId
    ),
    -- Lấy các record giữ sân (BookingHolds) đang hoạt động cho ngày có DayOfWeek khớp
ActiveHolds AS (
        SELECT CourtId, TimeSlotId, HoldId, HeldBy
        FROM (
            SELECT CourtId, TimeSlotId, Id AS HoldId, HeldBy,
                   ROW_NUMBER() OVER(PARTITION BY CourtId, TimeSlotId ORDER BY Id) AS rn
            FROM BookingHolds
            WHERE ExpiresAt > SYSDATETIMEOFFSET()
              AND (
                  -- BookingType = 1: Chỉ hiển thị nếu ngày @Date khớp với BeginAt
                  (BookingType = 1 AND CAST(BeginAt AS DATE) = @Date)
                  -- BookingType = 2 hoặc 3: Kiểm tra DayOfWeek và khoảng thời gian
                  OR (BookingType IN (2, 3) AND DayOfWeek = @TodayDayName 
                      AND CAST(BeginAt AS DATE) <= @Date
                      AND (EndAt IS NULL OR CAST(EndAt AS DATE) >= @Date))
              )
        ) AS sub
        WHERE rn = 1
    ),
    -- Lấy các booking đã đặt (trừ trạng thái hủy) cho sân đó
    ActiveBookings AS (
        SELECT bd.CourtId,
               bd.TimeSlotId,
               b.Status,
               b.Type,
               bd.BeginAt,
               bd.EndAt,
               bd.DayOfWeek
        FROM BookingDetails bd
        JOIN Bookings b ON bd.BookingId = b.Id
        WHERE b.Status NOT IN (5,6)  -- Loại trừ trạng thái hủy
          AND bd.CourtId = @CourtId
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
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 1) THEN 3 -- Đang đặt (chưa duyệt)
			WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 2) THEN 4 -- Đã đặt (đã duyệt)
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 3) THEN 6 -- Tạm ngưng
            WHEN EXISTS (SELECT 1 FROM ActiveBookings ab 
                         WHERE ab.CourtId = s.CourtId 
                           AND ab.TimeSlotId = s.TimeSlotId 
                           AND ab.Status = 4) THEN 5 -- Đã kết thúc
			WHEN s.StartTime < @CurrentTime and @Date <= @CurrentDate THEN 0 -- quá thời gian hiện tại 
			WHEN @Date < @CurrentDate THEN 0
            ELSE 1 -- Trống
        END AS [Status],
        h.HoldId,
        h.HeldBy
    FROM AllSlots s
    LEFT JOIN ActiveHolds h ON h.CourtId = s.CourtId AND h.TimeSlotId = s.TimeSlotId
    ORDER BY s.TimeSlotId;
END;
GO

CREATE OR ALTER PROCEDURE GetBookingScheduleForCourtInRange
    @CourtId INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nếu @StartDate lớn hơn @EndDate
    IF @StartDate > @EndDate
    BEGIN
        SELECT 0 AS result, N'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc.' AS Message;
        RETURN;
    END

    -- Xác định thời gian hiện tại
    DECLARE @CurrentTime TIME = CAST(SYSDATETIMEOFFSET() AS TIME);
    DECLARE @CurrentDate DATE = CAST(SYSDATETIMEOFFSET() AS DATE);

    -- Tạo danh sách tất cả các ngày trong khoảng [@StartDate, @EndDate]
    WITH DateRange AS (
        SELECT @StartDate AS ScheduleDate
        UNION ALL
        SELECT DATEADD(DAY, 1, ScheduleDate)
        FROM DateRange
        WHERE ScheduleDate < @EndDate
    ),
    -- Tạo danh sách tất cả các khung giờ cho sân và ngày
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
    -- Lấy các record giữ sân (BookingHolds) đang hoạt động
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
                  -- BookingType = 1: Ngày bắt đầu khớp với ScheduleDate
                  (bh.BookingType = 1 AND CAST(bh.BeginAt AS DATE) = s.ScheduleDate)
                  -- BookingType = 2 hoặc 3: Kiểm tra DayOfWeek và khoảng thời gian
                  OR (bh.BookingType IN (2, 3) AND bh.DayOfWeek = s.DayOfWeek 
                      AND CAST(bh.BeginAt AS DATE) <= s.ScheduleDate
                      AND (bh.EndAt IS NULL OR CAST(bh.EndAt AS DATE) >= s.ScheduleDate))
              )
            ORDER BY bh.Id DESC
        ) h
    ),
    -- Lấy các booking đã đặt (trừ trạng thái hủy)
    ActiveBookings AS (
        SELECT 
            s.ScheduleDate,
            s.CourtId,
            s.TimeSlotId,
            ab.Status,
            ab.Type,
            ab.BeginAt,
            ab.EndAt,
            ab.DayOfWeek
        FROM AllSlots s
        OUTER APPLY (
            SELECT TOP 1 
                b.Status,
                b.Type,
                bd.BeginAt,
                bd.EndAt,
                bd.DayOfWeek
            FROM BookingDetails bd
            JOIN Bookings b ON bd.BookingId = b.Id
            WHERE b.Status NOT IN (5, 6)  -- Loại trừ trạng thái hủy
              AND bd.CourtId = s.CourtId
              AND bd.TimeSlotId = s.TimeSlotId
              AND (
                  -- Type = 1: Ngày bắt đầu khớp với ScheduleDate
                  (b.Type = 1 AND CAST(bd.BeginAt AS DATE) = s.ScheduleDate)
                  -- Type = 2: Trong khoảng thời gian và DayOfWeek khớp
                  OR (b.Type = 2 AND CAST(bd.BeginAt AS DATE) <= s.ScheduleDate 
                              AND CAST(bd.EndAt AS DATE) >= s.ScheduleDate 
                              AND bd.DayOfWeek = s.DayOfWeek)
                  -- Type = 3: Bắt đầu trước ScheduleDate và DayOfWeek khớp
                  OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= s.ScheduleDate 
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
            WHEN h.HoldId IS NOT NULL THEN 2 -- Đang giữ
            WHEN ab.Status = 1 THEN 3 -- Đang đặt (chưa duyệt)
            WHEN ab.Status = 2 THEN 4 -- Đã đặt (đã duyệt)
            WHEN ab.Status = 3 THEN 6 -- Tạm ngưng
            WHEN ab.Status = 4 THEN 5 -- Đã kết thúc
            WHEN s.StartTime < @CurrentTime AND s.ScheduleDate = @CurrentDate THEN 0 -- Quá thời gian hiện tại
            WHEN s.ScheduleDate < @CurrentDate THEN 0 -- Ngày quá khứ
            ELSE 1 -- Trống
        END AS [Status],
        h.HoldId,
        h.HeldBy
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

exec GetBookingScheduleForAdmin 1, '20250303';
exec GetBookingScheduleForCourt 1, '20250303';



exec CheckBookingHold 3,1,2,'20250201','20250403', 'Tuesday';
exec CheckBookingHold 1,1,2,'20250201','20250330', 'Monday';
exec CheckBookingHold 3,1,3,'20250302',null, 'Sunday';
exec CheckBookingHold 1,1,1,'20250304',null, 'Monday';
exec CheckBookingHold 4,1,3,'20250302',null, 'Sunday';
exec CheckBookingHold 4,1,3,'20250304',null, 'Sunday';

exec CheckBookingHold 1,1,1,'20250224',null, 'Monday';

EXEC CheckBookingHold 
    @CourtId = 4, 
    @TimeSlotId = 1, 
    @BookingType = 1, 
    @BeginAt = '2025-03-04', 
    @EndAt = NULL, 
    @DayOfWeek = NULL;

SELECT * 
FROM BookingHolds
WHERE CourtId = 3
  AND TimeSlotId = 1
  AND DayOfWeek = 'Tuesday'
  AND ExpiresAt > SYSDATETIMEOFFSET();

SELECT bd.*, b.*
FROM BookingDetails bd
JOIN Bookings b ON bd.BookingId = b.Id
WHERE bd.CourtId = 3
  AND bd.TimeSlotId = 1
  AND bd.DayOfWeek = 'Tuesday'
  AND b.Status NOT IN (4, 5, 6);

--lấy lịch của 1 sân từ ngày đến ngày
EXEC GetBookingScheduleForCourtInRange 
    @CourtId = 1, 
    @StartDate = '2025-03-03', 
    @EndDate = '2025-03-03';

EXEC GetBookingScheduleForCourt
    @CourtId = 1, 
    @Date = '2025-03-03';