import { useState, useEffect, useCallback } from 'react';
import {
  collection,
  query,
  where,
  getDocs,
  orderBy,
} from 'firebase/firestore';
import { db } from '../firebase';
import {
  COLLECTIONS,
  COMPLETED_STATUSES,
  getTimeRange,
  toTimestamp,
  getRideAmount,
  calcGrowthRate,
  buildChartData,
  calcStatusRates,
} from '../utils/analyticsHelpers';

/**
 * Custom hook lấy dữ liệu analytics từ Firestore.
 *
 * @param {'week'|'month'|'year'} timeRange - Khoảng thời gian lọc
 * @returns {{ stats, chartData, statusRates, loading, error, refetch }}
 */
export default function useRideAnalytics(timeRange) {
  const [stats, setStats] = useState({
    totalRevenue: 0,
    totalTrips: 0,
    newUsers: 0,
    revenueGrowth: { text: '0%', value: 0, isPositive: true },
    tripsGrowth: { text: '0%', value: 0, isPositive: true },
    usersGrowth: { text: '0%', value: 0, isPositive: true },
  });
  const [chartData, setChartData] = useState([]);
  const [statusRates, setStatusRates] = useState({ completed: 0, cancelled: 0, processing: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const { start, end, prevStart, prevEnd } = getTimeRange(timeRange);

      const startTs = toTimestamp(start);
      const endTs = toTimestamp(end);
      const prevStartTs = toTimestamp(prevStart);
      const prevEndTs = toTimestamp(prevEnd);

      // ──────────────────────────────────────────────
      // 1. Query trips trong kỳ hiện tại
      // ──────────────────────────────────────────────
      const tripsRef = collection(db, COLLECTIONS.trips);
      const currentTripsQuery = query(
        tripsRef,
        where('createdAt', '>=', startTs),
        where('createdAt', '<=', endTs),
        orderBy('createdAt', 'desc')
      );

      const currentTripsSnap = await getDocs(currentTripsQuery);
      const currentTrips = currentTripsSnap.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      // ──────────────────────────────────────────────
      // 2. Query trips kỳ trước (để tính growth)
      // ──────────────────────────────────────────────
      const prevTripsQuery = query(
        tripsRef,
        where('createdAt', '>=', prevStartTs),
        where('createdAt', '<=', prevEndTs),
        orderBy('createdAt', 'desc')
      );

      const prevTripsSnap = await getDocs(prevTripsQuery);
      const prevTrips = prevTripsSnap.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      // ──────────────────────────────────────────────
      // 3. Query users mới kỳ hiện tại
      // ──────────────────────────────────────────────
      const usersRef = collection(db, COLLECTIONS.users);
      const newUsersQuery = query(
        usersRef,
        where('createdAt', '>=', startTs),
        where('createdAt', '<=', endTs)
      );

      const newUsersSnap = await getDocs(newUsersQuery);
      const newUsersCount = newUsersSnap.size;

      // ──────────────────────────────────────────────
      // 4. Query users mới kỳ trước
      // ──────────────────────────────────────────────
      const prevUsersQuery = query(
        usersRef,
        where('createdAt', '>=', prevStartTs),
        where('createdAt', '<=', prevEndTs)
      );

      const prevUsersSnap = await getDocs(prevUsersQuery);
      const prevUsersCount = prevUsersSnap.size;

      // ──────────────────────────────────────────────
      // 5. Tính toán stats
      // ──────────────────────────────────────────────

      // Doanh thu = tổng tiền chuyến hoàn thành trong kỳ
      const currentRevenue = currentTrips
        .filter(t => COMPLETED_STATUSES.includes(t.status))
        .reduce((sum, t) => sum + getRideAmount(t), 0);

      const prevRevenue = prevTrips
        .filter(t => COMPLETED_STATUSES.includes(t.status))
        .reduce((sum, t) => sum + getRideAmount(t), 0);

      // Tổng chuyến
      const currentTripsCount = currentTrips.length;
      const prevTripsCount = prevTrips.length;

      // Growth rates
      const revenueGrowth = calcGrowthRate(currentRevenue, prevRevenue);
      const tripsGrowth = calcGrowthRate(currentTripsCount, prevTripsCount);
      const usersGrowth = calcGrowthRate(newUsersCount, prevUsersCount);

      setStats({
        totalRevenue: currentRevenue,
        totalTrips: currentTripsCount,
        newUsers: newUsersCount,
        revenueGrowth,
        tripsGrowth,
        usersGrowth,
      });

      // ──────────────────────────────────────────────
      // 6. Build chart data
      // ──────────────────────────────────────────────
      const chart = buildChartData(currentTrips, timeRange, start, end);
      setChartData(chart);

      // ──────────────────────────────────────────────
      // 7. Tính status rates
      // ──────────────────────────────────────────────
      const rates = calcStatusRates(currentTrips);
      setStatusRates(rates);

    } catch (err) {
      console.error('Error fetching analytics:', err);
      setError(err.message || 'Lỗi khi tải dữ liệu analytics');
    } finally {
      setLoading(false);
    }
  }, [timeRange]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  return {
    stats,
    chartData,
    statusRates,
    loading,
    error,
    refetch: fetchAnalytics,
  };
}
