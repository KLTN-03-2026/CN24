# Tài liệu: Cách lấy dữ liệu Firebase trong Web Ride Now

## 1. Tổng quan kiến trúc

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  App.jsx    │────▶│ firestoreService │────▶│  Firebase Firestore │
│ (Giao diện) │◀────│     .js          │◀────│  (Cloud Database)   │
└─────────────┘     └──────────────────┘     └─────────────────────┘
                           │
                    ┌──────┴──────┐
                    │ firebase.js │  ← Cấu hình kết nối
                    └─────────────┘
```

- **firebase.js** — Khởi tạo kết nối Firebase, export `db` (Firestore) và `auth` (Authentication)
- **firestoreService.js** — Tầng service chứa tất cả hàm truy vấn Firestore
- **App.jsx** — Giao diện React, gọi các hàm service để lấy/hiển thị dữ liệu

---

## 2. Cấu hình Firebase (`firebase.js`)

```javascript
import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "...",
  authDomain: "ridenow-app-3aa76.firebaseapp.com",
  projectId: "ridenow-app-3aa76",
  storageBucket: "ridenow-app-3aa76.firebasestorage.app",
  messagingSenderId: "...",
  appId: "...",
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);   // Firestore database
export const auth = getAuth(app);       // Authentication
```

**Giải thích:** File này chỉ chạy 1 lần khi app khởi động. Nó tạo kết nối tới Firebase project `ridenow-app-3aa76` và export 2 instance: `db` để đọc/ghi Firestore, `auth` để xác thực.

---

## 3. Cấu trúc Firestore Collections

Firebase Firestore lưu dữ liệu theo dạng **Collection → Document → Fields**. Dự án Ride Now có 3 collections chính:

### 3.1. Collection: `users`

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | UID từ Firebase Auth |
| `name` | string | Họ tên đầy đủ |
| `email` | string | Email đăng nhập |
| `phone` | string? | Số điện thoại (có thể null) |
| `role` | string | `"customer"` hoặc `"driver"` |
| `avatar` | string? | URL ảnh đại diện |
| `vehicleType` | string? | Loại xe (chỉ driver) |
| `vehiclePlate` | string? | Biển số xe (chỉ driver) |
| `isOnline` | boolean? | Trạng thái online (chỉ driver) |
| `isAvailable` | boolean? | Sẵn sàng nhận khách (chỉ driver) |
| `latitude` | number? | Vĩ độ hiện tại |
| `longitude` | number? | Kinh độ hiện tại |
| `rating` | number | Đánh giá trung bình (0-5) |
| `totalTrips` | number | Tổng số chuyến đã đi |
| `earnings` | number | Tổng thu nhập (VNĐ) |
| `createdAt` | Timestamp | Ngày tạo tài khoản |

### 3.2. Collection: `trips`

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | Mã chuyến đi |
| `customerId` | string | UID khách hàng |
| `customerName` | string | Tên khách hàng |
| `driverId` | string | UID tài xế |
| `driverName` | string | Tên tài xế |
| `pickupAddress` | string | Địa chỉ đón khách |
| `pickupLatitude` | number | Vĩ độ điểm đón |
| `pickupLongitude` | number | Kinh độ điểm đón |
| `destinationAddress` | string | Địa chỉ điểm đến |
| `destinationLatitude` | number | Vĩ độ điểm đến |
| `destinationLongitude` | number | Kinh độ điểm đến |
| `fare` | number | Giá tiền (VNĐ) |
| `distance` | number | Khoảng cách (km) |
| `status` | string | `"ongoing"`, `"completed"`, `"cancelled"` |
| `paymentMethod` | string | `"Tiền mặt"` hoặc phương thức khác |
| `createdAt` | Timestamp | Thời điểm tạo chuyến |
| `completedAt` | Timestamp? | Thời điểm hoàn thành (null nếu chưa) |

### 3.3. Collection: `ride_requests`

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | Mã yêu cầu |
| `customerId` | string | UID khách hàng |
| `customerName` | string | Tên khách hàng |
| `pickupAddress` | string | Địa chỉ đón |
| `pickupLatitude` | number | Vĩ độ đón |
| `pickupLongitude` | number | Kinh độ đón |
| `destinationAddress` | string | Địa chỉ đến |
| `destinationLatitude` | number | Vĩ độ đến |
| `destinationLongitude` | number | Kinh độ đến |
| `driverId` | string? | UID tài xế được gán |
| `driverName` | string? | Tên tài xế |
| `driverPhone` | string? | SĐT tài xế |
| `customerPhone` | string? | SĐT khách |
| `distanceInKm` | number? | Khoảng cách (km) |
| `fare` | number? | Giá tiền |
| `status` | string | Trạng thái (xem bảng bên dưới) |
| `paymentMethod` | string | Phương thức thanh toán |
| `createdAt` | Timestamp | Thời điểm tạo yêu cầu |

**Các trạng thái `status` của ride_requests:**

| Status | Ý nghĩa |
|--------|---------|
| `pending` | Chờ xử lý |
| `searching_driver` | Đang tìm tài xế |
| `driver_assigned` | Đã gán tài xế |
| `accepted` | Tài xế đã nhận |
| `on_the_way` | Đang trên đường |
| `completed` | Hoàn thành |
| `cancelled` | Đã hủy |
| `rejected` | Tài xế từ chối |
| `timeout` | Hết thời gian chờ |

---

## 4. Các hàm lấy dữ liệu (`firestoreService.js`)

### 4.1. Lấy dữ liệu 1 lần (One-time fetch)

Sử dụng `getDocs()` — gọi 1 lần, trả về kết quả rồi ngắt kết nối.

#### `getUsers(role, maxResults)`
```javascript
// Lấy danh sách users, có thể lọc theo role
const allUsers = await getUsers();              // Tất cả users
const drivers = await getUsers('driver', 50);   // Chỉ tài xế, tối đa 50
const customers = await getUsers('customer');    // Chỉ khách hàng
```
**Firestore query:**
```
collection('users') → where('role', '==', role) → limit(maxResults)
```

#### `countUsers(role)`
```javascript
// Đếm số lượng users (không tải toàn bộ document)
const totalUsers = await countUsers();          // Tổng tất cả
const totalDrivers = await countUsers('driver'); // Tổng tài xế
```
**Firestore query:** Dùng `getCountFromServer()` — chỉ trả về số đếm, không tải dữ liệu → tiết kiệm bandwidth.

#### `countOnlineDrivers()`
```javascript
// Đếm tài xế đang online
const online = await countOnlineDrivers();
```
**Firestore query:**
```
collection('users') → where('role', '==', 'driver') AND where('isOnline', '==', true)
```

#### `getRecentTrips(maxResults)`
```javascript
// Lấy chuyến đi gần đây nhất, sắp xếp theo thời gian mới nhất
const trips = await getRecentTrips(10);
```
**Firestore query:**
```
collection('trips') → orderBy('createdAt', 'desc') → limit(10)
```

#### `countTrips(status)`
```javascript
const total = await countTrips();              // Tổng chuyến đi
const completed = await countTrips('completed'); // Chuyến hoàn thành
```

#### `getRecentRideRequests(maxResults)`
```javascript
// Lấy yêu cầu đặt xe gần đây
const requests = await getRecentRideRequests(10);
```
**Firestore query:**
```
collection('ride_requests') → orderBy('createdAt', 'desc') → limit(10)
```

#### `getTotalRevenue()`
```javascript
// Tính tổng doanh thu từ các chuyến hoàn thành
const revenue = await getTotalRevenue();
```
**Firestore query:**
```
collection('trips') → where('status', '==', 'completed') → tải tất cả → cộng field 'fare'
```
> ⚠️ Hàm này tải tất cả trips completed rồi cộng fare ở client. Với dữ liệu lớn nên dùng Cloud Functions.

---

### 4.2. Lắng nghe Realtime (Realtime listeners)

Sử dụng `onSnapshot()` — lắng nghe thay đổi liên tục, tự động cập nhật khi có dữ liệu mới.

#### `onRecentTrips(callback, maxResults)`
```javascript
// Tự động cập nhật khi có chuyến đi mới
const unsubscribe = onRecentTrips((trips) => {
  console.log('Trips đã cập nhật:', trips);
  setTrips(trips); // cập nhật state React
}, 20);

