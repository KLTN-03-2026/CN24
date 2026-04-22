import Icons from './Icons'
import { getVietnameseDate } from '../utils/helpers'

function Header({ isLive, onRefresh, loading }) {
  return (
    <header className="header" id="header">
      <div className="header__left">
        <h2 className="header__greeting">
          Xin chào, <span>Admin</span> 👋
        </h2>
        <p className="header__date">
          {getVietnameseDate()}
          {isLive && (
            <span style={{ marginLeft: '12px', display: 'inline-flex', alignItems: 'center', gap: '6px', color: 'var(--success-400)', fontSize: 'var(--font-xs)', fontWeight: 600 }}>
              {Icons.live} Realtime
            </span>
          )}
        </p>
      </div>
      <div className="header__actions">
        <div className="header__search">
          <span className="header__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="header__search-input"
            id="search-input"
            placeholder="Tìm kiếm chuyến đi, tài xế..."
          />
        </div>
        <button
          className="header__icon-btn"
          id="btn-refresh"
          title="Tải lại dữ liệu"
          onClick={onRefresh}
          style={loading ? { animation: 'spin 1s linear infinite' } : {}}
        >
          {Icons.refresh}
        </button>
        <button className="header__icon-btn" id="btn-notifications" title="Thông báo">
          {Icons.bell}
          <span className="badge">3</span>
        </button>
        <button className="header__icon-btn" id="btn-settings" title="Cài đặt">
          {Icons.settings}
        </button>
      </div>
    </header>
  )
}

export default Header
