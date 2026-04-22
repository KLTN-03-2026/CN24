import Icons from './Icons'
import { statusMap, formatFare, timeAgo } from '../utils/helpers'

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

export default ActivityFeed
