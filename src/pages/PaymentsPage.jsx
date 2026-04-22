import { useState, useMemo } from 'react'
import { formatCurrency, formatFare, timeAgo, getInitials } from '../utils/helpers'
import Icons from '../components/Icons'

function PaymentsPage({ trips }) {
  const [searchQuery, setSearchQuery] = useState('')

  // Lọc các chuyến đã hoàn thành để tính doanh thu
  const completedTrips = useMemo(() => trips.filter(t => t.status === 'completed'), [trips])

  const paymentStats = useMemo(() => {
    const cash = completedTrips.filter(t => t.paymentMethod === 'Tiền mặt' || !t.paymentMethod).reduce((sum, t) => sum + (t.fare || 0), 0)
    const digital = completedTrips.filter(t => t.paymentMethod && t.paymentMethod !== 'Tiền mặt').reduce((sum, t) => sum + (t.fare || 0), 0)
    return { cash, digital, total: cash + digital }
  }, [completedTrips])

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">💳 Quản lý Thanh toán</h2>
          <p className="rides-page__subtitle">Theo dõi dòng tiền và lịch sử giao dịch doanh thu</p>
        </div>
      </div>

      <div className="rides-stats">
        <div className="rides-stat rides-stat--revenue">
          <span className="rides-stat__label">Tổng doanh thu thực tế</span>
          <span className="rides-stat__number">{formatCurrency(paymentStats.total)}</span>
        </div>
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__label">Thanh toán Tiền mặt</span>
          <span className="rides-stat__number">{formatCurrency(paymentStats.cash)}</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <span className="rides-stat__label">Thanh toán Điện tử</span>
          <span className="rides-stat__number">{formatCurrency(paymentStats.digital)}</span>
        </div>
      </div>

      <div className="table-card rides-table-card">
        <div className="table-card__header">
          <h3 className="table-card__title">Lịch sử giao dịch gần đây</h3>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table className="table rides-table">
            <thead>
              <tr>
                <th>Mã giao dịch</th>
                <th>Khách hàng</th>
                <th>Phương thức</th>
                <th>Số tiền</th>
                <th>Thời gian</th>
                <th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {completedTrips.slice(0, 15).map(trip => (
                <tr key={trip.id}>
                  <td style={{ color: 'var(--primary-400)', fontWeight: 600 }}>#{trip.id?.slice(-6).toUpperCase()}</td>
                  <td>
                    <div className="table__rider">
                      <div className="table__rider-avatar">{getInitials(trip.customerName)}</div>
                      <span>{trip.customerName}</span>
                    </div>
                  </td>
                  <td>
                    <span style={{ 
                      padding: '4px 8px', 
                      background: 'var(--surface-800)', 
                      borderRadius: '4px', 
                      fontSize: 'var(--font-xs)',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px'
                    }}>
                      {trip.paymentMethod === 'Tiền mặt' ? '💵' : '💳'} {trip.paymentMethod || 'Tiền mặt'}
                    </span>
                  </td>
                  <td style={{ fontWeight: 600, color: 'var(--success-400)' }}>+{formatFare(trip.fare)}</td>
                  <td>{timeAgo(trip.createdAt)}</td>
                  <td>
                    <span className="table__status table__status--completed">Thành công</span>
                  </td>
                </tr>
              ))}
              {completedTrips.length === 0 && (
                <tr>
                  <td colSpan="6" style={{ textAlign: 'center', padding: '40px', color: 'var(--surface-500)' }}>
                    Chưa có lịch sử giao dịch nào được ghi nhận.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}

export default PaymentsPage
