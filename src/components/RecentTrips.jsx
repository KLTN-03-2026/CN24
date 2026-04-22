import { getInitials, formatFare, timeAgo, statusMap } from '../utils/helpers'

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

export default RecentTrips
