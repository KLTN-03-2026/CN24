import { useCallback, useEffect, useMemo, useState } from 'react'
import './App.css'
import {
  countOnlineDrivers,
  countTrips,
  countUsers,
  deleteTrip,
  getRecentRideRequests,
  getRecentTrips,
  getTotalRevenue,
  getUsers,
  onAllDrivers,
  onAllTrips,
  onOnlineDrivers,
  onRecentRideRequests,
  onRecentTrips,
} from './firestoreService'

/* ===== Icon Components (SVG inline) ===== */
const Icons = {
  dashboard: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" />
    </svg>
  ),
  car: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2" />
      <circle cx="7" cy="17" r="2" /><circle cx="17" cy="17" r="2" />
    </svg>
  ),
  users: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M22 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  ),
  driver: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4z" /><path d="M6 20v-2c0-2.21 1.79-4 4-4h4c2.21 0 4 1.79 4 4v2" /><path d="M15 7l2 2-2 2" />
    </svg>
  ),
  chart: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="20" x2="18" y2="10" /><line x1="12" y1="20" x2="12" y2="4" /><line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  ),
  wallet: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="1" y="4" width="22" height="16" rx="2" /><line x1="1" y1="10" x2="23" y2="10" />
    </svg>
  ),
  settings: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  ),
  bell: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  ),
  search: (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  ),
  trendUp: (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 6 13.5 15.5 8.5 10.5 1 18" /><polyline points="17 6 23 6 23 12" />
    </svg>
  ),
  map: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6" /><line x1="8" y1="2" x2="8" y2="18" /><line x1="16" y1="6" x2="16" y2="22" />
    </svg>
  ),
  help: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" /><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" /><line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  ),
  logout: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  ),
  refresh: (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 4 23 10 17 10" /><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
    </svg>
  ),
  live: (
    <svg width="8" height="8" viewBox="0 0 8 8"><circle cx="4" cy="4" r="4" fill="#22c55e" /></svg>
  ),
}

/* ===== Format helpers ===== */
function formatCurrency(amount) {
  if (amount >= 1000000000) return `${(amount / 1000000000).toFixed(1)} tỷ`
  if (amount >= 1000000) return `${(amount / 1000000).toFixed(1)} tr`
  if (amount >= 1000) return `${(amount / 1000).toFixed(0)}K`
  return amount.toLocaleString('vi-VN')
}

function formatNumber(num) {
  return num.toLocaleString('vi-VN')
}

function formatFare(fare) {
  return `${Math.round(fare).toLocaleString('vi-VN')}₫`
}

function getInitials(name) {
  if (!name) return '??'
  const parts = name.trim().split(' ')
  if (parts.length === 1) return parts[0][0]?.toUpperCase() || '?'
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
}

