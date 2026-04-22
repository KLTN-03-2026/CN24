import { useState, useEffect } from 'react'
import Icons from '../components/Icons'

function MapPage() {
  const [onlineDrivers, setOnlineDrivers] = useState([])

  // Mô phỏng vị trí tài xế (ngẫu nhiên)
  useEffect(() => {
    const mockDrivers = [
      { id: 1, name: 'Tài xế A', x: 25, y: 30, status: 'busy' },
      { id: 2, name: 'Tài xế B', x: 60, y: 45, status: 'available' },
      { id: 3, name: 'Tài xế C', x: 40, y: 70, status: 'available' },
      { id: 4, name: 'Tài xế D', x: 80, y: 20, status: 'busy' },
      { id: 5, name: 'Tài xế E', x: 15, y: 80, status: 'available' },
    ]
    setOnlineDrivers(mockDrivers)

    // Tạo hiệu ứng di chuyển nhẹ
    const interval = setInterval(() => {
      setOnlineDrivers(prev => prev.map(d => ({
        ...d,
        x: Math.min(Math.max(d.x + (Math.random() - 0.5) * 2, 5), 95),
        y: Math.min(Math.max(d.y + (Math.random() - 0.5) * 2, 5), 95)
      })))
    }, 3000)

    return () => clearInterval(interval)
  }, [])

  return (
    <section className="rides-page" style={{ height: 'calc(100vh - 140px)', display: 'flex', flexDirection: 'column' }}>
      <div className="rides-page__header" style={{ marginBottom: '16px' }}>
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🗺️ Bản đồ trực tuyến</h2>
          <p className="rides-page__subtitle">Theo dõi vị trí tài xế và chuyến đi theo thời gian thực</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: 'var(--font-xs)', color: 'var(--surface-400)' }}>
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--success-500)' }} /> Sẵn sàng
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: 'var(--font-xs)', color: 'var(--surface-400)' }}>
            <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--warning-500)' }} /> Đang bận
          </div>
        </div>
      </div>

      <div style={{ 
        flex: 1, 
        background: 'var(--surface-900)', 
        borderRadius: 'var(--radius-lg)', 
        position: 'relative',
        overflow: 'hidden',
        border: '1px solid var(--surface-800)',
        boxShadow: 'inset 0 0 40px rgba(0,0,0,0.5)'
      }}>
        {/* Giả lập lưới bản đồ */}
        <div style={{ 
          position: 'absolute', 
          inset: 0, 
          backgroundImage: 'radial-gradient(var(--surface-800) 1px, transparent 1px)', 
          backgroundSize: '40px 40px',
          opacity: 0.3
        }} />

        {/* Mock Map Streets (Simple SVG lines) */}
        <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.1 }}>
          <path d="M0 100 L1000 100 M200 0 L200 1000 M0 400 L1000 600 M600 0 L400 1000" stroke="white" strokeWidth="2" fill="none" />
        </svg>

        {/* Drivers Markers */}
        {onlineDrivers.map(driver => (
          <div 
            key={driver.id}
            style={{
              position: 'absolute',
              left: `${driver.x}%`,
              top: `${driver.y}%`,
              transform: 'translate(-50%, -50%)',
              transition: 'all 3s linear',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              cursor: 'pointer',
              zIndex: 10
            }}
          >
            <div style={{ 
              fontSize: '10px', 
              background: 'rgba(0,0,0,0.7)', 
              padding: '2px 6px', 
              borderRadius: '10px',
              marginBottom: '4px',
              whiteSpace: 'nowrap',
              border: '1px solid var(--surface-700)'
            }}>
              {driver.name}
            </div>
            <div style={{
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              background: driver.status === 'available' ? 'var(--success-500)' : 'var(--warning-500)',
              boxShadow: `0 0 15px ${driver.status === 'available' ? 'var(--success-500)' : 'var(--warning-500)'}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              animation: 'pulse 2s infinite'
            }}>
              <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: 'white' }} />
            </div>
          </div>
        ))}

        {/* Floating Search Controls */}
        <div style={{ 
          position: 'absolute', 
          top: '20px', 
          right: '20px', 
          background: 'var(--surface-800)', 
          padding: '8px', 
          borderRadius: 'var(--radius-md)',
          display: 'flex',
          flexDirection: 'column',
          gap: '8px',
          border: '1px solid var(--surface-700)'
        }}>
          <button className="header__icon-btn" style={{ background: 'var(--surface-700)' }}>+</button>
          <button className="header__icon-btn" style={{ background: 'var(--surface-700)' }}>-</button>
          <button className="header__icon-btn" style={{ background: 'var(--surface-700)' }}>{Icons.map}</button>
        </div>

        {/* Live Status Overlay */}
        <div style={{ 
          position: 'absolute', 
          bottom: '20px', 
          left: '20px', 
          background: 'rgba(15, 23, 42, 0.8)', 
          padding: '12px 20px', 
          borderRadius: 'var(--radius-md)',
          backdropFilter: 'blur(8px)',
          border: '1px solid var(--surface-700)',
          display: 'flex',
          alignItems: 'center',
          gap: '12px'
        }}>
          <div style={{ animation: 'spin 4s linear infinite' }}>{Icons.refresh}</div>
          <div>
            <div style={{ fontSize: '10px', color: 'var(--surface-500)', textTransform: 'uppercase', letterSpacing: '1px' }}>Hệ thống giám sát</div>
            <div style={{ fontSize: '14px', fontWeight: 600 }}>Tọa độ thực thể: Đà Nẵng, VN</div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default MapPage