// Khi component unmount → ngắt lắng nghe
unsubscribe();
```

#### `onRecentRideRequests(callback, maxResults)`
```javascript
// Tự động cập nhật khi có yêu cầu đặt xe mới
const unsubscribe = onRecentRideRequests((requests) => {
  setRideRequests(requests);
}, 20);
```

#### `onOnlineDrivers(callback)`
```javascript
// Tự động cập nhật danh sách tài xế online
const unsubscribe = onOnlineDrivers((drivers) => {
  setOnlineDriverCount(drivers.length);
}, 20);
```

**Firestore query cho realtime:**
```
collection('users') → where('role', '==', 'driver') AND where('isOnline', '==', true)
→ onSnapshot() lắng nghe liên tục
```

---

## 5. Luồng dữ liệu trong App.jsx

### 5.1. Khi App khởi động

```
App mount
  ├── loadStats()           → Gọi 6 hàm đếm song song (Promise.all)
  │     ├── countTrips()
  │     ├── countOnlineDrivers()
  │     ├── getTotalRevenue()
  │     ├── countUsers()
  │     ├── countUsers('driver')
  │     └── countUsers('customer')
  │
  ├── loadTrips()           → getRecentTrips(20)
  ├── loadRideRequests()    → getRecentRideRequests(20)
  │
  └── Khởi tạo 3 Realtime Listeners:
        ├── onRecentTrips()         → cập nhật bảng "Chuyến đi gần đây"
        ├── onRecentRideRequests()  → cập nhật "Hoạt động gần đây"  
        └── onOnlineDrivers()       → cập nhật số tài xế online
