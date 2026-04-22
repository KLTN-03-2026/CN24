function ConnectionBanner({ status, error }) {
  if (status === 'connected') return null

  const styles = {
    padding: '12px 24px',
    textAlign: 'center',
    fontSize: 'var(--font-sm)',
    fontWeight: 500,
    animation: 'fadeInUp 0.3s ease-out',
  }

  if (status === 'loading') {
    return (
      <div style={{ ...styles, background: 'rgba(99, 102, 241, 0.1)', color: 'var(--primary-400)', borderBottom: '1px solid rgba(99, 102, 241, 0.2)' }}>
        ⏳ Đang kết nối Firebase... Đang tải dữ liệu thật từ Firestore
      </div>
    )
  }

  if (status === 'error') {
    return (
      <div style={{ ...styles, background: 'rgba(239, 68, 68, 0.1)', color: 'var(--danger-400)', borderBottom: '1px solid rgba(239, 68, 68, 0.2)' }}>
        ⚠️ Lỗi kết nối Firebase: {error}
        <button onClick={() => window.location.reload()} style={{ marginLeft: 12, color: 'var(--primary-400)', textDecoration: 'underline', background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
          Thử lại
        </button>
      </div>
    )
  }

  return null
}

export default ConnectionBanner
