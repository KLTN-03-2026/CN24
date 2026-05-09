import { Timestamp } from 'firebase/firestore';

// ============================================================
// CẤU HÌNH - Đổi tên field ở đây nếu Firestore schema khác
// ============================================================

/** Lấy số tiền của chuyến đi, ưu tiên fare > totalPrice > price */
export const getRideAmount = (ride) => ride.fare || ride.totalPrice || ride.price || 0;

/** Lấy ngày của chuyến đi, ưu tiên completedAt > createdAt */
export const getRideDate = (ride) => ride.completedAt || ride.createdAt;

/** Tên collection — đổi ở đây nếu project dùng tên khác */
export const COLLECTIONS = {
  trips: 'trips',        // hoặc 'rides', 'ride_requests'
  users: 'users',        // hoặc 'customers'
};

// Các status được coi là "hoàn thành"
export const COMPLETED_STATUSES = ['completed', 'Hoàn thành'];
// Các status được coi là "đã hủy"
export const CANCELLED_STATUSES = ['cancelled', 'Đã hủy'];
// Các status được coi là "đang xử lý"
export const PROCESSING_STATUSES = ['pending', 'accepted', 'in_progress', 'searching_driver', 'driver_assigned', 'on_the_way', 'ongoing'];

// ============================================================
// CONVERT TIMESTAMP
// ============================================================

/** Chuyển đổi Firestore Timestamp / Date / string → JS Date */
export function toJsDate(timestamp) {
  if (!timestamp) return null;
  if (timestamp.seconds != null) {
    return new Date(timestamp.seconds * 1000);
  }
  if (timestamp instanceof Date) return timestamp;
  if (typeof timestamp === 'string' || typeof timestamp === 'number') {
    return new Date(timestamp);
  }
  return null;
}

// ============================================================
// TIME RANGE
// ============================================================

/**
 * Tính khoảng thời gian hiện tại và kỳ trước dựa trên range.
 * @param {'week'|'month'|'year'} range
 * @returns {{ start: Date, end: Date, prevStart: Date, prevEnd: Date }}
 */
export function getTimeRange(range) {
  const now = new Date();
  let start, end, prevStart, prevEnd;

  if (range === 'week') {
    // Tuần này: từ thứ 2 đầu tuần đến hiện tại
    const dayOfWeek = now.getDay(); // 0=CN, 1=T2, ...
    const diffToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

    start = new Date(now);
    start.setDate(now.getDate() - diffToMonday);
    start.setHours(0, 0, 0, 0);

    end = new Date(now);
    end.setHours(23, 59, 59, 999);

    // Tuần trước
    prevStart = new Date(start);
    prevStart.setDate(prevStart.getDate() - 7);

    prevEnd = new Date(start);
    prevEnd.setMilliseconds(-1); // cuối ngày CN tuần trước

  } else if (range === 'month') {
    // Tháng này: ngày 1 đến hiện tại
    start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);

    end = new Date(now);
    end.setHours(23, 59, 59, 999);

    // Tháng trước
    prevStart = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
    prevEnd = new Date(start);
    prevEnd.setMilliseconds(-1);

  } else {
    // Năm nay: 1/1 đến hiện tại
    start = new Date(now.getFullYear(), 0, 1, 0, 0, 0, 0);

    end = new Date(now);
    end.setHours(23, 59, 59, 999);

    // Năm trước
    prevStart = new Date(now.getFullYear() - 1, 0, 1, 0, 0, 0, 0);
    prevEnd = new Date(now.getFullYear(), 0, 1, 0, 0, 0, 0);
    prevEnd.setMilliseconds(-1);
  }

  return { start, end, prevStart, prevEnd };
}

/** Chuyển Date → Firestore Timestamp */
export function toTimestamp(date) {
  return Timestamp.fromDate(date);
}

// ============================================================
// GROWTH RATE
// ============================================================

/**
 * Tính tỉ lệ tăng trưởng giữa kỳ hiện tại và kỳ trước.
 * @returns {{ text: string, value: number, isPositive: boolean }}
 */
export function calcGrowthRate(current, previous) {
  if (previous === 0 && current === 0) {
    return { text: '0%', value: 0, isPositive: true };
  }
  if (previous === 0) {
    return { text: '+100%', value: 100, isPositive: true };
  }
  const rate = ((current - previous) / previous) * 100;
  const rounded = Math.round(rate * 10) / 10; // 1 decimal
  const sign = rounded >= 0 ? '+' : '';
  return {
    text: `${sign}${rounded}%`,
    value: rounded,
    isPositive: rounded >= 0,
  };
}

