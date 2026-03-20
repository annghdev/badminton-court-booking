use FocusBadminton
-- Tạo tài khoản cho 4 thành viên team 1
INSERT INTO AspNetUsers (Id, PersonalPoints, RewardPoints, Avatar, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, DeleteDate, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount)
VALUES 
('user-1', 100, 50, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL, NULL, 'user1', 'USER1', 'user1@example.com', 'USER1@EXAMPLE.COM', 1, NULL, NULL, NULL, '123456789', 1, 0, NULL, 1, 0),
('user-2', 120, 60, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL, NULL, 'user2', 'USER2', 'user2@example.com', 'USER2@EXAMPLE.COM', 1, NULL, NULL, NULL, '987654321', 1, 0, NULL, 1, 0),
('user-3', 130, 70, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL, NULL, 'user3', 'USER3', 'user3@example.com', 'USER3@EXAMPLE.COM', 1, NULL, NULL, NULL, '123123123', 1, 0, NULL, 1, 0),
('user-4', 140, 80, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL, NULL, 'user4', 'USER4', 'user4@example.com', 'USER4@EXAMPLE.COM', 1, NULL, NULL, NULL, '456456456', 1, 0, NULL, 1, 0);

-- Chèn 4 thành viên vào team 1 (có tài khoản)
INSERT INTO Members (FullName, PhoneNumber, Contributed, Email, CurrentTeamId, JoinedTeamAt, OldTeam, Gender, DoB, Address, AccountId, TeamId, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
('Nguyen Van A', '123456789', 10, 'user1@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nam', '1995-01-01', 'Hà Nội', 'user-1', NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Le Thi B', '987654321', 15, 'user2@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nữ', '1996-02-02', 'TPHCM', 'user-2', NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Tran Van C', '123123123', 20, 'user3@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nam', '1997-03-03', 'Đà Nẵng', 'user-3', NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Pham Thi D', '456456456', 25, 'user4@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nữ', '1998-04-04', 'Cần Thơ', 'user-4', NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL);

-- Lấy ID leader cho team 1
DECLARE @Leader1 INT = (SELECT Id FROM Members WHERE Email = 'user1@example.com');

-- Chèn team 1
INSERT INTO Teams (Name, TeamTierId, LeaderId, TeamPoints, RewardPoints, Image, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES ('Team Alpha', NULL, @Leader1, 200, 100, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL);

-- Cập nhật TeamId cho các thành viên team 1
DECLARE @Team1Id INT = (SELECT SCOPE_IDENTITY());
UPDATE Members SET TeamId = @Team1Id WHERE Email IN ('user1@example.com', 'user2@example.com', 'user3@example.com', 'user4@example.com');


-- Chèn tài khoản chỉ cho leader team 2
INSERT INTO AspNetUsers (Id, PersonalPoints, RewardPoints, Avatar, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, DeleteDate, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount)
VALUES 
('leader-2', 200, 100, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL, NULL, 'leader2', 'LEADER2', 'leader2@example.com', 'LEADER2@EXAMPLE.COM', 1, NULL, NULL, NULL, '999888777', 1, 0, NULL, 1, 0);

-- Chèn 4 thành viên vào team 2 (chỉ leader có tài khoản)
INSERT INTO Members (FullName, PhoneNumber, Contributed, Email, CurrentTeamId, JoinedTeamAt, OldTeam, Gender, DoB, Address, AccountId, TeamId, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES
('Nguyen Van X', '999888777', 30, 'leader2@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nam', '1993-05-05', 'Hà Nội', 'leader-2', NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Le Thi Y', '888777666', 35, 'lethiy@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nữ', '1994-06-06', 'TPHCM', NULL, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Tran Van Z', '777666555', 40, 'tranvanz@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nam', '1995-07-07', 'Đà Nẵng', NULL, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL),
('Pham Thi W', '666555444', 45, 'phamthiw@example.com', NULL, SYSDATETIMEOFFSET(), NULL, 'Nữ', '1996-08-08', 'Cần Thơ', NULL, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL);

-- Lấy ID leader cho team 2
DECLARE @Leader2 INT = (SELECT Id FROM Members WHERE Email = 'leader2@example.com');

-- Chèn team 2
INSERT INTO Teams (Name, TeamTierId, LeaderId, TeamPoints, RewardPoints, Image, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
VALUES ('Team Beta', NULL, @Leader2, 300, 150, NULL, SYSDATETIMEOFFSET(), 'system', NULL, NULL);

-- Cập nhật TeamId cho các thành viên team 2
DECLARE @Team2Id INT = (SELECT SCOPE_IDENTITY());
UPDATE Members SET TeamId = @Team2Id WHERE Email IN ('leader2@example.com', 'lethiy@example.com', 'tranvanz@example.com', 'phamthiw@example.com');

-----------------------------------------------------
-- 1. Loại 1: Đặt trong ngày
-----------------------------------------------------
-- Chèn record vào bảng Bookings với Type = 1
INSERT INTO Bookings 
    (MemberId, TeamId, Type, ApprovedAt, Amount, Deposit, Discount, Status, CreatedAt, CreatedBy, PaymentMethod)
VALUES 
    (1, NULL, 1, SYSDATETIMEOFFSET(), 100.0, 50.0, 0.0, 3, SYSDATETIMEOFFSET(), 'system',1);

-- Lấy BookingId vừa chèn
DECLARE @BookingId1 INT = SCOPE_IDENTITY();

-- Chèn chi tiết đặt sân cho ngày cụ thể (ví dụ: 2025-02-20)
INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (
        @BookingId1, 
        1, 
        1, 
        '2025-02-20 05:00:00', 
        '2025-02-20 06:00:00', 
        DATENAME(WEEKDAY, '2025-02-20'), 
        100.0, 
        1, 
        SYSDATETIMEOFFSET(), 
        'system'	
    );

-----------------------------------------------------
-- 2. Loại 2: Đặt cố định có ngày kết thúc
-- Ví dụ: khách chọn đặt cho 3 ngày trong tuần (thứ Hai, thứ Tư, thứ Sáu)
-- trong khoảng thời gian từ 2025-02-20 đến 2025-03-20.
-----------------------------------------------------
INSERT INTO Bookings 
    (MemberId, TeamId, Type, ApprovedAt, Amount, Deposit, Discount, Status, CreatedAt, CreatedBy, PaymentMethod)
VALUES 
    (1, 1, 2, SYSDATETIMEOFFSET(), 600.0, 300.0, 0.0, 3, SYSDATETIMEOFFSET(), 'system',1);

DECLARE @BookingId2 INT = SCOPE_IDENTITY();

-- Chèn 3 dòng cho 3 ngày trong tuần được chọn:
INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId2, 1, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Monday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId2, 1, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Wednesday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId2, 1, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Friday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO Bookings 
    (MemberId, TeamId, Type, ApprovedAt, Amount, Deposit, Discount, Status, CreatedAt, CreatedBy, PaymentMethod)
VALUES 
    (1, 1, 2, SYSDATETIMEOFFSET(), 600.0, 300.0, 0.0, 3, SYSDATETIMEOFFSET(), 'system',1);

DECLARE @BookingId4 INT = SCOPE_IDENTITY();

-- Chèn 3 dòng cho 3 ngày trong tuần được chọn:
INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId4, 2, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Monday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId4, 2, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Wednesday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId4, 2, 1, '2025-02-20 05:00:00', '2025-03-20 06:00:00', 'Friday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

-----------------------------------------------------
-- 3. Loại 3: Đặt cố định không có ngày kết thúc
-- Ví dụ: khách chọn đặt cho 2 ngày trong tuần (thứ Ba và thứ Năm)
-- với lần đặt đầu tiên là 2025-02-25 và không xác định ngày kết thúc.
-----------------------------------------------------
INSERT INTO Bookings 
    (MemberId, TeamId, Type, ApprovedAt, Amount, Deposit, Discount, Status, CreatedAt, CreatedBy, PaymentMethod)
VALUES 
    (5, 1, 3, SYSDATETIMEOFFSET(), 500.0, 250.0, 0.0, 3, SYSDATETIMEOFFSET(), 'system',1);

DECLARE @BookingId3 INT = SCOPE_IDENTITY();

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId3, 1, 1, '2025-02-25 05:00:00', NULL, 'Tuesday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId3, 1, 1, '2025-02-25 05:00:00', NULL, 'Thursday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO Bookings 
    (MemberId, TeamId, Type, ApprovedAt, Amount, Deposit, Discount, Status, CreatedAt, CreatedBy, PaymentMethod)
VALUES 
    (5, 1, 3, SYSDATETIMEOFFSET(), 500.0, 250.0, 0.0, 3, SYSDATETIMEOFFSET(), 'system',2);

DECLARE @BookingId5 INT = SCOPE_IDENTITY();

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId5, 2, 1, '2025-02-25 05:00:00', NULL, 'Tuesday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

INSERT INTO BookingDetails 
    (BookingId, CourtId, TimeSlotId, BeginAt, EndAt, DayOfWeek, Price, Amonut, CreatedAt, CreatedBy)
VALUES 
    (@BookingId5, 2, 1, '2025-02-25 05:00:00', NULL, 'Thursday', 100.0, 1, SYSDATETIMEOFFSET(), 'system');

select * from Bookings
select * from BookingDetails
select * from Members
select * from Teams
select * from AspNetUsers
select * from Courts

-----------------------------------------------------
-- Chèn dữ liệu giữ sân cho Loại 1: Đặt trong ngày
-----------------------------------------------------
INSERT INTO BookingHolds 
    (CourtId, TimeSlotId, HeldBy, HeldAt, ExpiresAt, BookingType, BeginAt, EndAt, DayOfWeek)
VALUES
    (
        3,               -- CourtId (giả sử có sân số 1)
        3,               -- TimeSlotId (giả sử khung giờ số 1)
        'User1',         -- Người giữ lịch
        SYSDATETIMEOFFSET(),  -- Thời điểm giữ lịch
        DATEADD(MINUTE, 5, SYSDATETIMEOFFSET()),  -- Hết hạn sau 5 phút
        1,               -- BookingType = 1 (đặt trong ngày)
        '2025-02-28 05:00:00', -- Thời gian bắt đầu của slot được giữ
        '2025-02-28 06:00:00', -- Thời gian kết thúc của slot được giữ
        DATENAME(WEEKDAY, '2025-02-28') -- Ngày trong tuần (ví dụ: 'Thursday')
    );

INSERT INTO BookingHolds 
    (CourtId, TimeSlotId, HeldBy, HeldAt, ExpiresAt, BookingType, BeginAt, EndAt, DayOfWeek)
VALUES
    (
        1,               -- CourtId (giả sử có sân số 1)
        2,               -- TimeSlotId (giả sử khung giờ số 1)
        'User1',         -- Người giữ lịch
        SYSDATETIMEOFFSET(),  -- Thời điểm giữ lịch
        DATEADD(MINUTE, 5, SYSDATETIMEOFFSET()),  -- Hết hạn sau 5 phút
        1,               -- BookingType = 1 (đặt trong ngày)
        '2025-02-21 06:00:00', -- Thời gian bắt đầu của slot được giữ
        '2025-02-21 07:00:00', -- Thời gian kết thúc của slot được giữ
        DATENAME(WEEKDAY, '2025-02-21') -- Ngày trong tuần (ví dụ: 'Thursday')
    );
-----------------------------------------------------
-- Chèn dữ liệu giữ sân cho Loại 2: Đặt cố định có ngày kết thúc
-----------------------------------------------------
INSERT INTO BookingHolds 
    (CourtId, TimeSlotId, HeldBy, HeldAt, ExpiresAt, BookingType, BeginAt, EndAt, DayOfWeek)
VALUES
    (
        1,               -- CourtId
        3,               -- TimeSlotId
        'User2',         -- Người giữ lịch
        SYSDATETIMEOFFSET(),  -- Thời điểm giữ lịch
        DATEADD(MINUTE, 5, SYSDATETIMEOFFSET()),  -- Hết hạn sau 5 phút
        2,               -- BookingType = 2 (đặt cố định có ngày kết thúc)
        '2025-03-01 07:00:00', -- Ngày bắt đầu của lịch cố định
        '2025-03-31 08:00:00', -- Ngày kết thúc của lịch cố định
        'Monday'         -- Ngày trong tuần được áp dụng (ví dụ: thứ Hai)
    );

-----------------------------------------------------
-- Chèn dữ liệu giữ sân cho Loại 3: Đặt cố định không có ngày kết thúc
-----------------------------------------------------
INSERT INTO BookingHolds 
    (CourtId, TimeSlotId, HeldBy, HeldAt, ExpiresAt, BookingType, BeginAt, EndAt, DayOfWeek)
VALUES
    (
        3,               -- CourtId
        1,               -- TimeSlotId
        'User3',         -- Người giữ lịch
        SYSDATETIMEOFFSET(),  -- Thời điểm giữ lịch
        DATEADD(MINUTE, 5, SYSDATETIMEOFFSET()),  -- Hết hạn sau 5 phút
        3,               -- BookingType = 3 (đặt cố định không có ngày kết thúc)
        '2025-04-01 05:00:00', -- Ngày bắt đầu của lịch cố định (dùng cho hiển thị lần đầu tiên)\n        -- với EndAt = NULL thể hiện không có ngày kết thúc\n",
        NULL,            -- EndAt = NULL cho loại 3
        'Tuesday'        -- Ngày trong tuần áp dụng (ví dụ: thứ Ba)
    );

