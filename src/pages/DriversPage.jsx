import { useState, useEffect, useMemo, useCallback } from 'react'
import { onAllDrivers, syncDriverStats, onDriverReviews } from '../firestoreService'
import { formatCurrency, formatFare, getInitials, formatDateShort, timeAgo } from '../utils/helpers'
import Icons from '../components/Icons'

function DriverDetailModal({ driver, onClose }) {
  if (!driver) return null
  const [reviews, setReviews] = useState([])
  const [loadingReviews, setLoadingReviews] = useState(true)

  useEffect(() => {
    setLoadingReviews(true)
    const unsub = onDriverReviews(driver.id, (data) => {
      setReviews(data)
      setLoadingReviews(false)
    })
    return () => unsub()
  }, [driver.id])

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal driver-detail-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '650px' }}>
        <div className="modal__header">
          <h2 className="modal__title">👨‍✈️ Thông tin tài xế</h2>
          <button className="modal__close" onClick={onClose}>
            {Icons.close}
          </button>
        </div>
        <div className="modal__body" style={{ maxHeight: '85vh', overflowY: 'auto' }}>
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
              <span className="driver-detail__stat-value">{formatFare(driver.earnings || 0)}</span>
              <span className="driver-detail__stat-label">Thu nhập</span>
            </div>
          </div>

          <div className="trip-detail">
            <div className="trip-detail__divider" />
            <div className="grid grid-cols-2 gap-4">
              <div className="trip-detail__row">
                <span className="trip-detail__label">📧 Email</span>
                <span className="trip-detail__value text-sm">{driver.email || '—'}</span>
              </div>
              <div className="trip-detail__row">
                <span className="trip-detail__label">📱 Số điện thoại</span>
                <span className="trip-detail__value">{driver.phone || '—'}</span>
              </div>
              <div className="trip-detail__row">
                <span className="trip-detail__label">🏍️ Loại xe</span>
                <span className="trip-detail__value">{driver.vehicleType || '—'}</span>
              </div>
              <div className="trip-detail__row">
                <span className="trip-detail__label">🆔 Biển số</span>
                <span className="trip-detail__value">{driver.vehiclePlate || '—'}</span>
              </div>
            </div>
            <div className="trip-detail__divider" />
            
            <h4 className="font-bold text-sm mb-4 flex items-center gap-2">
              ⭐ Đánh giá gần đây ({reviews.length})
            </h4>

            {loadingReviews ? (
              <div className="py-8 text-center opacity-50">Đang tải đánh giá...</div>
            ) : reviews.length === 0 ? (
              <div className="py-8 text-center opacity-50 text-sm">Chưa có đánh giá nào.</div>
            ) : (
              <div className="driver-reviews-list flex flex-col gap-3">
                {reviews.map(review => (
                  <div key={review.id} className="driver-review-item bg-surface-800/40 p-3 rounded-lg border border-surface-700/50">
                    <div className="flex justify-between items-start mb-1">
                      <span className="font-bold text-xs text-surface-100">{review.customerName}</span>
                      <span className="text-[10px] opacity-50">{timeAgo(review.createdAt)}</span>
                    </div>
                    <div className="flex text-warning-400 mb-2" style={{ fontSize: '10px' }}>
                      {Array.from({ length: 5 }).map((_, i) => (
                        <span key={i}>{i < review.rating ? '★' : '☆'}</span>
                      ))}
                    </div>
                    <p className="text-xs text-surface-200 leading-relaxed italic">
                      {review.comment ? `"${review.comment}"` : 'Không có nhận xét.'}
                    </p>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
      <style dangerouslySetInnerHTML={{ __html: `
        .grid { display: grid; }
        .grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        .gap-4 { gap: 1rem; }
        .mb-4 { margin-bottom: 1rem; }
        .mb-2 { margin-bottom: 0.5rem; }
        .mb-1 { margin-bottom: 0.25rem; }
        .p-3 { padding: 0.75rem; }
        .rounded-lg { border-radius: 0.5rem; }
      `}} />
    </div>
  )
}

function DriversPage() {
  const [drivers, setDrivers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedDriver, setSelectedDriver] = useState(null)
  const [syncLoading, setSyncLoading] = useState(false)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    setLoading(true)
    const unsub = onAllDrivers((driverList) => {
      setDrivers(driverList)
      setLoading(false)
    })
    return () => unsub()
  }, [])

  const handleSync = useCallback(async () => {
    setSyncLoading(true)
    const result = await syncDriverStats()
    setSyncLoading(false)
    if (result.success) {
      setToast({ message: `Đã cập nhật dữ liệu cho ${result.updatedCount} tài xế!`, type: 'success' })
    } else {
      setToast({ message: `Lỗi: ${result.error}`, type: 'error' })
    }
    setTimeout(() => setToast(null), 3000)
  }, [])

  const filteredDrivers = useMemo(() => {
    let result = drivers
    if (statusFilter === 'online') result = result.filter(d => d.isOnline)
    if (statusFilter === 'offline') result = result.filter(d => !d.isOnline)
    
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter(d => 
        d.name?.toLowerCase().includes(q) || 
        d.email?.toLowerCase().includes(q) || 
        d.phone?.includes(q)
      )
    }
    return result
  }, [drivers, statusFilter, searchQuery])

  const stats = useMemo(() => ({
    total: drivers.length,
    online: drivers.filter(d => d.isOnline).length,
    revenue: drivers.reduce((sum, d) => sum + (d.earnings || 0), 0)
  }), [drivers])

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">Quản lý tài xế</h2>
          <p className="rides-page__subtitle">Quản lý danh sách đối tác tài xế</p>
        </div>
      </div>

      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{stats.total}</span>
          <span className="rides-stat__label">Tổng tài xế</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{stats.online}</span>
          <span className="rides-stat__label">Đang online</span>
        </div>
        <div className="rides-stat rides-stat--revenue">
          <span className="rides-stat__number">{formatCurrency(stats.revenue)}</span>
          <span className="rides-stat__label">Tổng thu nhập</span>
        </div>
      </div>

      <div className="rides-toolbar">
        <div className="rides-toolbar__search">
          <span className="rides-toolbar__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="rides-toolbar__search-input"
            placeholder="Tìm theo tên, email, SĐT..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <button 
          className="confirm-modal__btn confirm-modal__btn--delete" 
          style={{ background: 'var(--primary-600)', minWidth: '160px' }}
          onClick={handleSync}
          disabled={syncLoading}
        >
          {syncLoading ? '⏳ Đang tính toán...' : '🔄 Cập nhật số chuyến'}
        </button>
      </div>

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách tài xế...</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Tài xế</th>
                  <th>Liên hệ</th>
                  <th>Phương tiện</th>
                  <th>Đánh giá</th>
                  <th>Chuyến đi</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredDrivers.map(driver => (
                  <tr key={driver.id}>
                    <td>
                      <div className="table__rider">
                        <div className="table__rider-avatar">{getInitials(driver.name)}</div>
                        <span>{driver.name}</span>
                      </div>
                    </td>
                    <td>
                      <div style={{ fontSize: 'var(--font-xs)' }}>
                        <div>{driver.email}</div>
                        <div style={{ color: 'var(--surface-500)' }}>{driver.phone}</div>
                      </div>
                    </td>
                    <td>{driver.vehicleType}</td>
                    <td>⭐ {driver.rating?.toFixed(1) || '0.0'}</td>
                    <td>{driver.totalTrips || 0}</td>
                    <td>
                      <span className={`table__status ${driver.isOnline ? 'table__status--completed' : 'table__status--cancelled'}`}>
                        {driver.isOnline ? 'Online' : 'Offline'}
                      </span>
                    </td>
                    <td>
                      <button className="rides-table__action-btn" onClick={() => setSelectedDriver(driver)}>👁️</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedDriver && (
        <DriverDetailModal driver={selectedDriver} onClose={() => setSelectedDriver(null)} />
      )}

      {toast && (
        <div className={`rides-toast rides-toast--${toast.type}`} style={{ zIndex: 1000 }}>
          {toast.type === 'success' ? '✅' : '❌'} {toast.message}
        </div>
      )}
    </section>
  )
}

export default DriversPage
