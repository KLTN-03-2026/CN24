import { getInitials, formatFare } from '../utils/helpers'

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

export default DriverModal
