import { useState, useEffect, useMemo } from 'react'
import { onAllCustomers } from '../firestoreService'
import { getInitials, formatDateShort } from '../utils/helpers'
import Icons from '../components/Icons'

function CustomerDetailModal({ customer, onClose }) {
  if (!customer) return null

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal driver-detail-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">👤 Thông tin khách hàng</h2>
          <button className="modal__close" onClick={onClose}>
            {Icons.close}
          </button>
        </div>
        <div className="modal__body">
          <div className="driver-detail__profile">
            <div className="driver-detail__avatar">
              {getInitials(customer.name)}
            </div>
            <div className="driver-detail__name-block">
              <h3 className="driver-detail__name">{customer.name || '—'}</h3>
              <span className="driver-detail__status-badge driver-detail__status-badge--online">
                Khách hàng thân thiết
              </span>
            </div>
          </div>

          <div className="driver-detail__stats-row">
            <div className="driver-detail__stat">
              <span className="driver-detail__stat-value">🚗 {customer.totalTrips || 0}</span>
              <span className="driver-detail__stat-label">Chuyến đã đi</span>
            </div>
            <div className="driver-detail__stat">
              <span className="driver-detail__stat-value">⭐ {(customer.rating || 0).toFixed(1)}</span>
              <span className="driver-detail__stat-label">Đánh giá</span>
            </div>
          </div>

          <div className="trip-detail">
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">📧 Email</span>
              <span className="trip-detail__value">{customer.email || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">📱 Số điện thoại</span>
              <span className="trip-detail__value">{customer.phone || '—'}</span>
            </div>
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Ngày tham gia</span>
              <span className="trip-detail__value">{formatDateShort(customer.createdAt)}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">🆔 User ID</span>
              <span className="trip-detail__value" style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)' }}>{customer.id}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function CustomersPage() {
  const [customers, setCustomers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCustomer, setSelectedCustomer] = useState(null)

  useEffect(() => {
    setLoading(true)
    const unsub = onAllCustomers((customerList) => {
      setCustomers(customerList)
      setLoading(false)
    })
    return () => unsub()
  }, [])

  const filteredCustomers = useMemo(() => {
    if (!searchQuery.trim()) return customers
    const q = searchQuery.toLowerCase()
    return customers.filter(c => 
      c.name?.toLowerCase().includes(q) || 
      c.email?.toLowerCase().includes(q) || 
      c.phone?.includes(q)
    )
  }, [customers, searchQuery])

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">👥 Quản lý khách hàng</h2>
          <p className="rides-page__subtitle">Danh sách tất cả người dùng trong hệ thống</p>
        </div>
      </div>

      <div className="rides-stats" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}>
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{customers.length}</span>
          <span className="rides-stat__label">Tổng khách hàng</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <span className="rides-stat__number">{customers.filter(c => c.totalTrips > 0).length}</span>
          <span className="rides-stat__label">Khách đã từng đi</span>
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
      </div>

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách khách hàng...</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Khách hàng</th>
                  <th>Email</th>
                  <th>Số điện thoại</th>
                  <th>Chuyến đi</th>
                  <th>Ngày tham gia</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredCustomers.map(customer => (
                  <tr key={customer.id}>
                    <td>
                      <div className="table__rider">
                        <div className="table__rider-avatar">{getInitials(customer.name)}</div>
                        <span>{customer.name || 'N/A'}</span>
                      </div>
                    </td>
                    <td>{customer.email}</td>
                    <td>{customer.phone || '—'}</td>
                    <td>{customer.totalTrips || 0}</td>
                    <td>{formatDateShort(customer.createdAt)}</td>
                    <td>
                      <button className="rides-table__action-btn" onClick={() => setSelectedCustomer(customer)}>👁️</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedCustomer && (
        <CustomerDetailModal customer={selectedCustomer} onClose={() => setSelectedCustomer(null)} />
      )}
    </section>
  )
}

export default CustomersPage