// ============================================================
// CHART DATA GROUPING
// ============================================================

/**
 * Group doanh thu theo ngày trong tuần (T2 → CN).
 * Trả về mảng 7 phần tử.
 */
export function groupRevenueByWeekDay(trips, startDate) {
  const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  const data = new Array(7).fill(0);

  trips.forEach(trip => {
    if (!COMPLETED_STATUSES.includes(trip.status)) return;
    const date = toJsDate(getRideDate(trip));
    if (!date) return;

    // Tính index ngày trong tuần (0=T2, 6=CN)
    const dayOfWeek = date.getDay(); // 0=CN
    const idx = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    data[idx] += getRideAmount(trip);
  });

  return labels.map((label, i) => ({ label, value: data[i] }));
}

/**
 * Group doanh thu theo ngày trong tháng.
 * Trả về mảng N phần tử (N = số ngày trong tháng đến hiện tại).
 */
export function groupRevenueByDayOfMonth(trips, startDate, endDate) {
  const daysInPeriod = endDate.getDate(); // ngày hiện tại = số ngày cần hiển thị
  const data = new Array(daysInPeriod).fill(0);
  const labels = [];

  for (let i = 0; i < daysInPeriod; i++) {
    labels.push(`${i + 1}`);
  }

  trips.forEach(trip => {
    if (!COMPLETED_STATUSES.includes(trip.status)) return;
    const date = toJsDate(getRideDate(trip));
    if (!date) return;
    const day = date.getDate() - 1; // 0-indexed
    if (day >= 0 && day < daysInPeriod) {
      data[day] += getRideAmount(trip);
    }
  });

  return labels.map((label, i) => ({ label, value: data[i] }));
}

/**
 * Group doanh thu theo tháng trong năm.
 * Trả về mảng 12 phần tử.
 */
export function groupRevenueByMonth(trips) {
  const labels = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
  const data = new Array(12).fill(0);

  trips.forEach(trip => {
    if (!COMPLETED_STATUSES.includes(trip.status)) return;
    const date = toJsDate(getRideDate(trip));
    if (!date) return;
    const month = date.getMonth(); // 0-11
    data[month] += getRideAmount(trip);
  });

  return labels.map((label, i) => ({ label, value: data[i] }));
}

/**
 * Tạo chart data dựa trên time range.
 */
export function buildChartData(trips, timeRange, startDate, endDate) {
  switch (timeRange) {
    case 'week':
      return groupRevenueByWeekDay(trips, startDate);
    case 'month':
      return groupRevenueByDayOfMonth(trips, startDate, endDate);
    case 'year':
      return groupRevenueByMonth(trips);
    default:
      return [];
  }
}

// ============================================================
// STATUS RATES
// ============================================================

/**
 * Tính tỉ lệ phần trăm trạng thái chuyến đi.
 * @returns {{ completed: number, cancelled: number, processing: number }}
 */
export function calcStatusRates(trips) {
  if (!trips || trips.length === 0) {
    return { completed: 0, cancelled: 0, processing: 0 };
  }

  let completedCount = 0;
  let cancelledCount = 0;
  let processingCount = 0;

  trips.forEach(trip => {
    if (COMPLETED_STATUSES.includes(trip.status)) {
      completedCount++;
    } else if (CANCELLED_STATUSES.includes(trip.status)) {
      cancelledCount++;
    } else {
      processingCount++;
    }
  });

  const total = trips.length;
  return {
    completed: Math.round((completedCount / total) * 100),
    cancelled: Math.round((cancelledCount / total) * 100),
    processing: Math.round((processingCount / total) * 100),
  };
}

// ============================================================
// FORMAT TIỀN CHO CHART
// ============================================================

/**
 * Format tiền cho chart tooltip: 584K, 1.2M, 2.5B
 */
export function formatChartCurrency(amount) {
  if (amount == null || amount === 0) return '0';
  if (amount >= 1_000_000_000) return `${(amount / 1_000_000_000).toFixed(1)}B`;
  if (amount >= 1_000_000) return `${(amount / 1_000_000).toFixed(1)}M`;
  if (amount >= 1_000) return `${Math.round(amount / 1_000)}K`;
  return amount.toLocaleString('vi-VN');
}
