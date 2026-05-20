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
  const [mapLoaded, setMapLoaded] = useState(false)

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
    // Thử các field phổ biến
    let dLat = driver.lat || driver.latitude
    let dLng = driver.lng || driver.longitude

    // Check location object (GeoPoint từ Firestore)
    if (!dLat && driver.location) {
      if (typeof driver.location.latitude === 'number') {
        dLat = driver.location.latitude
        dLng = driver.location.longitude
      } else if (driver.location._lat !== undefined) {
        // GeoPoint serialized format
        dLat = driver.location._lat
        dLng = driver.location._long
      }
    }

    // Check lastLocation object
    if (!dLat && driver.lastLocation) {
      if (typeof driver.lastLocation.latitude === 'number') {
        dLat = driver.lastLocation.latitude
        dLng = driver.lastLocation.longitude
      }
    }

    // Check position object  
    if (!dLat && driver.position) {
      if (typeof driver.position.latitude === 'number') {
        dLat = driver.position.latitude
        dLng = driver.position.longitude
      }
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
        console.log('[MAP] Map loaded successfully!')
        setMapError(null)
        setMapLoaded(true)
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

  // Hiển thị tài xế thật lên bản đồ - CHỈ chạy khi map đã load xong
  useEffect(() => {
    if (!map.current || !mapLoaded) return
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
        // Tạo element cho marker - dùng hình xe máy từ trên xuống
        const el = document.createElement('div')
        el.className = `map-marker map-marker--${status}`
        el.style.cursor = 'pointer'
        el.style.transition = 'all 0.3s ease'

        const { label, color: statusColor, status: driverStatus } = getDriverStatus(driver)
        const statusIcon = driverStatus === 'available' ? '🟢' : driverStatus === 'busy' ? '🔴' : '⚫'

        el.innerHTML = `
          <div class="marker-content" style="position: relative; width: 44px; height: 64px; display: flex; align-items: center; justify-content: center; transition: all 0.3s ease;">
            <img src="/images/motorcycle-top.png" alt="driver" style="width: 40px; height: 58px; object-fit: contain; filter: drop-shadow(0 3px 6px rgba(0,0,0,0.4)); pointer-events: none;" />
            <div class="status-dot" style="position: absolute; bottom: -2px; right: -2px; width: 14px; height: 14px; border-radius: 50%; background: ${statusColor}; border: 2px solid white; box-shadow: 0 0 6px ${statusColor}88;"></div>
            ${isSimulated ? '<div style="position: absolute; top: -5px; right: -8px; background: #f59e0b; color: white; font-size: 10px; padding: 1px 3px; border-radius: 3px; font-weight: bold; border: 1px solid white;">SIM</div>' : ''}
          </div>
        `

        // Tạo Popup hiện khi hover - chỉ hiện tên + trạng thái online/offline
        const popup = new maplibregl.Popup({
          offset: [0, -35],
          closeButton: false,
          closeOnClick: false,
          className: 'driver-popup'
        }).setHTML(`
          <div style="padding: 10px 14px; min-width: 140px; text-align: center;">
            <div style="font-weight: 700; font-size: 20px; margin-bottom: 6px; color: #0f172a;">${driver.name || driver.fullName || 'Tài xế'}</div>
            <div style="display: inline-flex; align-items: center; gap: 6px; background: ${driverStatus === 'available' ? '#dcfce7' : driverStatus === 'busy' ? '#fee2e2' : '#f1f5f9'}; padding: 4px 12px; border-radius: 20px;">
              <span style="font-size: 14px;">${statusIcon}</span>
              <span style="font-size: 18px; color: ${statusColor}; font-weight: 700; letter-spacing: 0.5px;">${label}</span>
            </div>
            ${driver.vehiclePlate ? '<div style="font-size: 14px; color: #64748b; margin-top: 6px;">BSX: ' + driver.vehiclePlate + '</div>' : ''}
          </div>
        `)

        const contentEl = el.querySelector('.marker-content')

        el.addEventListener('mouseenter', () => {
          markers.current[driverId]?.setPopup(popup)
          popup.addTo(map.current)
          if (contentEl) {
            contentEl.style.transform = 'scale(1.15)'
            contentEl.style.filter = 'drop-shadow(0 6px 12px rgba(0,0,0,0.35))'
          }
        })

        el.addEventListener('mouseleave', () => {
          popup.remove()
          if (contentEl) {
            contentEl.style.transform = 'scale(1)'
            contentEl.style.filter = 'none'
          }
        })

        markers.current[driverId] = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat([dLng, dLat])
          .addTo(map.current)
      } else {
        markers.current[driverId].setLngLat([dLng, dLat])
        // Cập nhật trạng thái dot
        const markerEl = markers.current[driverId].getElement()
        const dotEl = markerEl.querySelector('.status-dot')
        const isOnline = driver.isOnline === true
        const statusColor = isOnline ? '#22c55e' : '#94a3b8'
        if (dotEl) {
          dotEl.style.background = statusColor
          dotEl.style.boxShadow = `0 0 6px ${statusColor}88`
        }
      }
    })
  }, [drivers, trips, mapLoaded])

  // Fly tới vị trí tài xế
  const flyToDriver = (dLat, dLng) => {
    if (map.current && dLat && dLng) {
      map.current.flyTo({ center: [dLng, dLat], zoom: 16, duration: 1500 })
    }
  }

  return (
    <section className="rides-page" style={{ height: 'calc(100vh - 140px)', display: 'flex', flexDirection: 'column' }}>
      <div className="rides-page__header" style={{ marginBottom: '16px' }}>
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🗺️ Bản đồ trực tuyến (TrackAsia)</h2>
          <p className="rides-page__subtitle">Giám sát vị trí thực tế của {drivers.length} tài xế</p>
        </div>
        <div style={{ display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: 'var(--font-sm)', color: 'var(--surface-300)' }}>
            <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#22c55e', boxShadow: '0 0 8px #22c55e66' }} /> Online
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: 'var(--font-sm)', color: 'var(--surface-300)' }}>
            <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#94a3b8', boxShadow: '0 0 8px #94a3b866' }} /> Offline
          </div>
        </div>
      </div>

      <div style={{ flex: 1, display: 'flex', gap: '16px', minHeight: 0 }}>
        {/* Bản đồ */}
        <div style={{ flex: '1 1 70%', position: 'relative', borderRadius: 'var(--radius-lg)', overflow: 'hidden', border: '1px solid var(--surface-800)' }}>
          <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />

          {mapError && (
            <div style={{
              position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
              alignItems: 'center', justifyContent: 'center',
              background: 'rgba(15, 23, 42, 0.9)', zIndex: 10, color: 'white', textAlign: 'center', padding: '20px'
            }}>
              <div style={{ fontSize: '4rem', marginBottom: '16px' }}>⚠️</div>
              <h3 style={{ marginBottom: '8px' }}>Không thể hiển thị bản đồ</h3>
              <p style={{ color: 'var(--surface-400)', maxWidth: '400px', marginBottom: '20px' }}>{mapError}</p>
              <button onClick={() => window.location.reload()}
                style={{ padding: '10px 20px', background: 'var(--primary-600)', border: 'none', borderRadius: '4px', color: 'white', cursor: 'pointer' }}>
                Thử lại
              </button>
            </div>
          )}

          {/* Live Status Overlay */}
          <div style={{
            position: 'absolute', bottom: '20px', left: '20px',
            background: 'rgba(15, 23, 42, 0.8)', padding: '12px 20px',
            borderRadius: 'var(--radius-md)', backdropFilter: 'blur(8px)',
            border: '1px solid var(--surface-700)', display: 'flex', alignItems: 'center', gap: '12px', zIndex: 5
          }}>
            <div style={{ animation: 'spin 4s linear infinite', color: 'var(--primary-400)' }}>{Icons.refresh}</div>
            <div>
              <div style={{ fontSize: '14px', color: 'var(--surface-500)', textTransform: 'uppercase', letterSpacing: '1px' }}>TrackAsia Live Engine</div>
              <div style={{ fontSize: '18px', fontWeight: 600 }}>Đà Nẵng, Việt Nam</div>
            </div>
          </div>
        </div>

        {/* Bảng vị trí tài xế */}
        <div style={{
          flex: '0 0 320px', background: 'var(--surface-900)', borderRadius: 'var(--radius-lg)',
          border: '1px solid var(--surface-800)', display: 'flex', flexDirection: 'column', overflow: 'hidden'
        }}>
          <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--surface-800)' }}>
            <h3 style={{ fontSize: '20px', fontWeight: 700, margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
              📍 Vị trí tài xế <span style={{ fontSize: '16px', color: 'var(--surface-400)', fontWeight: 400 }}>({drivers.length})</span>
            </h3>
          </div>

          <div style={{ flex: 1, overflowY: 'auto', padding: '8px' }}>
            {drivers.length === 0 ? (
              <div style={{ padding: '40px 20px', textAlign: 'center', color: 'var(--surface-500)' }}>
                <div style={{ fontSize: '2rem', marginBottom: '8px' }}>🏍️</div>
                <div>Chưa có tài xế nào</div>
              </div>
            ) : (
              drivers.map(driver => {
                const driverId = driver.id || driver.uid
                const coords = getCoordinates(driver)
                const isOnline = driver.isOnline === true
                const hasCoords = coords.lat && coords.lng

                return (
                  <div key={driverId} style={{
                    padding: '12px 14px', marginBottom: '6px',
                    background: 'var(--surface-850, rgba(30,41,59,0.5))',
                    borderRadius: 'var(--radius-md)', border: '1px solid var(--surface-800)',
                    transition: 'all 0.2s ease',
                    cursor: hasCoords ? 'pointer' : 'default',
                    opacity: hasCoords ? 1 : 0.6
                  }}
                    onClick={() => hasCoords && flyToDriver(coords.lat, coords.lng)}
                    onMouseEnter={e => { if (hasCoords) e.currentTarget.style.borderColor = 'var(--primary-600)' }}
                    onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--surface-800)' }}
                  >
                    {/* Hàng 1: Tên + Status */}
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{
                          width: '32px', height: '32px', borderRadius: '50%',
                          background: `linear-gradient(135deg, ${isOnline ? '#22c55e33' : '#94a3b833'}, ${isOnline ? '#22c55e11' : '#94a3b811'})`,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          border: `2px solid ${isOnline ? '#22c55e' : '#94a3b8'}`,
                          fontSize: '14px'
                        }}>
                          🏍️
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '18px' }}>{driver.name || driver.fullName || 'Tài xế'}</div>
                          <div style={{ fontSize: '14px', color: 'var(--surface-400)' }}>{driver.vehiclePlate || '—'}</div>
                        </div>
                      </div>
                      <span style={{
                        padding: '4px 14px', borderRadius: '16px', fontSize: '14px', fontWeight: 700,
                        background: isOnline ? 'rgba(34,197,94,0.15)' : 'rgba(148,163,184,0.15)',
                        color: isOnline ? '#22c55e' : '#94a3b8',
                        border: `1px solid ${isOnline ? '#22c55e44' : '#94a3b844'}`
                      }}>
                        {isOnline ? '● Online' : '○ Offline'}
                      </span>
                    </div>

                    {/* Hàng 2: Tọa độ */}
                    <div style={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      background: 'rgba(0,0,0,0.2)', borderRadius: '6px', padding: '6px 10px'
                    }}>
                      {hasCoords ? (
                        <>
                          <div style={{ fontSize: '11px', fontFamily: 'monospace', color: 'var(--surface-300)' }}>
                            <span style={{ color: 'var(--surface-500)' }}>Lat:</span> {coords.lat.toFixed(6)}
                            <br />
                            <span style={{ color: 'var(--surface-500)' }}>Lng:</span> {coords.lng.toFixed(6)}
                            {coords.isSimulated && <span style={{ color: '#f59e0b', marginLeft: '6px' }}>(SIM)</span>}
                          </div>
                          <div style={{
                            width: '28px', height: '28px', borderRadius: '50%',
                            background: 'var(--primary-600)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                            fontSize: '12px', flexShrink: 0, transition: 'transform 0.2s',
                          }}
                            title="Bay tới vị trí"
                            onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.15)'}
                            onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                          >
                            🎯
                          </div>
                        </>
                      ) : (
                        <div style={{ fontSize: '11px', color: 'var(--surface-500)', fontStyle: 'italic' }}>
                          Chưa có dữ liệu vị trí
                        </div>
                      )}
                    </div>
                  </div>
                )
              })
            )}
          </div>
        </div>
      </div>
    </section>
  )
}

export default MapPage
