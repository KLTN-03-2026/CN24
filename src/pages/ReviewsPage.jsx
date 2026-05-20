import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { onReviews, deleteReview } from '../firestoreService';
import { format } from 'date-fns';
import Icons from '../components/Icons';
import { getInitials } from '../utils/helpers';

/* ===== Review Detail Modal ===== */
const ReviewDetailModal = ({ review, onClose, onDelete, isDeleting }) => {
  if (!review) return null;

  const formatDateFull = (timestamp) => {
    if (!timestamp) return '—';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return format(date, 'dd/MM/yyyy HH:mm:ss');
  };

  const renderStars = (rating) => {
    return Array.from({ length: 5 }).map((_, i) => (
      <span key={i} style={{ color: i < rating ? 'var(--warning-400)' : 'var(--surface-600)', fontSize: '1.5rem' }}>
        {i < rating ? '★' : '☆'}
      </span>
    ));
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal trip-detail-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '550px' }}>
        <div className="modal__header">
          <h2 className="modal__title">⭐ Chi tiết đánh giá</h2>
          <button className="modal__close" onClick={onClose}>
            {Icons.close}
          </button>
        </div>
        <div className="modal__body">
          <div className="trip-detail">
            <div className="trip-detail__row trip-detail__row--highlight">
              <span className="trip-detail__label">Mã đánh giá</span>
              <span className="trip-detail__value trip-detail__id">{review.id?.toUpperCase()}</span>
            </div>
            
            <div className="trip-detail__row">
              <span className="trip-detail__label">Đánh giá</span>
              <div className="flex items-center gap-1">
                {renderStars(review.rating)}
                <span className="ml-2 font-bold" style={{ color: 'var(--warning-400)' }}>{review.rating}/5</span>
              </div>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row">
              <span className="trip-detail__label">👤 Khách hàng</span>
              <div className="flex items-center gap-3">
                <div className="table__rider-avatar" style={{ width: '40px', height: '40px', fontSize: '16px' }}>
                  {getInitials(review.customerName)}
                </div>
                <span className="trip-detail__value">{review.customerName || '—'}</span>
              </div>
            </div>

            <div className="trip-detail__row">
              <span className="trip-detail__label">👨‍✈️ Tài xế</span>
              <div className="flex items-center gap-3">
                <div className="table__rider-avatar" style={{ width: '40px', height: '40px', fontSize: '16px', background: 'var(--primary-600)' }}>
                  {getInitials(review.driverName)}
                </div>
                <span className="trip-detail__value">{review.driverName || '—'}</span>
              </div>
            </div>

            <div className="trip-detail__row">
              <span className="trip-detail__label">🚗 Mã chuyến đi</span>
              <span className="trip-detail__value font-mono text-sm">{review.tripId?.toUpperCase() || '—'}</span>
            </div>

            <div className="trip-detail__divider" />

            <div className="trip-detail__row trip-detail__row--column">
              <span className="trip-detail__label">💬 Nội dung đánh giá</span>
              <div className="review-comment-box">
                {review.comment || <span className="opacity-40 italic">Không có nhận xét</span>}
              </div>
            </div>

            <div className="trip-detail__row">
              <span className="trip-detail__label">🕐 Thời gian</span>
              <span className="trip-detail__value">{formatDateFull(review.createdAt)}</span>
            </div>
          </div>

          <div className="modal__footer flex justify-between items-center" style={{ marginTop: '32px' }}>
            <button 
              className="confirm-modal__btn confirm-modal__btn--delete"
              onClick={() => onDelete(review.id)}
              disabled={isDeleting}
              style={{ padding: '10px 20px', borderRadius: '12px' }}
            >
              {isDeleting ? '...' : '🗑️ Xóa đánh giá'}
            </button>
            
            <button 
              className="confirm-modal__btn confirm-modal__btn--cancel" 
              onClick={onClose}
              style={{ padding: '10px 24px', borderRadius: '12px' }}
            >
              Đóng
            </button>
          </div>
        </div>
      </div>

      <style dangerouslySetInnerHTML={{ __html: `
        .review-comment-box {
          background: var(--surface-800);
          border: 1px solid var(--surface-700);
          padding: 16px;
          border-radius: 12px;
          font-size: var(--font-sm);
          color: var(--surface-100);
          margin-top: 8px;
          line-height: 1.6;
          min-height: 80px;
          position: relative;
        }
        .review-comment-box::before {
          content: '"';
          position: absolute;
          top: 0;
          left: 8px;
          font-size: 50px;
          opacity: 0.1;
          font-family: serif;
        }
      `}} />
    </div>
  );
};

