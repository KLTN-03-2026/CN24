import { useState, useEffect, useMemo, useCallback } from 'react'
import { onAllUsers, updateUserStatus } from '../firestoreService'
import { getInitials, formatDateShort } from '../utils/helpers'
import Icons from '../components/Icons'

function AccountDetailModal({ user, onClose, onUpdateStatus }) {
  if (!user) return null

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal driver-detail-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal__header">
          <h2 className="modal__title">🛡️ Chi tiết tài khoản</h2>
          <button className="modal__close" onClick={onClose}>
            {Icons.close}
          </button>
        </div>
        <div className="modal__body">
          <div className="driver-detail__profile">
            <div className="driver-detail__avatar">
              {getInitials(user.name)}
            </div>
            <div className="driver-detail__name-block">
              <h3 className="driver-detail__name">{user.name || '—'}</h3>
              <span className={`driver-detail__status-badge ${user.role === 'driver' ? 'driver-detail__status-badge--online' : 'driver-detail__status-badge--offline'}`} style={{ 
                background: user.role === 'driver' ? 'var(--primary-600)' : user.role === 'customer' ? 'var(--success-600)' : 'var(--warning-600)' 
              }}>
                {user.role === 'driver' ? 'Tài xế' : user.role === 'customer' ? 'Khách hàng' : 'Quản trị viên'}
              </span>
            </div>
          </div>

          <div className="trip-detail">
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">📧 Email</span>
              <span className="trip-detail__value">{user.email || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">📱 Số điện thoại</span>
              <span className="trip-detail__value">{user.phone || '—'}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">Trạng thái</span>
              <span className={`table__status ${user.isBlocked ? 'table__status--cancelled' : 'table__status--completed'}`}>
                {user.isBlocked ? '🚫 Đã khóa' : '✅ Đang hoạt động'}
              </span>
            </div>
            <div className="trip-detail__divider" />
            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Ngày tham gia</span>
              <span className="trip-detail__value">{formatDateShort(user.createdAt)}</span>
            </div>
            <div className="trip-detail__row">
              <span className="trip-detail__label">🆔 User ID</span>
              <span className="trip-detail__value" style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)' }}>{user.id}</span>
            </div>
          </div>

          <div className="modal__footer" style={{ marginTop: '24px', display: 'flex', gap: '12px' }}>
            <button 
              className={`confirm-modal__btn ${user.isBlocked ? 'confirm-modal__btn--cancel' : 'confirm-modal__btn--delete'}`}
              style={{ flex: 1, padding: '12px' }}
              onClick={() => onUpdateStatus(user.id, !user.isBlocked)}
            >
              {user.isBlocked ? '🔓 Mở khóa tài khoản' : '🚫 Khóa tài khoản'}
            </button>
            <button className="confirm-modal__btn confirm-modal__btn--cancel" style={{ flex: 1, padding: '12px' }} onClick={onClose}>
              Đóng
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function AccountsPage() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [roleFilter, setRoleFilter] = useState('all')
  const [selectedUser, setSelectedUser] = useState(null)
  const [toast, setToast] = useState(null)

  useEffect(() => {
    setLoading(true)
    const unsub = onAllUsers((userList) => {
      setUsers(userList)
      setLoading(false)
    })
    return () => unsub()
  }, [])

  const handleUpdateStatus = async (userId, isBlocked) => {
    const result = await updateUserStatus(userId, isBlocked)
    if (result.success) {
      setToast({ message: `Đã ${isBlocked ? 'khóa' : 'mở khóa'} tài khoản thành công!`, type: 'success' })
      if (selectedUser?.id === userId) {
        setSelectedUser(prev => ({ ...prev, isBlocked }))
      }
    } else {
      setToast({ message: `Lỗi: ${result.error}`, type: 'error' })
    }
    setTimeout(() => setToast(null), 3000)
  }

  const filteredUsers = useMemo(() => {
    let result = users
    if (roleFilter !== 'all') {
      result = result.filter(u => u.role === roleFilter)
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase()
      result = result.filter(u => 
        u.name?.toLowerCase().includes(q) || 
        u.email?.toLowerCase().includes(q) || 
        u.phone?.includes(q)
      )
    }
    return result
  }, [users, roleFilter, searchQuery])

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🛡️ Quản lý tài khoản</h2>
          <p className="rides-page__subtitle">Quản lý tất cả người dùng và phân quyền hệ thống</p>
        </div>
      </div>

      <div className="rides-stats" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))' }}>
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{users.length}</span>
          <span className="rides-stat__label">Tổng tài khoản</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{users.filter(u => u.role === 'driver').length}</span>
          <span className="rides-stat__label">Tài xế</span>
        </div>
        <div className="rides-stat rides-stat--active" style={{ borderColor: 'var(--success-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--success-400)' }}>{users.filter(u => u.role === 'customer').length}</span>
          <span className="rides-stat__label">Khách hàng</span>
        </div>
        <div className="rides-stat rides-stat--revenue" style={{ borderColor: 'var(--danger-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--danger-400)' }}>{users.filter(u => u.isBlocked).length}</span>
          <span className="rides-stat__label">Đã khóa</span>
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
        <div className="rides-toolbar__filters">
          <button 
            className={`rides-toolbar__filter-btn ${roleFilter === 'all' ? 'rides-toolbar__filter-btn--active' : ''}`}
            onClick={() => setRoleFilter('all')}
          >Tất cả</button>
          <button 
            className={`rides-toolbar__filter-btn ${roleFilter === 'driver' ? 'rides-toolbar__filter-btn--active' : ''}`}
            onClick={() => setRoleFilter('driver')}
          >Tài xế</button>
          <button 
            className={`rides-toolbar__filter-btn ${roleFilter === 'customer' ? 'rides-toolbar__filter-btn--active' : ''}`}
            onClick={() => setRoleFilter('customer')}
          >Khách hàng</button>
          <button 
            className={`rides-toolbar__filter-btn ${roleFilter === 'admin' ? 'rides-toolbar__filter-btn--active' : ''}`}
            onClick={() => setRoleFilter('admin')}
          >Admin</button>
        </div>
      </div>

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách tài khoản...</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Người dùng</th>
                  <th>Vai trò</th>
                  <th>Liên hệ</th>
                  <th>Ngày tham gia</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map(user => (
                  <tr key={user.id}>
                    <td>
                      <div className="table__rider">
                        <div className="table__rider-avatar">{getInitials(user.name)}</div>
                        <span>{user.name || 'N/A'}</span>
                      </div>
                    </td>
                    <td>
                      <span className={`badge ${user.role}`} style={{ 
                        padding: '4px 8px', 
                        borderRadius: '4px', 
                        fontSize: '10px',
                        background: user.role === 'driver' ? 'var(--primary-900)' : user.role === 'customer' ? 'var(--success-900)' : 'var(--warning-900)',
                        color: user.role === 'driver' ? 'var(--primary-200)' : user.role === 'customer' ? 'var(--success-200)' : 'var(--warning-200)'
                      }}>
                        {user.role === 'driver' ? 'Tài xế' : user.role === 'customer' ? 'Khách hàng' : 'Admin'}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontSize: 'var(--font-xs)' }}>
                        <div>{user.email}</div>
                        <div style={{ color: 'var(--surface-500)' }}>{user.phone || '—'}</div>
                      </div>
                    </td>
                    <td>{formatDateShort(user.createdAt)}</td>
                    <td>
                      <span className={`table__status ${user.isBlocked ? 'table__status--cancelled' : 'table__status--completed'}`}>
                        {user.isBlocked ? 'Đã khóa' : 'Hoạt động'}
                      </span>
                    </td>
                    <td>
                      <div className="rides-table__actions">
                        <button className="rides-table__action-btn" onClick={() => setSelectedUser(user)} title="Xem chi tiết">👁️</button>
                        <button 
                          className={`rides-table__action-btn ${user.isBlocked ? 'text-success-500' : 'text-danger-500'}`} 
                          onClick={() => handleUpdateStatus(user.id, !user.isBlocked)}
                          title={user.isBlocked ? "Mở khóa" : "Khóa tài khoản"}
                        >
                          {user.isBlocked ? '🔓' : '🚫'}
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

      {selectedUser && (
        <AccountDetailModal 
          user={selectedUser} 
          onClose={() => setSelectedUser(null)} 
          onUpdateStatus={handleUpdateStatus}
        />
      )}

      {toast && (
        <div className={`rides-toast rides-toast--${toast.type}`} style={{ zIndex: 1000 }}>
          {toast.type === 'success' ? '✅' : '❌'} {toast.message}
        </div>
      )}
    </section>
  )
}

export default AccountsPage
