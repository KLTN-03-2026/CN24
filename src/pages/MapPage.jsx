import { useState, useEffect, useRef } from 'react'
import Icons from '../components/Icons'

const TRACKASIA_KEY = 'dff36ce825dbdb5a17750650297977c46b'

function MapPage({ drivers = [], trips = [] }) {
  const mapContainer = useRef(null)
  const map = useRef(null)
  const [lng] = useState(108.2022) // Tọa độ Đà Nẵng
  const [lat] = useState(16.0544)
  const [zoom] = useState(13)
  const markers = useRef({})
  const [mapError, setMapError] = useState(null)

  // Helper: Xác định trạng thái tài xế
  const getDriverStatus = (driver) => {
    // Nếu tài xế ngoại tuyến (check cả isOnline từ users và driver_locations)
    const isOnline = driver.isOnline === true
    if (!isOnline) return { label: 'Ngoại tuyến', color: '#94a3b8', status: 'offline' }
    
    // Nếu đang online nhưng không sẵn sàng (đang bận)
    if (driver.isAvailable === false) {
      return { label: 'Đang bận', color: '#ef4444', status: 'busy' }
    }

    // Kiểm tra thêm trong danh sách chuyến đi (logic dự phòng)
    const activeTrip = trips.find(t => 
      t.driverId === (driver.id || driver.uid) && 
      ['on_the_way', 'accepted', 'driver_assigned'].includes(t.status)
    )
    
    if (activeTrip) {
      return { label: 'Đang bận', color: '#ef4444', status: 'busy', tripId: activeTrip.id }
    }
    
    return { label: 'Sẵn sàng', color: '#22c55e', status: 'available' }
  }

  // Helper: Lấy tọa độ
  const getCoordinates = (driver) => {
    let dLat = driver.lat || driver.latitude
    let dLng = driver.lng || driver.longitude
    
    // Check location object (GeoPoint)
    if (!dLat && driver.location) {
      dLat = driver.location.latitude
      dLng = driver.location.longitude
    }

    // Nếu vẫn không có, dùng tọa độ giả lập để test (chỉ khi driver online)
    if (!dLat && driver.isOnline) {
      // Tạo tọa độ quanh Đà Nẵng dựa trên ID để không bị trùng lặp hoàn toàn
      const seed = (driver.id || driver.uid || '').charCodeAt(0) || 0
      dLat = 16.0544 + (seed % 20 - 10) * 0.002
      dLng = 108.2022 + (seed % 15 - 7) * 0.002
      return { lat: dLat, lng: dLng, isSimulated: true }
    }

    return { lat: dLat, lng: dLng, isSimulated: false }
  }

  // Khởi tạo bản đồ
  useEffect(() => {
    if (map.current) return

    const maplibregl = window.maplibregl
    if (!maplibregl) {
      setMapError('Thư viện MapLibre chưa được tải. Vui lòng làm mới trang.')
      return
    }

    try {
      const styleUrl = `https://maps.track-asia.com/styles/v2/streets.json?key=${TRACKASIA_KEY}`
      
      map.current = new maplibregl.Map({
        container: mapContainer.current,
        style: styleUrl,
        center: [lng, lat],
        zoom: zoom,
        attributionControl: false
      })

      map.current.addControl(new maplibregl.NavigationControl(), 'top-right')
      map.current.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right')

      map.current.on('load', () => {
        setMapError(null)
      })

    } catch (err) {
      setMapError(`Khởi tạo thất bại: ${err.message}`)
    }

    return () => {
      if (map.current) {
        map.current.remove()
        map.current = null
      }
    }
  }, [lng, lat, zoom])

  // Hiển thị tài xế thật lên bản đồ
  useEffect(() => {
    if (!map.current) return
    const maplibregl = window.maplibregl

    // Xóa các marker cũ không còn trong danh sách drivers mới
    const currentDriverIds = drivers.map(d => d.id || d.uid)
    Object.keys(markers.current).forEach(id => {
      if (!currentDriverIds.includes(id)) {
        markers.current[id].remove()
        delete markers.current[id]
      }
    })

    // Thêm hoặc cập nhật marker cho tài xế
    drivers.forEach(driver => {
      const driverId = driver.id || driver.uid
      const { lat: dLat, lng: dLng, isSimulated } = getCoordinates(driver)
      const { label, color, status } = getDriverStatus(driver)
      
      if (!dLat || !dLng) return

      if (!markers.current[driverId]) {
        // Tạo element cho marker
        const el = document.createElement('div')
        el.className = `map-marker map-marker--${status}`
        el.style.cursor = 'pointer'
        el.style.filter = 'drop-shadow(0 4px 6px rgba(0,0,0,0.3))'
        el.style.transition = 'all 0.3s ease'
        
        el.innerHTML = `
          <div style="position: relative; width: 44px; height: 44px; display: flex; align-items: center; justify-content: center;">
            <div class="marker-bg" style="position: absolute; width: 100%; height: 100%; background: white; border-radius: 50%; border: 3px solid ${color}; box-shadow: 0 0 10px ${color}44;"></div>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="position: relative; z-index: 1;">
              <circle cx="16.5" cy="14.5" r="2.5" fill="${color}"/>
              <circle cx="7.5" cy="14.5" r="2.5" fill="${color}"/>
              <path d="M16.5 12.5L14.5 7.5H9.5L7.5 12.5" stroke="${color}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M7 12.5H17" stroke="${color}" stroke-width="1.5" stroke-linecap="round"/>
              <path d="M11.5 7.5V12.5" stroke="${color}" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            ${isSimulated ? '<div style="position: absolute; top: -5px; right: -5px; background: #f59e0b; color: white; font-size: 8px; padding: 2px 4px; border-radius: 4px; font-weight: bold; border: 1px solid white;">SIM</div>' : ''}
          </div>
        `

        // Tạo Popup
        const popup = new maplibregl.Popup({ 
          offset: 25, 
          closeButton: false, 
          closeOnClick: false,
          className: 'driver-popup'
        }).setHTML(`
          <div style="padding: 8px 12px; min-width: 150px;">
            <div style="font-weight: 700; font-size: 14px; margin-bottom: 4px; color: #0f172a;">${driver.name || driver.fullName || 'Tài xế'}</div>
            <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 8px;">
              <span style="width: 8px; height: 8px; border-radius: 50%; background: ${color};"></span>
              <span style="font-size: 12px; color: ${color}; font-weight: 600;">${label}</span>
            </div>
            <div style="font-size: 11px; color: #64748b; border-top: 1px solid #e2e8f0; pt: 4px; margin-top: 4px;">
              <div>BSX: ${driver.vehiclePlate || '—'}</div>
              <div>SĐT: ${driver.phone || '—'}</div>
              ${isSimulated ? '<div style="color: #f59e0b; margin-top: 2px;">⚠️ Vị trí giả lập (Thiếu GPS)</div>' : ''}
            </div>
          </div>
        `)

        el.addEventListener('mouseenter', () => {
          markers.current[driverId].setPopup(popup)
          popup.addTo(map.current)
          el.style.transform = 'scale(1.1) translateY(-5px)'
        })

        el.addEventListener('mouseleave', () => {
          popup.remove()
          el.style.transform = 'scale(1) translateY(0)'
        })

        markers.current[driverId] = new maplibregl.Marker(el)
          .setLngLat([dLng, dLat])
          .addTo(map.current)
      } else {
        markers.current[driverId].setLngLat([dLng, dLat])
        // Cập nhật lại HTML nếu trạng thái thay đổi
        const markerEl = markers.current[driverId].getElement()
        const bgEl = markerEl.querySelector('.marker-bg')
        if (bgEl) bgEl.style.borderColor = color
        markerEl.querySelectorAll('circle').forEach(p => p.setAttribute('fill', color))
        markerEl.querySelectorAll('path[stroke]').forEach(p => p.setAttribute('stroke', color))
      }
    })
  }, [drivers, trips])

  return (
    <section className="rides-page" style={{ height: 'calc(100vh - 140px)', display: 'flex', flexDirection: 'column' }}>
      <div className="rides-page__header" style={{ marginBottom: '16px' }}>
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🗺️ Bản đồ trực tuyến (TrackAsia)</h2>
          <p className="rides-page__subtitle">Giám sát vị trí thực tế của {drivers.length} tài xế đang online</p>
        </div>
        <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: 'var(--font-sm)', color: 'var(--surface-300)' }}>
            <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#22c55e', boxShadow: '0 0 8px #22c55e66' }} /> Sẵn sàng
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: 'var(--font-sm)', color: 'var(--surface-300)' }}>
            <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#ef4444', boxShadow: '0 0 8px #ef444466' }} /> Đang bận
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: 'var(--font-sm)', color: 'var(--surface-300)' }}>
            <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#94a3b8', boxShadow: '0 0 8px #94a3b866' }} /> Ngoại tuyến
          </div>
        </div>
      </div>

      <div style={{ flex: 1, position: 'relative', borderRadius: 'var(--radius-lg)', overflow: 'hidden', border: '1px solid var(--surface-800)' }}>
        <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />
        
        {mapError && (
          <div style={{ 
            position: 'absolute', 
            inset: 0, 
            display: 'flex', 
            flexDirection: 'column',
            alignItems: 'center', 
            justifyContent: 'center', 
            background: 'rgba(15, 23, 42, 0.9)', 
            zIndex: 10,
            color: 'white',
            textAlign: 'center',
            padding: '20px'
          }}>
            <div style={{ fontSize: '3rem', marginBottom: '16px' }}>⚠️</div>
            <h3 style={{ marginBottom: '8px' }}>Không thể hiển thị bản đồ</h3>
            <p style={{ color: 'var(--surface-400)', maxWidth: '400px', marginBottom: '20px' }}>{mapError}</p>
            <button 
              onClick={() => window.location.reload()}
              style={{ padding: '10px 20px', background: 'var(--primary-600)', border: 'none', borderRadius: '4px', color: 'white', cursor: 'pointer' }}
            >
              Thử lại
            </button>
          </div>
        )}

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
          gap: '12px',
          zIndex: 5
        }}>
          <div style={{ animation: 'spin 4s linear infinite', color: 'var(--primary-400)' }}>{Icons.refresh}</div>
          <div>
            <div style={{ fontSize: '10px', color: 'var(--surface-500)', textTransform: 'uppercase', letterSpacing: '1px' }}>TrackAsia Live Engine</div>
            <div style={{ fontSize: '14px', fontWeight: 600 }}>Tâm điểm: Đà Nẵng, Việt Nam</div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default MapPage
