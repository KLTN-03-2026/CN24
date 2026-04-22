import { useState, useMemo } from 'react'
import { formatCurrency, formatNumber } from '../utils/helpers'
import Icons from '../components/Icons'

function AnalyticsPage({ stats, trips }) {
  const [timeRange, setTimeRange] = useState('week')

  // Tính toán dữ liệu tăng trưởng (Giả lập dựa trên trips thật)
  const growthData = useMemo(() => {
    // Trong thực tế sẽ tính toán dựa trên dữ liệu lịch sử từ Firestore
    return {
      revenue: "+12.5%",
      trips: "+8.2%",
      users: "+5.4%"
    }
  }, [])

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

      {/* Analytics Cards */}
      <div className="rides-stats">
        <div className="rides-stat rides-stat--revenue">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Tổng doanh thu</span>
            <span style={{ color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>{growthData.revenue} ↑</span>
          </div>
          <span className="rides-stat__number">{formatCurrency(stats.totalRevenue)}</span>
        </div>
        <div className="rides-stat rides-stat--total">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Tổng chuyến đi</span>
            <span style={{ color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>{growthData.trips} ↑</span>
          </div>
          <span className="rides-stat__number">{formatNumber(stats.totalTrips)}</span>
        </div>
        <div className="rides-stat rides-stat--active">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="rides-stat__label">Người dùng mới</span>
            <span style={{ color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>{growthData.users} ↑</span>
          </div>
          <span className="rides-stat__number">+{formatNumber(Math.floor(stats.totalUsers * 0.1))}</span>
        </div>
      </div>

      <div className="content-grid" style={{ marginTop: '24px' }}>
        {/* Biểu đồ doanh thu chi tiết */}
        <div className="chart-card" style={{ gridColumn: 'span 2' }}>
          <div className="chart-card__header">
            <h3 className="chart-card__title">Biểu đồ doanh thu chi tiết</h3>
            <span style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)' }}>Đơn vị: VNĐ</span>
          </div>
          <div className="mini-chart" style={{ height: '300px', alignItems: 'flex-end', paddingBottom: '40px' }}>
            {/* Giả lập các cột doanh thu */}
            {[40, 65, 55, 85, 95, 75, 80].map((height, idx) => (
              <div className="mini-chart__bar-group" key={idx} style={{ flex: 1 }}>
                <div 
                  className="mini-chart__bar" 
                  style={{ 
                    height: `${height}%`, 
                    background: 'linear-gradient(to top, var(--primary-600), var(--primary-400))',
                    width: '60%'
                  }} 
                />
                <span className="mini-chart__label">{['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Top Drivers/Customers Statistics */}
        <div className="table-card">
          <div className="table-card__header">
            <h3 className="table-card__title">Tỉ lệ trạng thái chuyến đi</h3>
          </div>
          <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: 'var(--font-sm)' }}>Hoàn thành</span>
                <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>75%</span>
              </div>
              <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '75%', height: '100%', background: 'var(--success-500)' }} />
              </div>
            </div>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: 'var(--font-sm)' }}>Đã hủy</span>
                <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>15%</span>
              </div>
              <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '15%', height: '100%', background: 'var(--danger-500)' }} />
              </div>
            </div>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: 'var(--font-sm)' }}>Khác</span>
                <span style={{ fontSize: 'var(--font-sm)', fontWeight: 600 }}>10%</span>
              </div>
              <div style={{ height: '8px', background: 'var(--surface-800)', borderRadius: '4px', overflow: 'hidden' }}>
                <div style={{ width: '10%', height: '100%', background: 'var(--warning-500)' }} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default AnalyticsPage
