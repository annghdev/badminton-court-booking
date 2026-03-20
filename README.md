<div align="center">

# 🏸 FocusBadminton - Hệ thống Đặt sân Cầu lông

**Ứng dụng đặt sân cầu lông real-time với SignalR, xây dựng trên ASP.NET Core & Blazor WebAssembly**

[![.NET](https://img.shields.io/badge/.NET-9.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Blazor](https://img.shields.io/badge/Blazor-WebAssembly-512BD4?logo=blazor)](https://dotnet.microsoft.com/apps/aspnet/web-apps/blazor)
[![SignalR](https://img.shields.io/badge/SignalR-Real--time-blue?logo=dotnet)](https://dotnet.microsoft.com/apps/aspnet/signalr)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-Database-CC2927?logo=microsoftsqlserver)](https://www.microsoft.com/sql-server)
[![EF Core](https://img.shields.io/badge/EF%20Core-8.0-purple)](https://learn.microsoft.com/ef/core/)
[![AntDesign](https://img.shields.io/badge/Ant%20Design-Blazor-1890ff?logo=antdesign)](https://antblazor.com/)

</div>

---

## 📋 Mục đích dự án

Hệ thống quản lý và đặt sân cầu lông trực tuyến, cho phép người dùng:

- **Xem lịch sân real-time** — trạng thái slot được cập nhật tức thì qua SignalR
- **Giữ slot & đặt sân** — quy trình giữ chỗ → đặt sân → thanh toán → duyệt
- **Thanh toán online** — tích hợp VnPay và MoMo
- **Dashboard thống kê** — biểu đồ doanh thu

Dự án áp dụng **Clean Architecture**, **CQRS pattern** (MediatR), và một số mẫu thiết kế cho môn học **Design Patterns**.

---

## 🛠️ Công nghệ sử dụng

### Backend

| Công nghệ | Version | Mục đích |
|:--|:--|:--|
| **ASP.NET Core** | 9.0 | Web framework chính |
| **Entity Framework Core** | 8.0.13 | ORM, Code-First Migrations |
| **SQL Server** | — | Cơ sở dữ liệu quan hệ |
| **Stored Procedures** | 9 versions | Logic lịch sân phức tạp |
| **Dapper** | 2.1.66 | Raw SQL queries hiệu năng cao |
| **MediatR** | 12.4.1 | CQRS — tách biệt Command/Query |
| **AutoMapper** | 13.0.1 | Object-to-object mapping |
| **FluentValidation** | 11.11.0 | Request validation + MediatR Pipeline |
| **SignalR** | 9.0.2 | Real-time communication (MessagePack) |
| **ASP.NET Identity** | 8.0.13 | Quản lý tài khoản, role-based access |
| **JWT Bearer** | 8.0.13 | Token-based authentication |
| **Google.Apis.Auth** | 1.69.0 | Google OAuth2 login |
| **RestSharp** | 112.1.0 | HTTP client cho MoMo / Facebook API |
| **Swashbuckle** | 7.2.0 | Swagger / OpenAPI documentation |
| **Rate Limiting** | Built-in | Giới hạn request bảo vệ API |

### Frontend

| Công nghệ | Version | Mục đích |
|:--|:--|:--|
| **Blazor WebAssembly** | 9.0.2 | SPA chạy trên trình duyệt |
| **Ant Design Blazor** | 1.3.1 | UI component library |
| **AntDesign.Charts** | 0.6.0 | Biểu đồ thống kê |
| **Blazored.LocalStorage** | 4.5.0 | Lưu trữ phía client (token, etc.) |
| **SignalR Client** | 9.0.2 | Kết nối real-time từ Blazor |

### Payment Gateways

| Cổng thanh toán | Trạng thái | Chi tiết |
|:--|:--|:--|
| **VnPay** | ✅ Đã tích hợp | `VnPayService`, `VnPayLibrary`, HMAC-SHA verification |
| **MoMo** | ✅ Đã tích hợp | `MomoService`, signature verification |

---

## 🎨 Design Patterns

| Pattern | Áp dụng | Files chính |
|:--|:--|:--|
| **Clean Architecture** | Tách biệt Domain → Application → Infrastructure → Web | Solution structure |
| **CQRS** | Command/Query riêng biệt qua MediatR | `Features/*/Commands/`, `Features/*/Queries/` |
| **Repository + Unit of Work** | Generic `IRepository<T>` + `UnitOfWork` | `Data/Repositories/` |
| **Strategy Pattern** | Đăng nhập đa nền tảng | `GoogleLoginStrategy`, `FacebookLoginStrategy`, `PasswordLoginStrategy` |
| **Factory Pattern** | Tạo instances linh hoạt | `LoginStrategyFactory`, `CostCalculatorFactory`, `PaymentAdapterFactory` |
| **Decorator Pattern** | Tính tiền nhiều tầng | `MemberLevelCostDecorator`, `PromotionCostDecorator`, `WeekendCostDecorator` |
| **State Pattern** | Máy trạng thái slot | 11 states: Available, Booked, Held, Paused, Pending... |
| **Mediator Pattern** | Xử lý sự kiện slot phía client | `IScheduleMediator`, `SlotEventHandler` |
| **Pipeline Behavior** | Validation tự động | `ValidationBehavior<TRequest, TResponse>` |

---

## ⚡ Chức năng chính

### 🏟️ Đặt sân & Quản lý Slot

| Chức năng | Mô tả |
|:--|:--|
| Xem lịch sân real-time | Trạng thái slot cập nhật tức thì qua SignalR |
| Giữ slot (Hold) | Giữ chỗ tạm thời trước khi đặt, tự động release khi hết thời gian |
| Đặt sân (Booking) | Tạo → Chờ duyệt → Duyệt/Từ chối → Hoàn thành |
| Tạm dừng / Tiếp tục booking | Pause/Resume booking đã duyệt |
| Tự động hủy booking hết hạn | Background service `AutoCancelExpiredBooking` |
| Tự động release slot | Background service `AutoReleaseSlot` |

### 🔐 Xác thực & Phân quyền

| Chức năng | Mô tả |
|:--|:--|
| Đăng ký tài khoản | Email + Password qua ASP.NET Identity |
| Đăng nhập Password | JWT Bearer token |
| Đăng nhập Google OAuth2 | Web + Mobile strategies |
| Đăng nhập Facebook | Strategy implemented |
| Phân quyền | Role-based + Custom policy (`HasBookingPermission`) |

### 💳 Thanh toán

| Chức năng | Mô tả |
|:--|:--|
| VnPay | Redirect payment, HMAC-SHA verification |
| MoMo | QR payment, signature verification |
| Tính tiền tự động | Factory + Decorator: khung giờ, level thành viên, promotion, cuối tuần |

### 🎫 Voucher & Khuyến mãi

| Chức năng | Mô tả |
|:--|:--|
| Tạo voucher template | CRUD templates |
| Phát hành voucher | Bulk create từ template |
| Áp dụng voucher | `VoucherCostDecorator` tính tiền tự động |


### 📊 Quản trị & Thống kê

| Chức năng | Mô tả |
|:--|:--|
| Quản lý sân (Court) | Tạo, cập nhật thông tin sân |
| Quản lý khung giờ (TimeSlot) | Enable/Disable, đặt giá theo khung |
| Thống kê doanh thu | Biểu đồ `AntDesign.Charts` |

---

## 📁 Cấu trúc thư mục

```
FocusBadminton.Booking/
├── FocusBadminton.Booking.sln
├── README.md
├── assets/                          # Hình ảnh demo
├── store-procedures/                # SQL Stored Procedures
│   ├── proc_ver9.sql                # Version mới nhất
│   ├── proc_v8.sql
│   ├── proc_check_available_fix.sql
│   └── seeddata.sql                 # Dữ liệu mẫu
│
└── src/
    ├── Common (Shared)/             # DTOs & Enums chia sẻ
    │
    ├── Domain/                      # Entities & Contracts
    │   ├── Entities/
    │   ├── Repositories/            # IRepository<T>
    │   └── Constants/
    │
    ├── Application/                 # Business Logic (CQRS)
    │   ├── DependencyInjection.cs   # MediatR + AutoMapper + Validation DI
    │   ├── Common/
    │   │   ├── Behaviours/          # ValidationBehavior (Pipeline)
    │   │   └── Mappings/            # AutoMapper profiles
    │   ├── Interfaces/
    │   │   ├── IAuthService.cs
    │   │   ├── IPaymentAdapter.cs
    │   │   ├── ICostCalculator.cs
    │   │   ├── ISlotNotification.cs
    │   │   ├── IMailService.cs
    │   │   └── DapperQueries/       # Dapper query interfaces
    │   ├── Features/
    │   │   ├── Auth/Commands/
    │   │   ├── Bookings/
    │   │   │   ├── Commands/        # Create, Approve, Cancel, Pause, Reject, Resume
    │   │   │   ├── Queries/         # GetBooking, GetBookings, GetBookingHistory
    │   │   │   ├── Calculators/     # BookingCostProcessor, Decorators
    │   │   │   └── Validators/      # CreateBookingCommandValidator
    │   │   ├── Courts/Commands & Queries/
    │   │   ├── Facilities/Queries/
    │   │   ├── Members/Queries/
    │   │   ├── Schedules/           # GetCourtSchedule queries
    │   │   ├── Slots/               # Hold, Release, CheckAvailability
    │   │   ├── Statictis/Queries/
    │   │   ├── Teams/Commands & Queries/
    │   │   ├── TimeSlots/Commands & Queries/
    │   │   └── Vouchers/Commands & Queries/
    │   └── Models/
    │       └── PaymentModels/
    │
    ├── Infrastructure/              # Data Access & External Services
    │   ├── DependencyInjection.cs   # EF Core + Identity + JWT + Payment DI
    │   ├── Data/
    │   │   ├── AppDbContext.cs       # EF Core DbContext
    │   │   ├── UnitOfWork.cs
    │   │   ├── Repositories/        # Generic + Specialized repos
    │   │   ├── DapperQueries/       # Dapper SQL connections & queries
    │   │   └── Queries/
    │   ├── Identity/
    │   │   ├── AuthService.cs       # JWT token generation
    │   │   ├── LoginStrategies/     # Google, Facebook, Password, MobileGoogle
    │   │   └── LoginFactories/      # LoginStrategyFactory
    │   ├── Implements/
    │   │   ├── CostCalculators/     # Factory + Decorators (7 files)
    │   │   ├── Payments/            # VnPay & MoMo adapters + Factory
    │   │   └── Handlers/            # Dapper statistic queries
    │   ├── Services/
    │   │   ├── VnPay/               # 8 files: Service, Library, Models
    │   │   └── Momo/                # 6 files: Service, Models
    │   ├── Migrations/              # EF Core migrations
    │   └── Helper/                  # HmacSHA, IpHelper
    │
    └── Web/
        ├── Web (Server)/            # ASP.NET Core Host
        │   ├── Program.cs           # DI, Middleware, SignalR mapping
        │   ├── Controllers/           # API Controllers
        │   ├── Hubs/                # SignalR hub cho slot real-time
        │   ├── CronJobs/            # Công việc chạy nền
        │   ├── NotificationServices/
        │   ├── Middlewares/         # ValidationExceptionMiddleware
        │   └── Policies/            # Custom check permission
        │
        └── Web.Client/              # Blazor WebAssembly
            ├── Program.cs
            ├── Pages/
            ├── ApiServices/         # HTTP client services
            ├── SlotStates/          # State Pattern
            ├── Mediators/           # Client-side event handling
            ├── Layout/              # MainLayout.razor
            └── wwwroot/             # Static assets, CSS
```

---

## 📊 Trạng thái dự án

### ✅ Đã thực hiện

| # | Module | Chi tiết |
|:-:|:--|:--|
| 1 | **Đặt sân (Booking)** | Workflow đầy đủ: Create → Approve/Reject → Pause/Resume → Cancel |
| 2 | **Giữ slot real-time** | Hold/Release qua SignalR, Slot State Machine (11 states) |
| 3 | **Đăng ký / Đăng nhập** | Password + JWT, ASP.NET Identity |
| 4 | **Google OAuth2** | Web (`GoogleLoginStrategy`) + Mobile (`MobileGoogleLoginStrategy`) |
| 5 | **Facebook Login** | `FacebookLoginStrategy` implemented |
| 6 | **Thanh toán VnPay** | Full integration + HMAC verification |
| 7 | **Thanh toán MoMo** | Full integration + signature verification |
| 8 | **Quản lý Voucher** | Template CRUD + Bulk create + áp dụng khi tính tiền |
| 9 | **Quản lý Sân** | CRUD Courts + UI Blazor |
| 10 | **Lịch sân** | Dapper queries + SignalR real-time + Schedule pages |
| 11 | **Quản lý Khung giờ** | Enable/Disable + Set giá |
| 12 | **Quản lý Đội nhóm** | Create/Join/Leave/Switch/Kick + đóng góp tài chính |
| 13 | **Tính tiền tự động** | Factory + Decorator pattern (khung giờ, level, promotion, weekend) |
| 14 | **Background Services** | Auto release slot + Auto cancel expired booking |
| 15 | **Rate Limiting** | Fixed Window policy cho API |
| 16 | **Swagger API Docs** | Conditional enable (`OpenApi=1`) |
| 17 | **Validation Pipeline** | FluentValidation + MediatR Pipeline Behavior |
| 18 | **Stored Procedures** | 9 versions SQL cho logic scheduling phức tạp |

### ⚠️ Chưa hoàn thiện

| # | Module | Trạng thái | Ghi chú |
|:-:|:--|:--|:--|
| 1 | **Notification Hub** | ⚠️ Stub | chưa triển khai thông báo real-time |
| 2 | **Email Service** | ⚠️ Interface only | `IMailService` chưa có implementation |
| 3 | **Push Notification** | ⚠️ Interface only | `INotificationService` chưa implement đầy đủ |
| 4 | **Quản lý Cơ sở/sân** | ⚠️ Read-only | Chỉ có Query, chưa có Command tạo/sửa/xóa |

---

## 🖼️ Hình ảnh Demo

> 📌 **Cập nhật hình ảnh**: Thêm ảnh chụp màn hình vào folder `assets/` và cập nhật links dưới đây.

<!-- 
### Trang đăng nhập
![Login Page](assets/login.png)

### Lịch đặt sân
![Court Schedule](assets/schedule.png)

### Đặt sân real-time
![Booking](assets/booking.png)

### Thanh toán
![Payment](assets/payment.png)

### Quản lý voucher
![Vouchers](assets/vouchers.png)

### Thống kê
![Statistics](assets/statistics.png)
-->

---

## 🔗 Link Demo

- Video: https://youtu.be/-GW51V19bgk?si=mDFbyydS9-xyjtpi

<!--
- **Live Demo**: [https://focusbadminton.example.com](https://focusbadminton.example.com)
- **Swagger API**: [https://focusbadminton.example.com/swagger](https://focusbadminton.example.com/swagger)
-->

---

## 🚀 Hướng dẫn Cài đặt

### Yêu cầu

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [SQL Server](https://www.microsoft.com/sql-server) (LocalDB hoặc Express)

### Cài đặt

```bash
# 1. Clone repository
git clone https://github.com/<username>/FocusBadminton.Booking.git
cd FocusBadminton.Booking

# 2. Cấu hình database
# Cập nhật connection string trong appsettings.Development.json
# src/Web/Web/appsettings.Development.json

# 3. Áp dụng migrations
dotnet ef database update --project src/Infrastructure --startup-project src/Web/Web

# 4. Áp dụng Index, store procedure và chạy seed data
# Thực thi các file trong `store-procedures`: sql_index.sql, proc_v9.sql và seeddata.sql trên SQL Server

# 5. Chạy ứng dụng
dotnet run --project src/Web/Web
```

### Cấu hình

Tạo `appsettings.Development.json` và copy từ `appsettings.json` với các thông tin sau:

```json
{
  "ConnectionStrings": {
    "SqlServer": "<your-connection-string>"
  },
  "JWT": {
    "Key": "<your-jwt-secret-key>",
    "Issuer": "<issuer>",
    "Audience": "<audience>"
  },
  "Google": {
    "ClientId": "<google-client-id>",
    "ClientSecret": "<google-client-secret>"
  },
  "VnPay": {
    "TmnCode": "<vnpay-tmn-code>",
    "HashSecret": "<vnpay-hash-secret>",
    "PaymentUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"
  },
  "MomoAPI": {
    "PartnerCode": "<momo-partner-code>",
    "AccessKey": "<momo-access-key>",
    "SecretKey": "<momo-secret-key>"
  }
}
```

### Truy cập

| URL | Mô tả |
|:--|:--|
| `https://localhost:7000` | Ứng dụng Blazor |
| `https://localhost:7000/swagger` | Swagger UI |

---

## 📄 License

Dự án phục vụ mục đích học tập và portfolio cá nhân.

---
