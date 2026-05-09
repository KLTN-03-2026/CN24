import { useState } from 'react'
import { formatCurrency, formatNumber } from '../utils/helpers'
import { formatChartCurrency } from '../utils/analyticsHelpers'
import useRideAnalytics from '../hooks/useRideAnalytics'

function AnalyticsPage() {
  const [timeRange, setTimeRange] = useState('week')
  const { stats, chartData, statusRates, loading, error, refetch } = useRideAnalytics(timeRange)

  // Tìm giá trị max trong chartData để scale chiều cao cột
  const maxChartValue = Math.max(...chartData.map(d => d.value), 1)

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">📊 Phân tích & Báo cáo</h2>
          <p className="rides-page__subtitle">Theo dõi hiệu suất kinh doanh và tăng trưởng</p>
        </div>
        <div className="chart-card__tabs" style={{ background: 'var(--surface-800)', padding: '4px', borderRadius: 'var(--radius-md)' }}>
          {['week', 'month', 'year'].map(tab => (
            <button
              key={tab}
              className={`chart-card__tab ${timeRange === tab ? 'chart-card__tab--active' : ''}`}
              onClick={() => setTimeRange(tab)}
            >
              {tab === 'week' ? 'Tuần này' : tab === 'month' ? 'Tháng này' : 'Năm này'}
            </button>
          ))}
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="analytics-error">
          <span>⚠️ {error}</span>
          <button onClick={refetch} className="analytics-error__retry">Thử lại</button>
        </div>
      )}

      {/* Analytics Cards */}
      <div className="rides-stats">
        <div className={`rides-stat rides-stat--revenue ${loading ? 'analytics-loading' : ''}`}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Tổng doanh thu</span>
            <span
              className="analytics-growth"
              style={{ color: stats.revenueGrowth.isPositive ? 'var(--success-400)' : 'var(--danger-400)' }}
            >
              {stats.revenueGrowth.text} {stats.revenueGrowth.isPositive ? '↑' : '↓'}
            </span>
          </div>
          <span className="rides-stat__number">
            {loading ? '...' : formatCurrency(stats.totalRevenue)}
          </span>
        </div>
        <div className={`rides-stat rides-stat--total ${loading ? 'analytics-loading' : ''}`}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Tổng chuyến đi</span>
            <span
              className="analytics-growth"
              style={{ color: stats.tripsGrowth.isPositive ? 'var(--success-400)' : 'var(--danger-400)' }}
            >
              {stats.tripsGrowth.text} {stats.tripsGrowth.isPositive ? '↑' : '↓'}
            </span>
          </div>
          <span className="rides-stat__number">
            {loading ? '...' : formatNumber(stats.totalTrips)}
          </span>
        </div>
        <div className={`rides-stat rides-stat--active ${loading ? 'analytics-loading' : ''}`}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Người dùng mới</span>
            <span
              className="analytics-growth"
              style={{ color: stats.usersGrowth.isPositive ? 'var(--success-400)' : 'var(--danger-400)' }}
            >
              {stats.usersGrowth.text} {stats.usersGrowth.isPositive ? '↑' : '↓'}
            </span>
          </div>
          <span className="rides-stat__number">
            {loading ? '...' : `+${formatNumber(stats.newUsers)}`}
          </span>
        </div>
      </div>

      <div className="content-grid" style={{ marginTop: '24px' }}>
        {/* Biểu đồ doanh thu chi tiết */}
        <div className="chart-card" style={{ gridColumn: 'span 2' }}>
          <div className="chart-card__header">
            <h3 className="chart-card__title">Biểu đồ doanh thu chi tiết</h3>
            <span style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)' }}>Đơn vị: VNĐ</span>
          </div>

          {loading ? (
            <div className="analytics-chart-loading">
              <div className="analytics-spinner" />
              <span>Đang tải dữ liệu...</span>
            </div>
          ) : chartData.length === 0 ? (
            <div className="analytics-chart-empty">
              <span>📭 Không có dữ liệu trong khoảng thời gian này</span>
            </div>
          ) : (
            <div
              className="mini-chart"
              style={{
                height: '300px',
                alignItems: 'flex-end',
                paddingBottom: '40px',
                overflowX: chartData.length > 15 ? 'auto' : 'visible',
              }}
            >
              {chartData.map((item, idx) => {
                const heightPercent = maxChartValue > 0
                  ? Math.max((item.value / maxChartValue) * 100, item.value > 0 ? 4 : 0)
                  : 0;

                return (
                  <div
                    className="mini-chart__bar-group"
                    key={idx}
                    style={{
                      flex: chartData.length <= 12 ? 1 : '0 0 48px',
                    }}
                  >
                    {/* Tooltip hiển thị số tiền */}
                    {item.value > 0 && (
                      <span className="analytics-bar-tooltip">
                        {formatChartCurrency(item.value)}
                      </span>
                    )}
                    <div
                      className="mini-chart__bar"
                      style={{
                        height: `${heightPercent}%`,
                        background: 'linear-gradient(to top, var(--primary-600), var(--primary-400))',
                        width: '60%',
                        transition: 'height 0.4s ease-out',
                      }}
                    />
                    <span className="mini-chart__label">{item.label}</span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Tỉ lệ trạng thái chuyến đi */}
        <div className="table-card">
          <div className="table-card__header">
            <h3 className="table-card__title">Tỉ lệ trạng thái chuyến đi</h3>
          </div>
          <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {loading ? (
              <div className="analytics-chart-loading" style={{ height: '120px' }}>
                <div className="analytics-spinner" />
              </div>
            ) : (
              <>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: 'var(--font-sm)' }}>Hoàn thành</span>
                    <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>{statusRates.completed}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div
                      style={{
                        width: `${statusRates.completed}%`,
                        height: '100%',
                        background: 'var(--success-500)',
                        transition: 'width 0.5s ease-out',
                      }}
                    />
                  </div>
                </div>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: 'var(--font-sm)' }}>Đã hủy</span>
                    <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>{statusRates.cancelled}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div
                      style={{
                        width: `${statusRates.cancelled}%`,
                        height: '100%',
                        background: 'var(--danger-500)',
                        transition: 'width 0.5s ease-out',
                      }}
                    />
                  </div>
                </div>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <span style={{ fontSize: 'var(--font-sm)' }}>Đang xử lý</span>
                    <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>{statusRates.processing}%</span>
                  </div>
                  <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                    <div
                      style={{
                        width: `${statusRates.processing}%`,
                        height: '100%',
                        background: 'var(--warning-500)',
                        transition: 'width 0.5s ease-out',
                      }}
                    />
                  </div>
                </div>

                {stats.totalTrips === 0 && (
                  <p style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', textAlign: 'center', marginTop: '8px' }}>
                    Chưa có chuyến đi trong khoảng thời gian này
                  </p>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}

export default AnalyticsPage
