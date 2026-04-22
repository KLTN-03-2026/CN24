import { useState } from 'react'

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
      if (!isNaN(date.getTime())) {
        const dayIndex = (date.getDay() + 6) % 7 // Monday = 0
        dayCounts[dayIndex]++
      }
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

export default ChartSection
