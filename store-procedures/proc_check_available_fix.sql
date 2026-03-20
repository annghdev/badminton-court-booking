CREATE OR ALTER PROCEDURE CheckBookingHold
    @CourtId INT,
    @TimeSlotId INT,
    @BookingType INT,
    @BeginAt DATETIMEOFFSET,
    @EndAt DATETIMEOFFSET = NULL,
    @DayOfWeek VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentDateTime DATETIMEOFFSET = SYSDATETIMEOFFSET() AT TIME ZONE 'SE Asia Standard Time';

	IF @BeginAt IS NULL OR @BeginAt < @CurrentDateTime
		BEGIN
			SELECT 0 AS result, N'Không thể chọn lịch trong quá khứ' AS Message;
			RETURN;
		END
    DECLARE @EffectiveDayOfWeek VARCHAR(10) = @DayOfWeek;
    IF @DayOfWeek IS NULL
    BEGIN
        SET @EffectiveDayOfWeek = DATENAME(WEEKDAY, @BeginAt);
    END

    IF @BookingType IN (2, 3) AND @EffectiveDayOfWeek IS NULL
    BEGIN
        SELECT 0 AS result, N'Đối với đặt cố định, DayOfWeek không được NULL.' AS Message;
        RETURN;
    END

    DECLARE @FirstMatchingDate DATE;
    SET @FirstMatchingDate = CAST(@BeginAt AS DATE);
    WHILE DATENAME(WEEKDAY, @FirstMatchingDate) != @EffectiveDayOfWeek
    BEGIN
        SET @FirstMatchingDate = DATEADD(DAY, 1, @FirstMatchingDate);
    END

    IF EXISTS (
        SELECT 1 
        FROM BookingHolds
        WHERE CourtId = @CourtId
          AND TimeSlotId = @TimeSlotId
          AND ExpiresAt > @CurrentDateTime
          AND (
              (@BookingType = 1 AND BookingType = 1 AND CAST(BeginAt AS DATE) = CAST(@BeginAt AS DATE))
              OR (@BookingType = 2 AND (
                  (BookingType = 1 AND CAST(BeginAt AS DATE) BETWEEN CAST(@BeginAt AS DATE) AND CAST(@EndAt AS DATE)
                      AND DATENAME(WEEKDAY, BeginAt) = @EffectiveDayOfWeek)
                  OR (BookingType = 2 AND DayOfWeek = @EffectiveDayOfWeek 
                      AND CAST(BeginAt AS DATE) <= CAST(@EndAt AS DATE)
                      AND (EndAt IS NULL OR CAST(EndAt AS DATE) >= CAST(@BeginAt AS DATE)))
              ))
              OR (@BookingType = 3 AND (
                  (BookingType = 1 AND CAST(BeginAt AS DATE) >= CAST(@FirstMatchingDate AS DATE)
                      AND DATENAME(WEEKDAY, BeginAt) = @EffectiveDayOfWeek)
                  OR (BookingType IN (2, 3) AND DayOfWeek = @EffectiveDayOfWeek 
                      AND CAST(BeginAt AS DATE) >= CAST(@FirstMatchingDate AS DATE)
                      AND (EndAt IS NULL OR CAST(EndAt AS DATE) >= CAST(@FirstMatchingDate AS DATE)))
              ))
          )
    )
    BEGIN
        SELECT 0 AS result, N'Không thể giữ lịch, đã có người giữ lịch trước đó.' AS Message;
        RETURN;
    END

    IF EXISTS (
        SELECT 1 
        FROM BookingDetails bd
        JOIN Bookings b ON bd.BookingId = b.Id
        WHERE bd.CourtId = @CourtId
          AND bd.TimeSlotId = @TimeSlotId
          AND b.Status NOT IN (4, 5, 6)
          AND (
              (@BookingType = 1 AND (
                  (b.Type = 1 AND CAST(bd.BeginAt AS DATE) = CAST(@BeginAt AS DATE))
                  OR (b.Type = 2 AND CAST(bd.BeginAt AS DATE) <= CAST(@BeginAt AS DATE)
                             AND CAST(bd.EndAt AS DATE) >= CAST(@BeginAt AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
                  OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= CAST(@BeginAt AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
              ))
              OR (@BookingType = 2 AND (
                  (b.Type = 1 AND CAST(bd.BeginAt AS DATE) BETWEEN CAST(@BeginAt AS DATE) AND CAST(@EndAt AS DATE)
                          AND DATENAME(WEEKDAY, bd.BeginAt) = @EffectiveDayOfWeek)
                  OR (b.Type = 2 AND CAST(bd.EndAt AS DATE) >= CAST(@BeginAt AS DATE)
                             AND CAST(bd.BeginAt AS DATE) <= CAST(@EndAt AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
                  OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= CAST(@EndAt AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
              ))
              OR (@BookingType = 3 AND (
                  (b.Type = 1 AND CAST(bd.BeginAt AS DATE) >= CAST(@FirstMatchingDate AS DATE)
                          AND DATENAME(WEEKDAY, bd.BeginAt) = @EffectiveDayOfWeek)
                  OR (b.Type = 2 AND CAST(bd.EndAt AS DATE) >= CAST(@FirstMatchingDate AS DATE)
                             AND CAST(bd.BeginAt AS DATE) <= CAST(@FirstMatchingDate AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
                  OR (b.Type = 3 AND CAST(bd.BeginAt AS DATE) <= CAST(@FirstMatchingDate AS DATE)
                             AND bd.DayOfWeek = @EffectiveDayOfWeek)
              ))
          )
    )
    BEGIN
        SELECT 0 AS result, N'Không thể giữ lịch, đã có lịch đặt giao thoa.' AS Message;
        RETURN;
    END

    SELECT 1 AS result, N'Có thể giữ lịch' AS Message;
END;
GO