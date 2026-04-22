import Icons from './Icons'
import { sidebarLinks } from '../utils/helpers'

function Sidebar({ activeNav, onNavClick, onlineDriverCount }) {
  return (
    <aside className="sidebar" id="sidebar">
      <div className="sidebar__brand">
        <div className="sidebar__logo">RN</div>
        <div className="sidebar__brand-text">
          <h1>Ride Now</h1>
          <span>Admin Panel</span>
        </div>
      </div>

      <nav className="sidebar__nav">
        {sidebarLinks.map((item, idx) => {
          if (item.section) {
            return <div key={`section-${idx}`} className="sidebar__section-title">{item.section}</div>
          }

          // Dynamic badge cho drivers online
          let badge = null
          if (item.id === 'nav-drivers' && onlineDriverCount > 0) {
            badge = onlineDriverCount
          }

          return (
            <button
              key={item.id}
              id={item.id}
              className={`sidebar__link ${activeNav === item.id ? 'sidebar__link--active' : ''}`}
              onClick={() => onNavClick(item.id)}
            >
              <span className="sidebar__link-icon">{Icons[item.icon]}</span>
              {item.label}
              {badge != null && <span className="sidebar__link-badge">{badge}</span>}
            </button>
          )
        })}
      </nav>

      <div className="sidebar__footer">
        <div className="sidebar__user">
          <div className="sidebar__avatar">AD</div>
          <div className="sidebar__user-info">
            <div className="sidebar__user-name">Admin</div>
            <div className="sidebar__user-role">Quản trị viên</div>
          </div>
          <span style={{ color: 'var(--surface-500)', cursor: 'pointer' }}>{Icons.logout}</span>
        </div>
      </div>
    </aside>
  )
}

export default Sidebar
