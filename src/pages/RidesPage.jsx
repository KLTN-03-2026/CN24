import { useState, useEffect, useMemo, useCallback } from 'react'
import { onAllTrips, deleteTrip, countTrips, getTotalRevenue } from '../firestoreService'
import { formatCurrency, formatFare, timeAgo, getInitials, statusMap } from '../utils/helpers'
import Icons from '../components/Icons'

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

  const formatDateFull = (timestamp) => {
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
            {Icons.close}
          </button>
        </div>
        <div className="modal__body">
          <div className="trip-detail">
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
            <div className="trip-detail__row">
              <span className="trip-detail__label">👤 Khách hàng</span>
              <span className="trip-detail__value">{trip.customerName || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">🚘 Tài xế</span>
              <span className="trip-detail__value">{trip.driverName || '—'}</span>
            </div>
            <div className="trip-detail__divider" />
            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">📍 Điểm đón</span>
              <span className="trip-detail__value trip-detail__address">{trip.pickupAddress || '—'}</span>
            </div>
            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">📍 Điểm đến</span>
              <span className="trip-detail__value trip-detail__address">{trip.destinationAddress || '—'}</span>
            </div>
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">💰 Giá tiền</span>
              <span className="trip-detail__value trip-detail__fare">{trip.fare ? formatFare(trip.fare) : '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">💳 Thanh toán</span>
              <span className="trip-detail__value">{trip.paymentMethod || 'Tiền mặt'}</span>
            </div>
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Tạo lúc</span>
              <span className="trip-detail__value">{formatDateFull(trip.createdAt)}</span>
            </div>
          </div>
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

function RidesPage() {
  const [allTrips, setAllTrips] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedTrip, setSelectedTrip] = useState(null)
  const [deletingTrip, setDeletingTrip] = useState(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [toast, setToast] = useState(null)
  const [serverStats, setServerStats] = useState({
    total: 0, completed: 0, active: 0, cancelled: 0, revenue: 0,
  })

  const statusTabs = [
    { key: 'all', label: 'Tất cả' },
    { key: 'completed', label: 'Hoàn thành' },
    { key: 'on_the_way', label: 'Đang đi' },
    { key: 'accepted', label: 'Đã nhận' },
    { key: 'cancelled', label: 'Đã hủy' },
    { key: 'pending', label: 'Chờ xử lý' },
  ]

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

  useEffect(() => {
    loadServerStats()
  }, [loadServerStats, allTrips])

  useEffect(() => {
    setLoading(true)
    const unsub = onAllTrips((trips) => {
      setAllTrips(trips)
      setLoading(false)
    }, statusFilter === 'all' ? null : statusFilter, 200)

    return () => unsub()
  }, [statusFilter])

  const showToast = useCallback((message, type = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3000)
  }, [])

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

  const handleDeleteTrip = useCallback(async () => {
    if (!deletingTrip) return
    setIsDeleting(true)
    const result = await deleteTrip(deletingTrip.id)
    setIsDeleting(false)
    if (result.success) {
      showToast(`Đã xóa chuyến đi thành công!`, 'success')
      setDeletingTrip(null)
      setSelectedTrip(null)
    } else {
      showToast(`Lỗi: ${result.error}`, 'error')
    }
  }, [deletingTrip, showToast])

  return (
    <section className="rides-page" id="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">Quản lý chuyến đi</h2>
          <p className="rides-page__subtitle">Theo dõi và quản lý tất cả chuyến đi trong hệ thống</p>
        </div>
      </div>

      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{serverStats.total}</span>
          <span className="rides-stat__label">Tổng chuyến</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{serverStats.completed}</span>
          <span className="rides-stat__label">Hoàn thành</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <span className="rides-stat__number">{serverStats.active}</span>
          <span className="rides-stat__label">Đang hoạt động</span>
        </div>
        <div className="rides-stat rides-stat--revenue">
          <span className="rides-stat__number">{formatCurrency(serverStats.revenue)}</span>
          <span className="rides-stat__label">Doanh thu</span>
        </div>
      </div>

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

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách chuyến đi...</p>
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
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredTrips.map((trip) => {
                  const st = statusMap[trip.status] || { label: trip.status || '—', css: 'active' }
                  return (
                    <tr key={trip.id}>
                      <td className="rides-table__id" onClick={() => setSelectedTrip(trip)}>
                        {trip.id?.slice(0, 8).toUpperCase()}
                      </td>
                      <td>{trip.customerName}</td>
                      <td className="font-medium text-surface-100">{trip.driverName || '—'}</td>
                      <td>{trip.pickupAddress}</td>
                      <td>{trip.destinationAddress}</td>
                      <td>{formatFare(trip.fare)}</td>
                      <td>
                        <span className={`table__status table__status--${st.css}`}>
                          <span className="table__status-dot" />
                          {st.label}
                        </span>
                      </td>
                      <td>
                        <div className="rides-table__actions">
                          <button className="rides-table__action-btn" onClick={() => setSelectedTrip(trip)}>👁️</button>
                          <button className="rides-table__action-btn" onClick={() => setDeletingTrip(trip)}>🗑️</button>
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

      {selectedTrip && (
        <TripDetailModal
          trip={selectedTrip}
          onClose={() => setSelectedTrip(null)}
          onDelete={(trip) => { setSelectedTrip(null); setDeletingTrip(trip); }}
        />
      )}

      {deletingTrip && (
        <ConfirmDeleteModal
          trip={deletingTrip}
          onConfirm={handleDeleteTrip}
          onCancel={() => setDeletingTrip(null)}
          deleting={isDeleting}
        />
      )}

      {toast && (
        <div className={`rides-toast rides-toast--${toast.type}`}>
          {toast.message}
        </div>
      )}
    </section>
  )
}

export default RidesPage
