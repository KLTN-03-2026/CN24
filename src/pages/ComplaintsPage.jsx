import React, { useState, useEffect, useMemo } from 'react';
import { onComplaints, updateComplaintStatus } from '../firestoreService';
import { format } from 'date-fns';
import Icons from '../components/Icons';

/* ===== Complaint Detail Modal ===== */
const ComplaintDetailModal = ({ complaint, onClose, onUpdateStatus, isUpdating, adminNotes, setAdminNotes }) => {
  if (!complaint) return null;

  const statusMap = {
    pending: { label: 'Chờ xử lý', css: 'active' },
    in_progress: { label: 'Đang xử lý', css: 'active' },
    resolved: { label: 'Đã giải quyết', css: 'completed' },
    rejected: { label: 'Đã từ chối', css: 'cancelled' },
  };

  const st = statusMap[complaint.status] || { label: complaint.status, css: 'active' };

  const formatDateFull = (timestamp) => {
    if (!timestamp) return '—';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return format(date, 'dd/MM/yyyy HH:mm:ss');
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal trip-detail-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '600px' }}>
        <div className="modal__header">
          <h2 className="modal__title">📑 Chi tiết khiếu nại</h2>
          <button className="modal__close" onClick={onClose}>
            {Icons.close}
          </button>
        </div>
        <div className="modal__body">
          <div className="trip-detail">
            <div className="trip-detail__row trip-detail__row--highlight">
              <span className="trip-detail__label">Mã khiếu nại</span>
              <span className="trip-detail__value trip-detail__id">{complaint.id?.toUpperCase()}</span>
            </div>
            
            <div className="trip-detail__row">
              <span className="trip-detail__label">Trạng thái</span>
              <span className={`table__status table__status--${st.css}`}>
                <span className="table__status-dot" />
                {st.label}
              </span>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row">
              <span className="trip-detail__label">👤 Người gửi</span>
              <div className="flex flex-col">
                <span className="trip-detail__value font-mono text-xs" style={{ color: 'var(--surface-100)' }}>{complaint.userId}</span>
                <span className="text-[10px] uppercase opacity-60 tracking-wider font-bold">{complaint.userRole}</span>
              </div>
            </div>

            <div className="trip-detail__row">
              <span className="trip-detail__label">🚗 Mã chuyến đi</span>
              <span className="trip-detail__value font-mono">{complaint.tripId?.toUpperCase()}</span>
            </div>

            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Ngày gửi</span>
              <span className="trip-detail__value">{formatDateFull(complaint.createdAt)}</span>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">📝 Lý do khiếu nại</span>
              <span className="trip-detail__value" style={{ color: 'var(--danger-400)', fontWeight: 600 }}>
                {complaint.reason}
              </span>
            </div>

            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">💬 Nội dung chi tiết</span>
              <div className="complaint-content-box">
                {complaint.description}
              </div>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">🛠️ Ghi chú xử lý (Nội bộ)</span>
              <textarea
                className="complaint-admin-notes"
                rows="3"
                value={adminNotes}
                onChange={(e) => setAdminNotes(e.target.value)}
                placeholder="Nhập ghi chú xử lý của quản trị viên..."
              />
            </div>
          </div>

          <div className="modal__footer flex justify-end gap-3" style={{ marginTop: '24px' }}>
            <button 
              className="confirm-modal__btn confirm-modal__btn--cancel" 
              onClick={onClose}
              style={{ padding: '8px 16px' }}
            >
              Hủy
            </button>
            
            {complaint.status !== 'resolved' && (
              <button 
                className="confirm-modal__btn"
                style={{ background: 'var(--success-600)', color: 'white', padding: '8px 16px' }}
                onClick={() => onUpdateStatus('resolved')}
                disabled={isUpdating}
              >
                {isUpdating ? '...' : '✅ Đã giải quyết'}
              </button>
            )}
            
            {complaint.status !== 'in_progress' && complaint.status !== 'resolved' && (
              <button 
                className="confirm-modal__btn"
                style={{ background: 'var(--primary-600)', color: 'white', padding: '8px 16px' }}
                onClick={() => onUpdateStatus('in_progress')}
                disabled={isUpdating}
              >
                {isUpdating ? '...' : '⚙️ Đang xử lý'}
              </button>
            )}
          </div>
        </div>
      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        .complaint-content-box {
          background: rgba(248, 113, 113, 0.05);
          border: 1px solid rgba(248, 113, 113, 0.2);
          border-left: 4px solid var(--danger-500);
          padding: 12px;
          border-radius: var(--radius-md);
          font-size: var(--font-sm);
          color: var(--surface-200);
          margin-top: 8px;
          white-space: pre-wrap;
        }
        .complaint-admin-notes {
          width: 100%;
          background: var(--surface-800);
          border: 1px solid var(--surface-700);
          border-radius: var(--radius-md);
          padding: 10px;
          color: var(--surface-100);
          font-family: inherit;
          font-size: var(--font-sm);
          margin-top: 8px;
          outline: none;
          transition: border-color 0.2s;
        }
        .complaint-admin-notes:focus {
          border-color: var(--primary-500);
        }
      `}} />
    </div>
  );
};

const ComplaintsPage = () => {
  const [complaints, setComplaints] = useState([]);
  const [allComplaints, setAllComplaints] = useState([]);
  const [statusFilter, setStatusFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  
  // Modal states
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [adminNotes, setAdminNotes] = useState('');
  const [isUpdating, setIsUpdating] = useState(false);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = onComplaints(
      (data) => {
        if (statusFilter === 'all') {
          setAllComplaints(data);
          setComplaints(data);
        } else {
          setComplaints(data);
        }
        setLoading(false);
      },
      statusFilter,
      200
    );

    return () => unsubscribe();
  }, [statusFilter]);

  // Secondary listener for global stats
  useEffect(() => {
    if (statusFilter !== 'all') {
      const unsub = onComplaints((data) => setAllComplaints(data), 'all', 500);
      return () => unsub();
    }
  }, [statusFilter]);

  const stats = useMemo(() => {
    const total = allComplaints.length;
    const pending = allComplaints.filter(c => c.status === 'pending').length;
    const processing = allComplaints.filter(c => c.status === 'in_progress').length;
    const resolved = allComplaints.filter(c => c.status === 'resolved').length;
    
    return { total, pending, processing, resolved };
  }, [allComplaints]);

  const handleOpenModal = (complaint) => {
    setSelectedComplaint(complaint);
    setAdminNotes(complaint.adminNotes || '');
  };

  const handleCloseModal = () => {
    setSelectedComplaint(null);
    setAdminNotes('');
  };

  const handleUpdateStatus = async (newStatus) => {
    if (!selectedComplaint) return;
    setIsUpdating(true);
    const result = await updateComplaintStatus(selectedComplaint.id, newStatus, adminNotes);
    setIsUpdating(false);
    if (result.success) {
      handleCloseModal();
    } else {
      alert('Lỗi cập nhật trạng thái: ' + result.error);
    }
  };

  const statusTabs = [
    { key: 'all', label: 'Tất cả' },
    { key: 'pending', label: 'Chờ xử lý' },
    { key: 'in_progress', label: 'Đang xử lý' },
    { key: 'resolved', label: 'Đã giải quyết' },
    { key: 'rejected', label: 'Từ chối' },
  ];

  return (
    <section className="rides-page animate-fadeInUp">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">🛡️ Quản lý Khiếu nại</h2>
          <p className="rides-page__subtitle">Tiếp nhận và giải quyết các phản hồi từ người dùng hệ thống</p>
        </div>
      </div>

      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{stats.total}</span>
          <span className="rides-stat__label">Tổng khiếu nại</span>
        </div>
        <div className="rides-stat rides-stat--active" style={{ borderColor: 'var(--warning-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--warning-400)' }}>{stats.pending}</span>
          <span className="rides-stat__label">Đang chờ</span>
        </div>
        <div className="rides-stat rides-stat--active" style={{ borderColor: 'var(--primary-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--primary-400)' }}>{stats.processing}</span>
          <span className="rides-stat__label">Đang xử lý</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{stats.resolved}</span>
          <span className="rides-stat__label">Đã giải quyết</span>
        </div>
      </div>

      <div className="rides-toolbar">
        <div className="rides-toolbar__filters" style={{ marginLeft: 0 }}>
          {statusTabs.map(tab => (
            <button
              key={tab.key}
              className={`rides-toolbar__filter-btn ${statusFilter === tab.key ? 'rides-toolbar__filter-btn--active' : ''}`}
              onClick={() => setStatusFilter(tab.key)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách khiếu nại...</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Người gửi</th>
                  <th>Mã chuyến</th>
                  <th>Lý do</th>
                  <th>Ngày gửi</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {complaints.length === 0 ? (
                  <tr>
                    <td colSpan="6" style={{ textAlign: 'center', padding: '48px', color: 'var(--surface-500)' }}>
                      Không có khiếu nại nào được tìm thấy.
                    </td>
                  </tr>
                ) : (
                  complaints.map((c) => {
                    const statusMap = {
                      pending: { label: 'Chờ xử lý', css: 'active' },
                      in_progress: { label: 'Đang xử lý', css: 'active' },
                      resolved: { label: 'Đã giải quyết', css: 'completed' },
                      rejected: { label: 'Từ chối', css: 'cancelled' },
                    };
                    const st = statusMap[c.status] || { label: c.status, css: 'active' };
                    
                    return (
                      <tr key={c.id}>
                        <td>
                          <div className="flex flex-col">
                            <span className="font-medium" style={{ color: 'var(--surface-100)' }}>{c.userId.substring(0, 8)}...</span>
                            <span className="text-[10px] uppercase opacity-60 font-bold">{c.userRole}</span>
                          </div>
                        </td>
                        <td className="font-mono text-xs opacity-80">
                          {c.tripId.substring(0, 12)}...
                        </td>
                        <td style={{ fontWeight: 600, color: 'var(--surface-100)' }}>
                          {c.reason}
                        </td>
                        <td className="text-xs">
                          {c.createdAt?.toDate ? format(c.createdAt.toDate(), 'dd/MM/yyyy HH:mm') : '-'}
                        </td>
                        <td>
                          <span className={`table__status table__status--${st.css}`}>
                            <span className="table__status-dot" />
                            {st.label}
                          </span>
                        </td>
                        <td>
                          <div className="rides-table__actions">
                            <button 
                              className="rides-table__action-btn" 
                              onClick={() => handleOpenModal(c)}
                              title="Xem chi tiết"
                            >
                              👁️
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedComplaint && (
        <ComplaintDetailModal
          complaint={selectedComplaint}
          onClose={handleCloseModal}
          onUpdateStatus={handleUpdateStatus}
          isUpdating={isUpdating}
          adminNotes={adminNotes}
          setAdminNotes={setAdminNotes}
        />
      )}
    </section>
  );
};

export default ComplaintsPage;
