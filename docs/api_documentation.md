# Tổng hợp các REST API trong dự án Ride Now

Dưới đây là danh sách các REST API và dịch vụ backend được sử dụng trong ứng dụng Ride Now.

---

## 1. TrackAsia API (Dịch vụ Bản đồ & Địa chỉ)

Đây là dịch vụ chính được sử dụng để tìm kiếm địa chỉ, gợi ý địa điểm (autocomplete) và chuyển đổi tọa độ.

*   **Base URL:** `https://maps.track-asia.com/api/v1`
*   **Dịch vụ sử dụng:** `lib/services/trackasia_service.dart`

### Các Endpoint:

#### **A. Autocomplete (Gợi ý địa chỉ)**
*   **Endpoint:** `/autocomplete`
*   **Method:** `GET`
*   **Tham số chính:**
    *   `text`: Nội dung người dùng nhập.
    *   `key`: API Key (TrackAsia).
    *   `countrycodes=vn`: Giới hạn kết quả tại Việt Nam.
    *   `focus.point.lat/lon`: Ưu tiên các địa điểm gần vị trí người dùng.
*   **Mục đích:** Hiển thị danh sách gợi ý khi người dùng nhập điểm đến.

#### **B. Search (Tìm kiếm địa chỉ cụ thể)**
*   **Endpoint:** `/search`
*   **Method:** `GET`
*   **Mục đích:** Tìm kiếm chính xác tọa độ của một địa chỉ cụ thể (thường dùng khi người dùng nhấn Enter hoặc chọn từ danh sách).

#### **C. Reverse Geocoding (Chuyển tọa độ thành địa chỉ)**
*   **Endpoint:** `/reverse`
*   **Method:** `GET`
*   **Tham số chính:**
    *   `point.lat` & `point.lon`: Tọa độ cần chuyển đổi.
*   **Mục đích:** Lấy tên địa chỉ từ vị trí GPS hiện tại của người dùng.

---

## 2. OSRM API (Dịch vụ Lộ trình - Routing)

Ứng dụng sử dụng Project OSRM để tính toán đường đi giữa hai điểm.

*   **Base URL:** `http://router.project-osrm.org/route/v1/driving`
*   **Sử dụng tại:** `CustomerHomeView` và `DriverNavigationScreen`

### Endpoint:
*   **Định dạng:** `/{longitude1},{latitude1};{longitude2},{latitude2}?overview=full&geometries=geojson`
*   **Method:** `GET`
*   **Mục đích:** 
    *   Vẽ đường đi (Polyline) trên bản đồ.
    *   Tính toán khoảng cách (km) và thời gian di chuyển dự kiến (phút).

---

## 3. OpenStreetMap Tile API (Dịch vụ Lớp Bản đồ)

Dùng để tải các mảnh bản đồ (tiles) hiển thị giao diện bản đồ.

*   **URL Template:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
*   **Mục đích:** Cung cấp lớp nền bản đồ cho plugin `flutter_map`.

---

## 4. Firebase Services (Hệ thống Backend chính)

Mặc dù sử dụng Firebase SDK (không gọi REST trực tiếp bằng code thủ công), nhưng đây là nơi lưu trữ và xử lý dữ liệu chính.

### **A. Firebase Authentication**
*   **Mục đích:** Quản lý đăng ký, đăng nhập người dùng (Email/Password).

### **B. Cloud Firestore (Cơ sở dữ liệu NoSQL)**
Dữ liệu được tổ chức qua các Collection chính:
*   `users`: Lưu thông tin cá nhân, vai trò (Customer/Driver).
*   `ride_requests`: Lưu thông tin các chuyến xe (điểm đón, điểm đến, giá tiền, trạng thái).
*   `driver_locations`: Lưu vị trí realtime của tài xế để khách hàng theo dõi.
*   `trips`: Lưu lịch sử các chuyến đi đã hoàn thành và đang diễn ra.

---

## 5. Các thông số API Key
*   **TrackAsia Key:** Được truyền qua `--dart-define=TRACKASIA_KEY=...` hoặc sử dụng fallback key trong code.
*   **Firebase Config:** Cấu hình trong `ios/Runner/GoogleService-Info.plist` và `android/app/google-services.json`.
