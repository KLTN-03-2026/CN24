import { useState } from 'react'
import Icons from '../components/Icons'

function SettingsPage() {
  const [activeTab, setActiveTab] = useState('profile')

  return (
    <section className="rides-page">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">⚙️ Cài đặt hệ thống</h2>
          <p className="rides-page__subtitle">Tùy chỉnh cấu hình và quản lý tài khoản quản trị</p>
        </div>
      </div>

      <div className="content-grid" style={{ gridTemplateColumns: '250px 1fr', alignItems: 'start' }}>
        {/* Sidebar Settings */}
        <div className="table-card" style={{ padding: '12px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            {[
              { id: 'profile', label: 'Hồ sơ cá nhân', icon: '👥' },
              { id: 'notifications', label: 'Thông báo', icon: '🔔' },
              { id: 'security', label: 'Bảo mật', icon: '🔒' },
              { id: 'appearance', label: 'Giao diện', icon: '🎨' },
              { id: 'system', label: 'Hệ thống', icon: '🖥️' },
            ].map(item => (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  padding: '12px 16px',
                  borderRadius: 'var(--radius-md)',
                  background: activeTab === item.id ? 'var(--primary-600)' : 'transparent',
                  color: activeTab === item.id ? 'white' : 'var(--surface-300)',
                  border: 'none',
                  cursor: 'pointer',
                  textAlign: 'left',
                  fontSize: 'var(--font-sm)',
                  fontWeight: activeTab === item.id ? 600 : 400,
                  transition: 'all 0.2s'
                }}
              >
                <span>{item.icon}</span>
                {item.label}
              </button>
            ))}
          </div>
        </div>

        {/* Content Settings */}
        <div className="table-card" style={{ padding: '32px' }}>
          {activeTab === 'profile' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Thông tin quản trị viên</h3>
              <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
                <div style={{ 
                  width: '80px', 
                  height: '80px', 
                  borderRadius: '50%', 
                  background: 'var(--primary-600)', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center',
                  fontSize: '1.5rem',
                  fontWeight: 600
                }}>AD</div>
                <button className="confirm-modal__btn confirm-modal__btn--cancel">Thay đổi ảnh</button>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div className="trip-detail__row trip-detail__row--column">
                  <label style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', marginBottom: '8px' }}>Họ và tên</label>
                  <input type="text" className="header__search-input" defaultValue="Admin Ride Now" style={{ width: '100%', padding: '10px' }} />
                </div>
                <div className="trip-detail__row trip-detail__row--column">
                  <label style={{ fontSize: 'var(--font-xs)', color: 'var(--surface-500)', marginBottom: '8px' }}>Email liên hệ</label>
                  <input type="email" className="header__search-input" defaultValue="admin@ridenow.com" style={{ width: '100%', padding: '10px' }} />
                </div>
              </div>
              <button className="confirm-modal__btn confirm-modal__btn--delete" style={{ background: 'var(--primary-600)', width: 'fit-content' }}>Lưu thay đổi</button>
            </div>
          )}
          {activeTab !== 'profile' && (
            <div style={{ textAlign: 'center', padding: '40px', color: 'var(--surface-500)' }}>
              <div style={{ fontSize: '3rem', marginBottom: '16px' }}>🛠️</div>
              <h3>Tính năng đang phát triển</h3>
              <p>Phần cài đặt này sẽ sớm có mặt trong phiên bản cập nhật tới.</p>
            </div>
          )}
        </div>
      </div>
    </section>
  )
}

export default SettingsPage