function timeAgo(timestamp) {
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

/* ===== Sidebar Links ===== */
const sidebarLinks = [
  { section: 'Tổng quan' },
  { id: 'nav-dashboard', icon: 'dashboard', label: 'Dashboard', active: true },
  { id: 'nav-analytics', icon: 'chart', label: 'Phân tích' },
  { section: 'Quản lý' },
  { id: 'nav-rides', icon: 'car', label: 'Chuyến đi' },
  { id: 'nav-drivers', icon: 'driver', label: 'Tài xế' },
  { id: 'nav-customers', icon: 'users', label: 'Khách hàng' },
  { id: 'nav-map', icon: 'map', label: 'Bản đồ' },
  { section: 'Tài chính' },
  { id: 'nav-payments', icon: 'wallet', label: 'Thanh toán' },
  { section: 'Hệ thống' },
  { id: 'nav-settings', icon: 'settings', label: 'Cài đặt' },
  { id: 'nav-help', icon: 'help', label: 'Trợ giúp' },
]

/* ===== Get Vietnamese date ===== */
function getVietnameseDate() {
  const days = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy']
  const now = new Date()
  return `${days[now.getDay()]}, ${now.getDate()} tháng ${String(now.getMonth() + 1).padStart(2, '0')} năm ${now.getFullYear()}`
}

/* ===== Status mapping ===== */
const statusMap = {
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

/* ===== Sidebar Component ===== */
function Sidebar({ activeNav, onNavClick, onlineDriverCount }) {
  return (
    <aside className="sidebar" id="sidebar">
      <div className="sidebar__brand">
        <div className="sidebar__logo">RN</div>
        <div className="sidebar__brand-text">
          <h1>Ride Now</h1>
          <span>Admin Panel</span>
        </div>
      </div>

      <nav className="sidebar__nav">
        {sidebarLinks.map((item, idx) => {
          if (item.section) {
            return <div key={`section-${idx}`} className="sidebar__section-title">{item.section}</div>
          }

          // Dynamic badge cho drivers online
          let badge = null
          if (item.id === 'nav-drivers' && onlineDriverCount > 0) {
            badge = onlineDriverCount
          }

          return (
            <button
              key={item.id}
              id={item.id}
              className={`sidebar__link ${activeNav === item.id ? 'sidebar__link--active' : ''}`}
              onClick={() => onNavClick(item.id)}
            >
              <span className="sidebar__link-icon">{Icons[item.icon]}</span>
              {item.label}
              {badge != null && <span className="sidebar__link-badge">{badge}</span>}
            </button>
          )
        })}
      </nav>

      <div className="sidebar__footer">
        <div className="sidebar__user">
          <div className="sidebar__avatar">AD</div>
          <div className="sidebar__user-info">
            <div className="sidebar__user-name">Admin</div>
            <div className="sidebar__user-role">Quản trị viên</div>
          </div>
          <span style={{ color: 'var(--surface-500)', cursor: 'pointer' }}>{Icons.logout}</span>
        </div>
      </div>
    </aside>
  )
}

/* ===== Header Component ===== */
function Header({ isLive, onRefresh, loading }) {
  return (
    <header className="header" id="header">
      <div className="header__left">
        <h2 className="header__greeting">
          Xin chào, <span>Admin</span> 👋
        </h2>
        <p className="header__date">
          {getVietnameseDate()}
          {isLive && (
            <span style={{ marginLeft: '12px', display: 'inline-flex', alignItems: 'center', gap: '6px', color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>
              {Icons.live} Realtime
            </span>
          )}
        </p>
      </div>
      <div className="header__actions">
        <div className="header__search">
          <span className="header__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="header__search-input"
            id="search-input"
            placeholder="Tìm kiếm chuyến đi, tài xế..."
          />
        </div>
        <button
          className="header__icon-btn"
          id="btn-refresh"
          title="Tải lại dữ liệu"
          onClick={onRefresh}
          style={loading ? { animation: 'spin 1s linear infinite' } : {}}
        >
          {Icons.refresh}
        </button>
        <button className="header__icon-btn" id="btn-notifications" title="Thông báo">
          {Icons.bell}
          <span className="badge">3</span>
        </button>
        <button className="header__icon-btn" id="btn-settings" title="Cài đặt">
          {Icons.settings}
        </button>
      </div>
    </header>
  )
}

/* ===== Loading Skeleton ===== */
function StatSkeleton() {
  return (
    <div className="stat-card" style={{ opacity: 0.5 }}>
      <div className="stat-card__header">
        <div style={{ width: 48, height: 48, borderRadius: 'var(--radius-lg)', background: 'var(--surface-800)' }} />
      </div>
      <div style={{ width: '60%', height: 32, background: 'var(--surface-800)', borderRadius: 'var(--radius-md)', marginTop: 12 }} />
      <div style={{ width: '40%', height: 16, background: 'var(--surface-800)', borderRadius: 'var(--radius-md)', marginTop: 8 }} />
    </div>
  )
}

/* ===== Stat Card Component ===== */
function StatCard({ data, onClick }) {
  return (
    <div
      className={`stat-card stat-card--${data.type} ${onClick ? 'stat-card--clickable' : ''}`}
      id={`stat-${data.id}`}
      onClick={onClick}
    >
      <div className="stat-card__header">
        <div className="stat-card__icon">
          <span style={{ fontSize: '1.5rem' }}>{data.icon}</span>
        </div>
        {data.subtitle && (
          <div className="stat-card__trend stat-card__trend--up">
            {Icons.trendUp}
            {data.subtitle}
          </div>
        )}
      </div>
      <div className="stat-card__value">{data.value}</div>
      <div className="stat-card__label">{data.label}</div>
    </div>
  )
}

/* ===== Driver Modal Component ===== */
function DriverModal({ drivers, onClose }) {
  if (!drivers) return null

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">👨‍✈️ Danh sách tài xế ({drivers.length})</h2>
          <button className="modal__close" onClick={onClose} id="btn-close-modal">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>
        <div className="modal__body">
          {drivers.length === 0 ? (
            <p className="modal__empty">Không có tài xế nào</p>
          ) : (
            <div className="driver-list">
              {drivers.map((driver, idx) => (
                <div className="driver-card" key={driver.id || idx}>
                  <div className="driver-card__left">
                    <div className="driver-card__avatar">
                      {getInitials(driver.name)}
                      <span className={`driver-card__status-dot ${driver.isOnline ? 'driver-card__status-dot--online' : ''}`} />
                    </div>
                    <div className="driver-card__info">
                      <h4 className="driver-card__name">{driver.name || '—'}</h4>
                      <p className="driver-card__email">{driver.email || '—'}</p>
                      {driver.phone && <p className="driver-card__phone">📱 {driver.phone}</p>}
                    </div>
                  </div>
                  <div className="driver-card__right">
                    <div className="driver-card__meta">
                      <span className="driver-card__rating">⭐ {(driver.rating || 0).toFixed(1)}</span>
                      <span className="driver-card__trips">🚗 {driver.totalTrips || 0} chuyến</span>
                    </div>
                    {driver.vehicleType && (
                      <p className="driver-card__vehicle">
                        🏍️ {driver.vehicleType} {driver.vehiclePlate ? `· ${driver.vehiclePlate}` : ''}
                      </p>
                    )}
                    {driver.earnings > 0 && (
                      <p className="driver-card__earnings">💰 {formatFare(driver.earnings)}</p>
                    )}
                    <span className={`driver-card__badge ${driver.isOnline ? 'driver-card__badge--online' : 'driver-card__badge--offline'}`}>
                      {driver.isOnline ? '🟢 Online' : '⚫ Offline'}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

/* ===== Chart Component (CSS-only) ===== */
function ChartSection({ trips }) {
  const [activeTab, setActiveTab] = useState('week')

  // Tính số chuyến đi theo ngày trong tuần từ trips thật
  const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
  const dayCounts = [0, 0, 0, 0, 0, 0, 0]

  if (trips && trips.length > 0) {
    trips.forEach(trip => {
      let date
      if (trip.createdAt?.seconds) {
        date = new Date(trip.createdAt.seconds * 1000)
      } else {
        date = new Date(trip.createdAt)
      }
      const dayIndex = (date.getDay() + 6) % 7 // Monday = 0
      dayCounts[dayIndex]++
    })
  }

  const maxVal = Math.max(...dayCounts, 1)

  return (
    <div className="chart-card" id="chart-section">
      <div className="chart-card__header">
        <h3 className="chart-card__title">Tổng quan chuyến đi</h3>
        <div className="chart-card__tabs">
          {['week', 'month', 'year'].map(tab => (
            <button
              key={tab}
              id={`chart-tab-${tab}`}
              className={`chart-card__tab ${activeTab === tab ? 'chart-card__tab--active' : ''}`}
              onClick={() => setActiveTab(tab)}
            >
              {tab === 'week' ? 'Tuần' : tab === 'month' ? 'Tháng' : 'Năm'}
            </button>
          ))}
        </div>
      </div>
      <div className="mini-chart">
        {dayLabels.map((label, idx) => (
          <div className="mini-chart__bar-group" key={idx}>
            <div
              className="mini-chart__bar mini-chart__bar--primary"
              style={{
                height: `${Math.max((dayCounts[idx] / maxVal) * 100, 4)}%`,
              }}
              title={`${label}: ${dayCounts[idx]} chuyến`}
            />
            <span className="mini-chart__label">{label}</span>
          </div>
        ))}
      </div>
      {trips.length === 0 && (
        <p style={{ textAlign: 'center', color: 'var(--surface-500)', fontSize: 'var(--font-sm)', marginTop: 16 }}>
          Chưa có dữ liệu chuyến đi
        </p>
      )}
    </div>
  )
}

/* ===== Activity Feed Component ===== */

function ActivityFeed({ rideRequests }) {
  const getActivityIcon = (status) => {
    if (status === 'completed') return { icon: '✅', type: 'ride' }
    if (status === 'cancelled' || status === 'rejected') return { icon: '❌', type: 'alert' }
    if (status === 'accepted' || status === 'driver_assigned') return { icon: '🚗', type: 'ride' }
    if (status === 'on_the_way' || status === 'ongoing') return { icon: '🛣️', type: 'ride' }
    return { icon: '📋', type: 'payment' }
  }

  const getActivityText = (req) => {
    const name = req.customerName || 'Khách hàng'
    const st = statusMap[req.status] || { label: req.status }
    const fare = req.fare ? ` - ${formatFare(req.fare)}` : ''
    return `<strong>${name}</strong> — ${st.label}${fare}`
  }

  return (
    <div className="activity-card" id="activity-feed">
      <div className="activity-card__header">
        <h3 className="activity-card__title">Hoạt động gần đây</h3>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>
          {Icons.live} Live
        </span>
      </div>
      <div className="activity-list">
        {rideRequests.length === 0 ? (
          <p style={{ textAlign: 'center', color: 'var(--surface-500)', fontSize: 'var(--font-sm)', padding: '24px 0' }}>
            Chưa có hoạt động nào
          </p>
        ) : (
          rideRequests.slice(0, 8).map((req, idx) => {
            const { icon, type } = getActivityIcon(req.status)
            return (
              <div className="activity-item" key={req.id || idx} id={`activity-${idx}`}>
                <div className={`activity-item__icon activity-item__icon--${type}`}>
                  {icon}
                </div>
                <div className="activity-item__content">
                  <p className="activity-item__text" dangerouslySetInnerHTML={{ __html: getActivityText(req) }} />
                  <span className="activity-item__time">
                    {req.pickupAddress && `${req.pickupAddress} → ${req.destinationAddress}`}
                    {' · '}{timeAgo(req.createdAt)}
                  </span>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}

/* ===== Recent Trips Table ===== */
function RecentTrips({ trips }) {
  return (
    <div className="table-card" id="recent-rides">
      <div className="table-card__header">
        <h3 className="table-card__title">
          Chuyến đi gần đây
          <span style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', fontWeight: 400, marginLeft: 8 }}>
            ({trips.length} chuyến)
          </span>
        </h3>
      </div>

      {trips.length === 0 ? (
        <p style={{ textAlign: 'center', color: 'var(--surface-500)', fontSize: 'var(--font-sm)', padding: '40px 0' }}>
          Chưa có chuyến đi nào trong hệ thống
        </p>
      ) : (
        <div style={{ overflowX: 'auto' }}>
          <table className="table">
            <thead>
              <tr>
                <th>Mã chuyến</th>
                <th>Khách hàng</th>
                <th>Tài xế</th>
                <th>Điểm đón</th>
                <th>Điểm đến</th>
                <th>Giá tiền</th>
                <th>Thanh toán</th>
                <th>Trạng thái</th>
                <th>Thời gian</th>
              </tr>
            </thead>
            <tbody>
              {trips.map((trip, idx) => {
                const st = statusMap[trip.status] || { label: trip.status || '—', css: 'active' }
                return (
                  <tr key={trip.id || idx} id={`ride-${trip.id || idx}`}>
                    <td style={{ fontWeight: 600, color: 'var(--primary-400)', fontSize: 'var(--font-xs)' }}>
                      {trip.id ? trip.id.slice(0, 8).toUpperCase() : '—'}
                    </td>
                    <td>
                      <div className="table__rider">
                        <div className="table__rider-avatar">{getInitials(trip.customerName)}</div>
                        <span className="table__rider-name">{trip.customerName || '—'}</span>
                      </div>
                    </td>
                    <td>{trip.driverName || '—'}</td>
                    <td style={{ maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                      title={trip.pickupAddress}>
                      {trip.pickupAddress || '—'}
                    </td>
                    <td style={{ maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                      title={trip.destinationAddress}>
                      {trip.destinationAddress || '—'}
                    </td>
                    <td style={{ fontWeight: 600 }}>
                      {trip.fare ? formatFare(trip.fare) : '—'}
                    </td>
                    <td>{trip.paymentMethod || 'Tiền mặt'}</td>
                    <td>
                      <span className={`table__status table__status--${st.css}`}>
                        <span className="table__status-dot" />
                        {st.label}
                      </span>
                    </td>
                    <td style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-400)' }}>
                      {timeAgo(trip.createdAt)}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

/* ===== Confirm Delete Modal ===== */
function ConfirmDeleteModal({ trip, onConfirm, onCancel, deleting }) {
  if (!trip) return null
  return (
    <div className="modal-overlay" onClick={onCancel}>
      <div className="confirm-modal" onClick={(e) => e.stopPropagation()}>
        <div className="confirm-modal__icon">🗑️</div>
        <h3 className="confirm-modal__title">Xác nhận xóa chuyến đi</h3>
        <p className="confirm-modal__text">
          Bạn có chắc chắn muốn xóa chuyến đi <strong>{trip.id?.slice(0, 8).toUpperCase()}</strong>?
        </p>
        <p className="confirm-modal__sub">
          {trip.customerName && `Khách: ${trip.customerName}`}
          {trip.fare ? ` · ${formatFare(trip.fare)}` : ''}
        </p>
        <p className="confirm-modal__warning">⚠️ Hành động này không thể hoàn tác!</p>
        <div className="confirm-modal__actions">
          <button className="confirm-modal__btn confirm-modal__btn--cancel" onClick={onCancel} disabled={deleting}>
            Hủy
          </button>
          <button className="confirm-modal__btn confirm-modal__btn--delete" onClick={onConfirm} disabled={deleting}>
            {deleting ? (
              <><span className="confirm-modal__spinner" /> Đang xóa...</>
            ) : (
              '🗑️ Xóa chuyến đi'
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ===== Trip Detail Modal ===== */
function TripDetailModal({ trip, onClose, onDelete }) {
  if (!trip) return null
  const st = statusMap[trip.status] || { label: trip.status || '—', css: 'active' }

  const formatDate = (timestamp) => {
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

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal trip-detail-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">🚗 Chi tiết chuyến đi</h2>
          <button className="modal__close" onClick={onClose}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>
        <div className="modal__body">
          <div className="trip-detail">
            {/* Trip ID + Status */}
            <div className="trip-detail__row trip-detail__row--highlight">
              <span className="trip-detail__label">Mã chuyến</span>
              <span className="trip-detail__value trip-detail__id">{trip.id?.toUpperCase() || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">Trạng thái</span>
              <span className={`table__status table__status--${st.css}`}>
                <span className="table__status-dot" />
                {st.label}
              </span>
            </div>

            <div className="trip-detail__divider" />

            {/* Customer & Driver */}
            <div className="trip-detail__row">
              <span className="trip-detail__label">👤 Khách hàng</span>
              <span className="trip-detail__value">{trip.customerName || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">🚘 Tài xế</span>
              <span className="trip-detail__value">{trip.driverName || '—'}</span>
            </div>

            <div className="trip-detail__divider" />

            {/* Addresses */}
            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">📍 Điểm đón</span>
              <span className="trip-detail__value trip-detail__address">{trip.pickupAddress || '—'}</span>
            </div>
            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">📍 Điểm đến</span>
              <span className="trip-detail__value trip-detail__address">{trip.destinationAddress || '—'}</span>
            </div>

            <div className="trip-detail__divider" />

            {/* Fare & Payment */}
            <div className="trip-detail__row">
              <span className="trip-detail__label">💰 Giá tiền</span>
              <span className="trip-detail__value trip-detail__fare">{trip.fare ? formatFare(trip.fare) : '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">💳 Thanh toán</span>
              <span className="trip-detail__value">{trip.paymentMethod || 'Tiền mặt'}</span>
            </div>
            {trip.distance && (
              <div className="trip-detail__row">
                <span className="trip-detail__label">📏 Khoảng cách</span>
                <span className="trip-detail__value">{(trip.distance || trip.distanceInKm || 0).toFixed(1)} km</span>
              </div>
            )}

            <div className="trip-detail__divider" />

            {/* Times */}
            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Tạo lúc</span>
              <span className="trip-detail__value">{formatDate(trip.createdAt)}</span>
            </div>
            {trip.completedAt && (
              <div className="trip-detail__row">
                <span className="trip-detail__label">✅ Hoàn thành</span>
                <span className="trip-detail__value">{formatDate(trip.completedAt)}</span>
              </div>
            )}
          </div>

          {/* Delete button */}
          <div className="trip-detail__footer">
            <button className="trip-detail__delete-btn" onClick={() => onDelete(trip)}>
              🗑️ Xóa chuyến đi
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

/* ===== Rides Management Page ===== */
function RidesPage() {
  const [allTrips, setAllTrips] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedTrip, setSelectedTrip] = useState(null)
  const [deletingTrip, setDeletingTrip] = useState(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [toast, setToast] = useState(null)

  // Server-side stats (accurate, from Firestore aggregation)
  const [serverStats, setServerStats] = useState({
    total: 0, completed: 0, active: 0, cancelled: 0, revenue: 0,
  })

  // Status filter tabs
  const statusTabs = [
    { key: 'all', label: 'Tất cả' },
    { key: 'completed', label: 'Hoàn thành' },
    { key: 'on_the_way', label: 'Đang đi' },
    { key: 'accepted', label: 'Đã nhận' },
    { key: 'cancelled', label: 'Đã hủy' },
    { key: 'pending', label: 'Chờ xử lý' },
  ]

  // Load accurate stats from Firestore (server-side aggregation)
  const loadServerStats = useCallback(async () => {
    try {
      const [total, completed, onTheWay, accepted, pending, driverAssigned, searchingDriver, cancelled, rejected, timeout, revenue] =
        await Promise.all([
          countTrips(),
          countTrips('completed'),
          countTrips('on_the_way'),
          countTrips('accepted'),
          countTrips('pending'),
          countTrips('driver_assigned'),
          countTrips('searching_driver'),
          countTrips('cancelled'),
          countTrips('rejected'),
          countTrips('timeout'),
          getTotalRevenue(),
        ])
      setServerStats({
        total,
        completed,
        active: onTheWay + accepted + pending + driverAssigned + searchingDriver,
        cancelled: cancelled + rejected + timeout,
        revenue,
      })
    } catch (error) {
      console.error('Error loading server stats:', error)
    }
  }, [])

  // Load stats on mount and when trips change
  useEffect(() => {
    loadServerStats()
  }, [loadServerStats, allTrips])

  // Realtime listener with status filter
  useEffect(() => {
    setLoading(true)
    const unsub = onAllTrips((trips) => {
      setAllTrips(trips)
      setLoading(false)
    }, statusFilter === 'all' ? null : statusFilter, 200)

    return () => unsub()
  }, [statusFilter])

  // Show toast
  const showToast = useCallback((message, type = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3000)
  }, [])

  // Filter trips by search query
  const filteredTrips = useMemo(() => {
    if (!searchQuery.trim()) return allTrips
    const q = searchQuery.toLowerCase()
    return allTrips.filter(trip =>
      (trip.customerName?.toLowerCase().includes(q)) ||
      (trip.driverName?.toLowerCase().includes(q)) ||
      (trip.pickupAddress?.toLowerCase().includes(q)) ||
      (trip.destinationAddress?.toLowerCase().includes(q)) ||
      (trip.id?.toLowerCase().includes(q))
    )
  }, [allTrips, searchQuery])

  // Handle delete trip
  const handleDeleteTrip = useCallback(async () => {
    if (!deletingTrip) return
    setIsDeleting(true)
    const result = await deleteTrip(deletingTrip.id)
    setIsDeleting(false)
    if (result.success) {
      showToast(`Đã xóa chuyến đi ${deletingTrip.id.slice(0, 8).toUpperCase()} thành công!`, 'success')
      setDeletingTrip(null)
      setSelectedTrip(null)
    } else {
      showToast(`Lỗi: ${result.error}`, 'error')
    }
  }, [deletingTrip, showToast])

  // Use server stats for display
  const tripStats = serverStats

  return (
    <section className="rides-page" id="rides-page">
      {/* Page Header */}
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🚗 Quản lý chuyến đi</h2>
          <p className="rides-page__subtitle">Theo dõi và quản lý tất cả chuyến đi trong hệ thống</p>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{tripStats.total}</span>
          <span className="rides-stat__label">Tổng chuyến</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{tripStats.completed}</span>
          <span className="rides-stat__label">Hoàn thành</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <span className="rides-stat__number">{tripStats.active}</span>
          <span className="rides-stat__label">Đang hoạt động</span>
        </div>
        <div className="rides-stat rides-stat--cancelled">
          <span className="rides-stat__number">{tripStats.cancelled}</span>
          <span className="rides-stat__label">Đã hủy</span>
        </div>
        <div className="rides-stat rides-stat--revenue">
          <span className="rides-stat__number">{formatCurrency(tripStats.revenue)}</span>
          <span className="rides-stat__label">Doanh thu</span>
        </div>
      </div>

      {/* Toolbar: Search + Filter */}
      <div className="rides-toolbar">
        <div className="rides-toolbar__search">
          <span className="rides-toolbar__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="rides-toolbar__search-input"
            placeholder="Tìm theo tên, địa chỉ, mã chuyến..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button className="rides-toolbar__search-clear" onClick={() => setSearchQuery('')}>
              ✕
            </button>
          )}
        </div>
        <div className="rides-toolbar__filters">
          {statusTabs.map(tab => (
            <button
              key={tab.key}
              className={`rides-toolbar__filter-btn ${statusFilter === tab.key ? 'rides-toolbar__filter-btn--active' : ''}`}
              onClick={() => setStatusFilter(tab.key)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Trips Table */}
      <div className="table-card rides-table-card">
        <div className="table-card__header">
          <h3 className="table-card__title">
            Danh sách chuyến đi
            <span style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', fontWeight: 400, marginLeft: 8 }}>
              ({filteredTrips.length} chuyến{searchQuery ? ` · tìm kiếm: "${searchQuery}"` : ''})
            </span>
          </h3>
        </div>

        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách chuyến đi...</p>
          </div>
        ) : filteredTrips.length === 0 ? (
          <div className="rides-empty">
            <span className="rides-empty__icon">🚗</span>
            <p className="rides-empty__text">
              {searchQuery ? `Không tìm thấy chuyến đi nào cho "${searchQuery}"` : 'Chưa có chuyến đi nào'}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Mã chuyến</th>
                  <th>Khách hàng</th>
                  <th>Tài xế</th>
                  <th>Điểm đón</th>
                  <th>Điểm đến</th>
                  <th>Giá tiền</th>
                  <th>Trạng thái</th>
                  <th>Thời gian</th>
                  <th style={{ textAlign: 'center' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredTrips.map((trip, idx) => {
                  const st = statusMap[trip.status] || { label: trip.status || '—', css: 'active' }
                  return (
                    <tr key={trip.id || idx} className="rides-table__row">
                      <td
                        className="rides-table__id"
                        onClick={() => setSelectedTrip(trip)}
                        title="Xem chi tiết"
                      >
                        {trip.id ? trip.id.slice(0, 8).toUpperCase() : '—'}
                      </td>
                      <td>
                        <div className="table__rider">
                          <div className="table__rider-avatar">{getInitials(trip.customerName)}</div>
                          <span className="table__rider-name">{trip.customerName || '—'}</span>
                        </div>
                      </td>
                      <td>{trip.driverName || '—'}</td>
                      <td style={{ maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                        title={trip.pickupAddress}>
                        {trip.pickupAddress || '—'}
                      </td>
                      <td style={{ maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}
                        title={trip.destinationAddress}>
                        {trip.destinationAddress || '—'}
                      </td>
                      <td style={{ fontWeight: 600 }}>
                        {trip.fare ? formatFare(trip.fare) : '—'}
                      </td>
                      <td>
                        <span className={`table__status table__status--${st.css}`}>
                          <span className="table__status-dot" />
                          {st.label}
                        </span>
                      </td>
                      <td style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-400)' }}>
                        {timeAgo(trip.createdAt)}
                      </td>
                      <td>
                        <div className="rides-table__actions">
                          <button
                            className="rides-table__action-btn rides-table__action-btn--view"
                            title="Xem chi tiết"
                            onClick={() => setSelectedTrip(trip)}
                          >
                            👁️
                          </button>
                          <button
                            className="rides-table__action-btn rides-table__action-btn--delete"
                            title="Xóa chuyến đi"
                            onClick={() => setDeletingTrip(trip)}
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Trip Detail Modal */}
      {selectedTrip && (
        <TripDetailModal
          trip={selectedTrip}
          onClose={() => setSelectedTrip(null)}
          onDelete={(trip) => { setSelectedTrip(null); setDeletingTrip(trip); }}
        />
      )}

      {/* Confirm Delete Modal */}
      {deletingTrip && (
        <ConfirmDeleteModal
          trip={deletingTrip}
          onConfirm={handleDeleteTrip}
          onCancel={() => setDeletingTrip(null)}
          deleting={isDeleting}
        />
      )}

      {/* Toast */}
      {toast && (
        <div className={`rides-toast rides-toast--${toast.type}`}>
          {toast.type === 'success' ? '✅' : '❌'} {toast.message}
        </div>
      )}
    </section>
  )
}

/* ===== Driver Detail Modal ===== */
function DriverDetailModal({ driver, onClose }) {
  if (!driver) return null

  const formatDate = (timestamp) => {
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

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal driver-detail-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">👨‍✈️ Thông tin tài xế</h2>
          <button className="modal__close" onClick={onClose}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>
        <div className="modal__body">
          {/* Avatar + Name */}
          <div className="driver-detail__profile">
            <div className="driver-detail__avatar">
              {getInitials(driver.name)}
              <span className={`driver-detail__online-dot ${driver.isOnline ? 'driver-detail__online-dot--active' : ''}`} />
            </div>
            <div className="driver-detail__name-block">
              <h3 className="driver-detail__name">{driver.name || '—'}</h3>
              <span className={`driver-detail__status-badge ${driver.isOnline ? 'driver-detail__status-badge--online' : 'driver-detail__status-badge--offline'}`}>
                {driver.isOnline ? '🟢 Đang online' : '⚫ Offline'}
              </span>
            </div>
          </div>

          <div className="driver-detail__stats-row">
            <div className="driver-detail__stat">
              <span className="driver-detail__stat-value">⭐ {(driver.rating || 0).toFixed(1)}</span>
              <span className="driver-detail__stat-label">Đánh giá</span>
            </div>
            <div className="driver-detail__stat">
              <span className="driver-detail__stat-value">🚗 {driver.totalTrips || 0}</span>
              <span className="driver-detail__stat-label">Chuyến đi</span>
            </div>
            <div className="driver-detail__stat">
              <span className="driver-detail__stat-value">💰 {driver.earnings ? formatFare(driver.earnings) : '0₫'}</span>
              <span className="driver-detail__stat-label">Thu nhập</span>
            </div>
          </div>

          <div className="trip-detail">
            <div className="trip-detail__divider" />

            <div className="trip-detail__row">
              <span className="trip-detail__label">📧 Email</span>
              <span className="trip-detail__value">{driver.email || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">📱 Số điện thoại</span>
              <span className="trip-detail__value">{driver.phone || '—'}</span>
            </div>

            <div className="trip-detail__divider" />
            <div className="trip-detail__row trip-detail__row--highlight" style={{ marginBottom: 4 }}>
              <span className="trip-detail__label" style={{ fontWeight: 600, color: 'var(--primary-400)' }}>🏍️ Thông tin xe</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">Loại xe</span>
              <span className="trip-detail__value">{driver.vehicleType || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">Biển số xe</span>
              <span className="trip-detail__value" style={{ fontFamily: 'monospace', fontWeight: 700, color: 'var(--warning-400)' }}>{driver.vehiclePlate || '—'}</span>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Ngày đăng ký</span>
              <span className="trip-detail__value">{formatDate(driver.createdAt)}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">📍 Sẵn sàng nhận khách</span>
              <span className="trip-detail__value">{driver.isAvailable ? '✅ Có' : '❌ Không'}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

/* ===== Drivers Management Page ===== */
function DriversPage() {
  const [drivers, setDrivers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedDriver, setSelectedDriver] = useState(null)
  const [totalDrivers, setTotalDrivers] = useState(0)

  const statusTabs = [
    { key: 'all', label: 'Tất cả' },
    { key: 'online', label: 'Online' },
    { key: 'offline', label: 'Offline' },
  ]

  // Realtime driver list
  useEffect(() => {
    setLoading(true)
    const unsub = onAllDrivers((driverList) => {
      setDrivers(driverList)
      setTotalDrivers(driverList.length)
      setLoading(false)
    })
    return () => unsub()
  }, [])

  // Filter by status and search
  const filteredDrivers = useMemo(() => {
    let result = drivers
    // Filter by online status
    if (statusFilter === 'online') {
      result = result.filter(d => d.isOnline === true)
    } else if (statusFilter === 'offline') {
      result = result.filter(d => !d.isOnline)
    }
    // Filter by search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter(d =>
        (d.name?.toLowerCase().includes(q)) ||
        (d.email?.toLowerCase().includes(q)) ||
        (d.phone?.includes(q)) ||
        (d.vehiclePlate?.toLowerCase().includes(q)) ||
        (d.vehicleType?.toLowerCase().includes(q))
      )
    }
    return result
  }, [drivers, statusFilter, searchQuery])

  // Stats
  const driverStats = useMemo(() => {
    const total = drivers.length
    const online = drivers.filter(d => d.isOnline).length
    const offline = total - online
    const avgRating = total > 0 ? (drivers.reduce((sum, d) => sum + (d.rating || 0), 0) / total).toFixed(1) : '0.0'
    const totalEarnings = drivers.reduce((sum, d) => sum + (d.earnings || 0), 0)
    return { total, online, offline, avgRating, totalEarnings }
  }, [drivers])

  return (
    <section className="rides-page" id="drivers-page">
      {/* Page Header */}
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">👨‍✈️ Quản lý tài xế</h2>
          <p className="rides-page__subtitle">Danh sách tất cả tài xế đã đăng ký trong hệ thống</p>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{driverStats.total}</span>
          <span className="rides-stat__label">Tổng tài xế</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{driverStats.online}</span>
          <span className="rides-stat__label">Đang online</span>
        </div>
        <div className="rides-stat rides-stat--cancelled">
          <span className="rides-stat__number">{driverStats.offline}</span>
          <span className="rides-stat__label">Offline</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <span className="rides-stat__number">⭐ {driverStats.avgRating}</span>
          <span className="rides-stat__label">Đánh giá TB</span>
        </div>
        <div className="rides-stat rides-stat--revenue">
          <span className="rides-stat__number">{formatCurrency(driverStats.totalEarnings)}</span>
          <span className="rides-stat__label">Tổng thu nhập</span>
        </div>
      </div>

      {/* Toolbar */}
      <div className="rides-toolbar">
        <div className="rides-toolbar__search">
          <span className="rides-toolbar__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="rides-toolbar__search-input"
            placeholder="Tìm theo tên, email, SĐT, biển số xe..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button className="rides-toolbar__search-clear" onClick={() => setSearchQuery('')}>
              ✕
            </button>
          )}
        </div>
        <div className="rides-toolbar__filters">
          {statusTabs.map(tab => (
            <button
              key={tab.key}
              className={`rides-toolbar__filter-btn ${statusFilter === tab.key ? 'rides-toolbar__filter-btn--active' : ''}`}
              onClick={() => setStatusFilter(tab.key)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Drivers Table */}
      <div className="table-card rides-table-card">
        <div className="table-card__header">
          <h3 className="table-card__title">
            Danh sách tài xế
            <span style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', fontWeight: 400, marginLeft: 8 }}>
              ({filteredDrivers.length} tài xế{searchQuery ? ` · tìm kiếm: "${searchQuery}"` : ''})
            </span>
          </h3>
        </div>

        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách tài xế...</p>
          </div>
        ) : filteredDrivers.length === 0 ? (
          <div className="rides-empty">
            <span className="rides-empty__icon">👨‍✈️</span>
            <p className="rides-empty__text">
              {searchQuery ? `Không tìm thấy tài xế nào cho "${searchQuery}"` : 'Chưa có tài xế nào'}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Tài xế</th>
                  <th>Email</th>
                  <th>SĐT</th>
                  <th>Loại xe</th>
                  <th>Biển số</th>
                  <th>Đánh giá</th>
                  <th>Chuyến đi</th>
                  <th>Thu nhập</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'center' }}>Chi tiết</th>
                </tr>
              </thead>
              <tbody>
                {filteredDrivers.map((driver, idx) => (
                  <tr key={driver.id || idx} className="rides-table__row">
                    <td>
                      <div className="table__rider">
                        <div className="table__rider-avatar" style={{ position: 'relative' }}>
                          {getInitials(driver.name)}
                          <span
                            className="drivers-table__online-indicator"
                            style={{
                              position: 'absolute', bottom: -1, right: -1,
                              width: 10, height: 10, borderRadius: '50%',
                              background: driver.isOnline ? 'var(--success-400)' : 'var(--surface-600)',
                              border: '2px solid var(--surface-900)',
                            }}
                          />
                        </div>
                        <span className="table__rider-name">{driver.name || '—'}</span>
                      </div>
                    </td>
                    <td style={{ fontSize: 'var(--font-xs)' }}>{driver.email || '—'}</td>
                    <td>{driver.phone || '—'}</td>
                    <td>
                      {driver.vehicleType ? (
                        <span className="drivers-table__vehicle-type">
                          🏍️ {driver.vehicleType}
                        </span>
                      ) : '—'}
                    </td>
                    <td>
                      {driver.vehiclePlate ? (
                        <span className="drivers-table__plate">{driver.vehiclePlate}</span>
                      ) : '—'}
                    </td>
                    <td>
                      <span className="drivers-table__rating">⭐ {(driver.rating || 0).toFixed(1)}</span>
                    </td>
                    <td style={{ fontWeight: 600 }}>{driver.totalTrips || 0}</td>
                    <td style={{ fontWeight: 600, color: 'var(--warning-400)' }}>
                      {driver.earnings ? formatFare(driver.earnings) : '0₫'}
                    </td>
                    <td>
                      <span className={`table__status ${driver.isOnline ? 'table__status--completed' : 'table__status--cancelled'}`}>
                        <span className="table__status-dot" />
                        {driver.isOnline ? 'Online' : 'Offline'}
                      </span>
                    </td>
                    <td>
                      <div className="rides-table__actions">
                        <button
                          className="rides-table__action-btn rides-table__action-btn--view"
                          title="Xem chi tiết"
                          onClick={() => setSelectedDriver(driver)}
                        >
                          👁️
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Driver Detail Modal */}
      {selectedDriver && (
        <DriverDetailModal
          driver={selectedDriver}
          onClose={() => setSelectedDriver(null)}
        />
      )}
    </section>
  )
}

/* ===== Connection Status Banner ===== */
function ConnectionBanner({ status, error }) {
  if (status === 'connected') return null

  const styles = {
    padding: '12px 24px',
    textAlign: 'center',
    fontSize: 'var(--font-sm)',
    fontWeight: 500,
    animation: 'fadeInUp 0.3s ease-out',
  }

  if (status === 'loading') {
    return (
      <div style={{ ...styles, background: 'rgba(99, 102, 241, 0.1)', color: 'var(--primary-400)', borderBottom: '1px solid rgba(99, 102, 241, 0.2)' }}>
        ⏳ Đang kết nối Firebase... Đang tải dữ liệu thật từ Firestore
      </div>
    )
  }

  if (status === 'error') {
    return (
      <div style={{ ...styles, background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger-400)', borderBottom: '1px solid rgba(239, 68, 68, 0.2)' }}>
        ⚠️ Lỗi kết nối Firebase: {error}
        <button onClick={() => window.location.reload()} style={{ marginLeft: 12, color: 'var(--primary-400)', textDecoration: 'underline', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
          Thử lại
        </button>
      </div>
    )
  }

  return null
}

/* ===== Main App ===== */
function App() {
  const [activeNav, setActiveNav] = useState('nav-dashboard')
  const [connectionStatus, setConnectionStatus] = useState('loading') // loading, connected, error
  const [connectionError, setConnectionError] = useState('')
  const [refreshing, setRefreshing] = useState(false)
  const [showDriverModal, setShowDriverModal] = useState(false)
  const [allDrivers, setAllDrivers] = useState(null)

  // Firebase data states
  const [stats, setStats] = useState({
    totalTrips: 0,
    onlineDrivers: 0,
    totalRevenue: 0,
    totalUsers: 0,
    totalDrivers: 0,
    totalCustomers: 0,
  })
  const [trips, setTrips] = useState([])
  const [rideRequests, setRideRequests] = useState([])
  const [onlineDriverCount, setOnlineDriverCount] = useState(0)

  // Load stats from Firestore
  const loadStats = useCallback(async () => {
    try {
      const [totalTripsCount, onlineDrivers, revenue, totalUsers, totalDrivers, totalCustomers] =
        await Promise.all([
          countTrips(),
          countOnlineDrivers(),
          getTotalRevenue(),
          countUsers(),
          countUsers('driver'),
          countUsers('customer'),
        ])

      setStats({
        totalTrips: totalTripsCount,
        onlineDrivers,
        totalRevenue: revenue,
        totalUsers,
        totalDrivers,
        totalCustomers,
      })
      setOnlineDriverCount(onlineDrivers)
      setConnectionStatus('connected')
    } catch (error) {
      console.error('Error loading stats:', error)
      setConnectionStatus('error')
      setConnectionError(error.message)
    }
  }, [])

  // Load trips one time
  const loadTrips = useCallback(async () => {
    try {
      const recentTrips = await getRecentTrips(20)
      setTrips(recentTrips)
    } catch (error) {
      console.error('Error loading trips:', error)
    }
  }, [])

  // Load ride requests one time
  const loadRideRequests = useCallback(async () => {
    try {
      const recentRequests = await getRecentRideRequests(20)
      setRideRequests(recentRequests)
    } catch (error) {
      console.error('Error loading ride requests:', error)
    }
  }, [])

  // Refresh all data
  // Open driver modal and fetch driver list
  const handleOpenDrivers = useCallback(async () => {
    setShowDriverModal(true)
    try {
      const drivers = await getUsers('driver', 100)
      setAllDrivers(drivers)
    } catch (error) {
      console.error('Error loading drivers:', error)
      setAllDrivers([])
    }
  }, [])

  const handleRefresh = useCallback(async () => {
    setRefreshing(true)
    await Promise.all([loadStats(), loadTrips(), loadRideRequests()])
    setTimeout(() => setRefreshing(false), 600)
  }, [loadStats, loadTrips, loadRideRequests])

  // Initial load + realtime listeners
  useEffect(() => {
    loadStats()
    loadTrips()
    loadRideRequests()

    // Realtime listeners
    const unsubTrips = onRecentTrips((newTrips) => {
      setTrips(newTrips)
    }, 20)

    const unsubRequests = onRecentRideRequests((newRequests) => {
      setRideRequests(newRequests)
    }, 20)

    const unsubDrivers = onOnlineDrivers((drivers) => {
      setOnlineDriverCount(drivers.length)
      setStats(prev => ({ ...prev, onlineDrivers: drivers.length }))
    })

    return () => {
      unsubTrips()
      unsubRequests()
      unsubDrivers()
    }
  }, [loadStats, loadTrips, loadRideRequests])

  // Build stats cards from real data
  const statsCards = [
    {
      id: 'total-rides',
      label: 'Tổng chuyến đi',
      value: formatNumber(stats.totalTrips),
      subtitle: `${stats.totalDrivers} tài xế`,
      type: 'primary',
      icon: '🚗',
    },
    {
      id: 'active-drivers',
      label: 'Tài xế online',
      value: formatNumber(stats.onlineDrivers),
      subtitle: `/ ${stats.totalDrivers} tổng`,
      type: 'success',
      icon: '👨‍✈️',
    },
    {
      id: 'total-revenue',
      label: 'Doanh thu (VNĐ)',
      value: formatCurrency(stats.totalRevenue),
      subtitle: 'Hoàn thành',
      type: 'warning',
      icon: '💰',
    },
    {
      id: 'total-users',
      label: 'Người dùng',
      value: formatNumber(stats.totalUsers),
      subtitle: `${stats.totalCustomers} khách`,
      type: 'info',
      icon: '👥',
    },
  ]

  return (
    <div className="app">
      <Sidebar activeNav={activeNav} onNavClick={setActiveNav} onlineDriverCount={onlineDriverCount} />

      <main className="main">
        <ConnectionBanner status={connectionStatus} error={connectionError} />
        <Header isLive={connectionStatus === 'connected'} onRefresh={handleRefresh} loading={refreshing} />

        {activeNav === 'nav-rides' ? (
          /* ===== Rides Management Page ===== */
          <RidesPage />
        ) : activeNav === 'nav-drivers' ? (
          /* ===== Drivers Management Page ===== */
          <DriversPage />
        ) : (
          /* ===== Dashboard Page ===== */
          <section className="dashboard">
            {/* Stats Grid */}
            <div className="stats-grid" id="stats-grid">
              {connectionStatus === 'loading'
                ? [1, 2, 3, 4].map(i => <StatSkeleton key={i} />)
                : statsCards.map(stat => (
                  <StatCard
                    key={stat.id}
                    data={stat}
                    onClick={stat.id === 'active-drivers' ? handleOpenDrivers : undefined}
                  />
                ))
              }
            </div>

            {/* Chart + Activity */}
            <div className="content-grid">
              <ChartSection trips={trips} />
              <ActivityFeed rideRequests={rideRequests} />
            </div>

            {/* Recent Trips Table */}
            <RecentTrips trips={trips} />
          </section>
        )}
      </main>

      {/* Driver Modal */}
      {showDriverModal && (
        <DriverModal
          drivers={allDrivers}
          onClose={() => { setShowDriverModal(false); setAllDrivers(null); }}
        />
      )}
    </div>
  )
}

export default App