const ReviewsPage = () => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [ratingFilter, setRatingFilter] = useState('all');
  
  // Modal states
  const [selectedReview, setSelectedReview] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    setLoading(true);
    const unsubscribe = onReviews((data) => {
      setReviews(data);
      setLoading(false);
    }, 300);

    return () => unsubscribe();
  }, []);

  const showToast = useCallback((message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  }, []);

  const handleDeleteReview = async (id) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa đánh giá này?')) return;
    setIsDeleting(true);
    const result = await deleteReview(id);
    setIsDeleting(false);
    if (result.success) {
      showToast('Đã xóa đánh giá thành công');
      setSelectedReview(null);
    } else {
      showToast('Lỗi khi xóa: ' + result.error, 'error');
    }
  };

  const filteredReviews = useMemo(() => {
    let result = reviews;
    
    if (ratingFilter !== 'all') {
      result = result.filter(r => r.rating === parseInt(ratingFilter));
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      result = result.filter(r => 
        r.customerName?.toLowerCase().includes(q) || 
        r.driverName?.toLowerCase().includes(q) || 
        r.comment?.toLowerCase().includes(q) ||
        r.tripId?.toLowerCase().includes(q)
      );
    }
    
    return result;
  }, [reviews, ratingFilter, searchQuery]);

  const stats = useMemo(() => {
    if (reviews.length === 0) return { avg: 0, total: 0, five: 0, low: 0 };
    const total = reviews.length;
    const sum = reviews.reduce((s, r) => s + (r.rating || 0), 0);
    const five = reviews.filter(r => r.rating === 5).length;
    const low = reviews.filter(r => r.rating <= 2).length;
    return {
      avg: (sum / total).toFixed(1),
      total,
      five,
      low
    };
  }, [reviews]);

  const renderStars = (rating) => {
    return (
      <div className="flex gap-0.5 text-warning-400">
        {Array.from({ length: 5 }).map((_, i) => (
          <span key={i} style={{ fontSize: '1.1rem' }}>
            {i < rating ? '★' : '☆'}
          </span>
        ))}
      </div>
    );
  };

  return (
    <section className="rides-page animate-fadeInUp">
      <div className="rides-page__header">
        <div className="rides-page__title-block">
          <h2 className="rides-page__title">⭐ Quản lý Đánh giá</h2>
          <p className="rides-page__subtitle">Theo dõi phản hồi và chất lượng dịch vụ từ khách hàng</p>
        </div>
      </div>

      <div className="rides-stats">
        <div className="rides-stat rides-stat--total">
          <span className="rides-stat__number">{stats.avg}</span>
          <span className="rides-stat__label">⭐ Trung bình</span>
        </div>
        <div className="rides-stat rides-stat--completed">
          <span className="rides-stat__number">{stats.total}</span>
          <span className="rides-stat__label">Tổng đánh giá</span>
        </div>
        <div className="rides-stat rides-stat--active" style={{ borderColor: 'var(--success-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--success-400)' }}>{stats.five}</span>
          <span className="rides-stat__label">5 sao tuyệt đối</span>
        </div>
        <div className="rides-stat rides-stat--active" style={{ borderColor: 'var(--danger-500)' }}>
          <span className="rides-stat__number" style={{ color: 'var(--danger-400)' }}>{stats.low}</span>
          <span className="rides-stat__label">Cần lưu ý (≤ 2 sao)</span>
        </div>
      </div>

      <div className="rides-toolbar">
        <div className="rides-toolbar__search">
          <span className="rides-toolbar__search-icon">{Icons.search}</span>
          <input
            type="text"
            className="rides-toolbar__search-input"
            placeholder="Tìm theo tên, nhận xét, mã chuyến..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <div className="rides-toolbar__filters">
          {['all', '5', '4', '3', '2', '1'].map(val => (
            <button
              key={val}
              className={`rides-toolbar__filter-btn ${ratingFilter === val ? 'rides-toolbar__filter-btn--active' : ''}`}
              onClick={() => setRatingFilter(val)}
            >
              {val === 'all' ? 'Tất cả' : `${val} ★`}
            </button>
          ))}
        </div>
      </div>

      <div className="table-card rides-table-card">
        {loading ? (
          <div className="rides-loading">
            <div className="rides-loading__spinner" />
            <p>Đang tải danh sách đánh giá...</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="table rides-table">
              <thead>
                <tr>
                  <th>Khách hàng</th>
                  <th>Tài xế</th>
                  <th>Xếp hạng</th>
                  <th>Nhận xét</th>
                  <th>Thời gian</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredReviews.length === 0 ? (
                  <tr>
                    <td colSpan="6" style={{ textAlign: 'center', padding: '64px', color: 'var(--surface-500)' }}>
                      <div style={{ fontSize: '3rem', marginBottom: '8px' }}>🔍</div>
                      Không tìm thấy đánh giá nào.
                    </td>
                  </tr>
                ) : (
                  filteredReviews.map((r) => (
                    <tr key={r.id} className="hover:bg-surface-800/30 transition-colors">
                      <td>
                        <div className="flex items-center gap-2">
                          <div className="table__rider-avatar" style={{ width: '36px', height: '36px', fontSize: '14px' }}>
                            {getInitials(r.customerName)}
                          </div>
                          <span className="font-medium text-surface-100">{r.customerName}</span>
                        </div>
                      </td>
                      <td>
                        <button 
                          className="text-surface-100 hover:text-primary-400 font-medium transition-colors text-left"
                          onClick={() => setSearchQuery(r.driverName || '')}
                          title={`Lọc theo tài xế ${r.driverName}`}
                        >
                          {r.driverName || '—'}
                        </button>
                      </td>
                      <td>
                        <div className="flex flex-col gap-1">
                          <span className="font-bold text-warning-400">{r.rating} ★</span>
                          {renderStars(r.rating)}
                        </div>
                      </td>
                      <td style={{ maxWidth: '300px' }}>
                        <p className="truncate-2 text-surface-200 text-base italic">
                          {r.comment ? `"${r.comment}"` : '—'}
                        </p>
                      </td>
                      <td className="text-sm opacity-70">
                        {r.createdAt?.toDate ? format(r.createdAt.toDate(), 'dd/MM/yyyy HH:mm') : '-'}
                      </td>
                      <td>
                        <div className="rides-table__actions">
                          <button 
                            className="rides-table__action-btn" 
                            onClick={() => setSelectedReview(r)}
                            title="Xem chi tiết"
                          >
                            👁️
                          </button>
                          <button 
                            className="rides-table__action-btn text-danger-500" 
                            onClick={() => handleDeleteReview(r.id)}
                            title="Xóa đánh giá"
                          >
                            🗑️
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedReview && (
        <ReviewDetailModal
          review={selectedReview}
          onClose={() => setSelectedReview(null)}
          onDelete={handleDeleteReview}
          isDeleting={isDeleting}
        />
      )}

      {toast && (
        <div className={`rides-toast rides-toast--${toast.type}`}>
          {toast.type === 'success' ? '✅' : '❌'} {toast.message}
        </div>
      )}

      <style dangerouslySetInnerHTML={{ __html: `
        .truncate-2 {
          display: -webkit-box;
          -webkit-line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
      `}} />
    </section>
  );
};

export default ReviewsPage;
