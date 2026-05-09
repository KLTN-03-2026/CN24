/* ===== Format helpers ===== */
export function formatCurrency(amount) {
  if (amount >= 1000000000) return `${(amount / 1000000000).toFixed(1)} tỷ`
  if (amount >= 1000000) return `${(amount / 1000000).toFixed(1)} tr`
  if (amount >= 1000) return `${(amount / 1000).toFixed(0)}K`
  return amount.toLocaleString('vi-VN')
}

export function formatNumber(num) {
  return num.toLocaleString('vi-VN')
}

export function formatFare(fare) {
  return `${Math.round(fare).toLocaleString('vi-VN')}₫`
}

export function getInitials(name) {
  if (!name) return '??'
  const parts = name.trim().split(' ')
  if (parts.length === 1) return parts[0][0]?.toUpperCase() || '?'
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
}

export function timeAgo(timestamp) {
  if (!timestamp) return ''
  let date
  if (timestamp.seconds) {
    date = new Date(timestamp.seconds * 1000)
  } else if (timestamp instanceof Date) {
    date = timestamp
  } else {
    date = new Date(timestamp)
  }
  const now = new Date()
  const diff = Math.floor((now - date) / 1000)
  if (diff < 60) return `${diff} giây trước`
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`
  return `${Math.floor(diff / 86400)} ngày trước`
}

export function getVietnameseDate() {
  const days = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy']
  const now = new Date()
  return `${days[now.getDay()]}, ${now.getDate()} tháng ${String(now.getMonth() + 1).padStart(2, '0')} năm ${now.getFullYear()}`
}

export function formatDate(timestamp) {
  if (!timestamp) return '—'
  let date
  if (timestamp.seconds) {
    date = new Date(timestamp.seconds * 1000)
  } else if (timestamp instanceof Date) {
    date = timestamp
  } else {
    date = new Date(timestamp)
  }
  return date.toLocaleString('vi-VN', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit', second: '2-digit'
  })
}

export function formatDateShort(timestamp) {
  if (!timestamp) return '—'
  let date
  if (timestamp.seconds) {
    date = new Date(timestamp.seconds * 1000)
  } else if (timestamp instanceof Date) {
    date = timestamp
  } else {
    date = new Date(timestamp)
  }
  return date.toLocaleString('vi-VN', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  })
}

/* ===== Status mapping ===== */
export const statusMap = {
  completed: { label: 'Hoàn thành', css: 'completed' },
  ongoing: { label: 'Đang đi', css: 'active' },
  on_the_way: { label: 'Đang đi', css: 'active' },
  accepted: { label: 'Đã nhận', css: 'active' },
  driver_assigned: { label: 'Đã gán TX', css: 'active' },
  searching_driver: { label: 'Đang tìm', css: 'active' },
  pending: { label: 'Chờ xử lý', css: 'active' },
  cancelled: { label: 'Đã hủy', css: 'cancelled' },
  rejected: { label: 'Từ chối', css: 'cancelled' },
  timeout: { label: 'Hết hạn', css: 'cancelled' },
}

/* ===== Sidebar Links ===== */
export const sidebarLinks = [
  { section: 'Tổng quan' },
  { id: 'nav-dashboard', icon: 'dashboard', label: 'Dashboard', active: true },
  { id: 'nav-analytics', icon: 'chart', label: 'Phân tích' },
  { section: 'Quản lý' },
  { id: 'nav-rides', icon: 'car', label: 'Chuyến đi' },
  { id: 'nav-drivers', icon: 'driver', label: 'Tài xế' },
  { id: 'nav-customers', icon: 'users', label: 'Khách hàng' },
  { id: 'nav-accounts', icon: 'account', label: 'Tài khoản' },
  { id: 'nav-map', icon: 'map', label: 'Bản đồ' },
  { section: 'Tài chính' },
  { id: 'nav-payments', icon: 'wallet', label: 'Thanh toán' },
  { section: 'Hệ thống' },
  { id: 'nav-complaints', icon: 'help', label: 'Khiếu nại' },
  { id: 'nav-reviews', icon: 'star', label: 'Đánh giá' },
  { id: 'nav-settings', icon: 'settings', label: 'Cài đặt' },
  { id: 'nav-help', icon: 'help', label: 'Trợ giúp' },
]