```

### 5.2. Khi bấm nút Refresh

```
handleRefresh()
  └── Promise.all([loadStats(), loadTrips(), loadRideRequests()])
      → Tải lại tất cả dữ liệu 1 lần
```

### 5.3. Khi bấm card "Tài xế online"

```
handleOpenDrivers()
  ├── setShowDriverModal(true)     → Mở modal
  └── getUsers('driver', 100)      → Tải danh sách tài xế
      └── setAllDrivers(drivers)   → Hiển thị trong modal
```

### 5.4. Khi có dữ liệu mới trên Firestore (Realtime)

```
Firestore thay đổi (ai đó đặt xe, tài xế online, ...)
  └── onSnapshot() tự động fire callback
      └── setState() → React tự render lại giao diện
```

---

## 6. Mapping dữ liệu → Giao diện

| Dữ liệu | Component hiển thị | Cách lấy |
|----------|-------------------|----------|
| Tổng chuyến đi | Stat Card #1 | `countTrips()` |
| Tài xế online | Stat Card #2 | `countOnlineDrivers()` |
| Tổng doanh thu | Stat Card #3 | `getTotalRevenue()` |
| Tổng người dùng | Stat Card #4 | `countUsers()` |
| Biểu đồ chuyến đi | ChartSection | `trips` state (từ realtime) |
| Hoạt động gần đây | ActivityFeed | `rideRequests` state (từ realtime) |
| Bảng chuyến đi | RecentTrips | `trips` state (từ realtime) |
| Modal tài xế | DriverModal | `getUsers('driver')` (on-click) |
| Badge tài xế (sidebar) | Sidebar | `onOnlineDrivers()` realtime |

---

## 7. Sơ đồ quan hệ giữa Collections

```
┌─────────────────────────────────────────────┐
│                  users                       │
│  (role: 'customer' | 'driver')              │
│                                              │
│  Customer: id, name, email, phone, rating    │
│  Driver:   + vehicleType, vehiclePlate,      │
│              isOnline, isAvailable,           │
│              latitude, longitude, earnings   │
└──────┬────────────────────────┬──────────────┘
       │ customerId              │ driverId
       ▼                         ▼
┌──────────────────┐   ┌────────────────────┐
│  ride_requests   │──▶│      trips         │
│                  │   │                    │
│  Yêu cầu đặt xe │   │  Chuyến đi đã     │
│  (trạng thái     │   │  được xác nhận    │
│   thay đổi liên  │   │                    │
│   tục)           │   │  Lưu khi tài xế   │
│                  │   │  nhận chuyến       │
└──────────────────┘   └────────────────────┘

  Luồng: Customer đặt xe → ride_requests (pending)
         → Tìm driver → ride_requests (driver_assigned)
         → Driver nhận → trips (ongoing) + ride_requests (accepted)
         → Hoàn thành → trips (completed) + ride_requests (completed)
```

---

## 8. Lưu ý quan trọng

1. **Timestamp:** Firestore lưu thời gian dạng `Timestamp` object (có `.seconds` và `.nanoseconds`), không phải `Date`. Khi dùng ở JS cần convert: `new Date(timestamp.seconds * 1000)`.

2. **Realtime vs One-time:** 
   - Dùng `getDocs()` cho dữ liệu tĩnh (thống kê, danh sách)
   - Dùng `onSnapshot()` cho dữ liệu cần cập nhật liên tục (hoạt động, chuyến đi)

3. **Cleanup:** Luôn gọi `unsubscribe()` khi component unmount để tránh memory leak.

4. **Index:** Các query phức tạp (nhiều `where` + `orderBy`) có thể cần tạo composite index trên Firebase Console.

5. **Security Rules:** Firestore Rules cần cho phép đọc các collections này. Kiểm tra tại Firebase Console → Firestore → Rules.
