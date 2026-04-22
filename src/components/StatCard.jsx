import Icons from './Icons'

/* ===== Loading Skeleton ===== */
export function StatSkeleton() {
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
export function StatCard({ data, onClick }) {
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
