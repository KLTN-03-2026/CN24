import {
  collection,
  query,
  orderBy,
  limit,
  getDocs,
  where,
  onSnapshot,
  getCountFromServer,
  doc,
  deleteDoc,
  updateDoc,
} from 'firebase/firestore';
import { db } from './firebase';

/**
 * Lấy danh sách users theo role
 * Collections: users
 * Fields: role ('customer' | 'driver'), name, email, phone, isOnline, rating, totalTrips, earnings, createdAt
 */
export async function getUsers(role = null, maxResults = 50) {
  try {
    let q;
    if (role) {
      q = query(
        collection(db, 'users'),
        where('role', '==', role),
        limit(maxResults)
      );
    } else {
      q = query(collection(db, 'users'), limit(maxResults));
    }
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching users:', error);
    return [];
  }
}

/**
 * Đếm tổng số users theo role
 */
export async function countUsers(role = null) {
  try {
    let q;
    if (role) {
      q = query(collection(db, 'users'), where('role', '==', role));
    } else {
      q = query(collection(db, 'users'));
    }
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  } catch (error) {
    console.error('Error counting users:', error);
    return 0;
  }
}

/**
 * Đếm tài xế đang online
 */
export async function countOnlineDrivers() {
  try {
    const q = query(
      collection(db, 'users'),
      where('role', '==', 'driver'),
      where('isOnline', '==', true)
    );
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  } catch (error) {
    console.error('Error counting online drivers:', error);
    return 0;
  }
}

/**
 * Lấy chuyến đi gần đây
 * Collection: trips
 * Fields: customerId, customerName, driverId, driverName, pickupAddress, destinationAddress, fare, distance, status, paymentMethod, createdAt, completedAt
 */
export async function getRecentTrips(maxResults = 10) {
  try {
    const q = query(
      collection(db, 'trips'),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching trips:', error);
    return [];
  }
}

/**
 * Đếm tổng số trips
 */
export async function countTrips(status = null) {
  try {
    let q;
    if (status) {
      q = query(collection(db, 'trips'), where('status', '==', status));
    } else {
      q = query(collection(db, 'trips'));
    }
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  } catch (error) {
    console.error('Error counting trips:', error);
    return 0;
  }
}

/**
 * Lấy ride requests gần đây
 * Collection: ride_requests  
 * Fields: customerId, customerName, pickupAddress, destinationAddress, driverId, driverName, fare, distanceInKm, status, paymentMethod, createdAt
 */
export async function getRecentRideRequests(maxResults = 10) {
  try {
    const q = query(
      collection(db, 'ride_requests'),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching ride requests:', error);
    return [];
  }
}

/**
 * Đếm ride requests theo status
 */
export async function countRideRequests(status = null) {
  try {
    let q;
    if (status) {
      q = query(collection(db, 'ride_requests'), where('status', '==', status));
    } else {
      q = query(collection(db, 'ride_requests'));
    }
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  } catch (error) {
    console.error('Error counting ride requests:', error);
    return 0;
  }
}

/**
 * Tính tổng doanh thu từ trips completed
 */
export async function getTotalRevenue() {
  try {
    const q = query(
      collection(db, 'trips'),
      where('status', '==', 'completed')
    );
    const snapshot = await getDocs(q);
    let total = 0;
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      total += data.fare || 0;
    });
    return total;
  } catch (error) {
    console.error('Error calculating revenue:', error);
    return 0;
  }
}

/**
 * Realtime listener cho trips mới
 */
export function onRecentTrips(callback, maxResults = 10) {
  const q = query(
    collection(db, 'trips'),
    orderBy('createdAt', 'desc'),
    limit(maxResults)
  );
  return onSnapshot(q, (snapshot) => {
    const trips = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(trips);
  }, (error) => {
    console.error('Realtime trips error:', error);
  });
}

/**
 * Realtime listener cho ride_requests mới
 */
export function onRecentRideRequests(callback, maxResults = 10) {
  const q = query(
    collection(db, 'ride_requests'),
    orderBy('createdAt', 'desc'),
    limit(maxResults)
  );
  return onSnapshot(q, (snapshot) => {
    const requests = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(requests);
  }, (error) => {
    console.error('Realtime ride requests error:', error);
  });
}

/**
 * Realtime listener cho users (drivers online)
 */
export function onOnlineDrivers(callback) {
  const q = query(
    collection(db, 'users'),
    where('role', '==', 'driver'),
    where('isOnline', '==', true)
  );
  return onSnapshot(q, (snapshot) => {
    const drivers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(drivers);
  }, (error) => {
    console.error('Realtime drivers error:', error);
  });
}

/**
 * Lấy tất cả chuyến đi, có thể lọc theo status
 */
export async function getAllTrips(statusFilter = null, maxResults = 100) {
  try {
    let q;
    if (statusFilter && statusFilter !== 'all') {
      q = query(
        collection(db, 'trips'),
        where('status', '==', statusFilter),
        orderBy('createdAt', 'desc'),
        limit(maxResults)
      );
    } else {
      q = query(
        collection(db, 'trips'),
        orderBy('createdAt', 'desc'),
        limit(maxResults)
      );
    }
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching all trips:', error);
    return [];
  }
}

/**
 * Realtime listener cho tất cả trips (có filter status)
 */
export function onAllTrips(callback, statusFilter = null, maxResults = 100) {
  let q;
  if (statusFilter && statusFilter !== 'all') {
    q = query(
      collection(db, 'trips'),
      where('status', '==', statusFilter),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
  } else {
    q = query(
      collection(db, 'trips'),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
  }
  return onSnapshot(q, (snapshot) => {
    const trips = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(trips);
  }, (error) => {
    console.error('Realtime all trips error:', error);
  });
}

/**
 * Xóa chuyến đi theo ID
 */
export async function deleteTrip(tripId) {
  try {
    await deleteDoc(doc(db, 'trips', tripId));
    return { success: true };
  } catch (error) {
    console.error('Error deleting trip:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Realtime listener cho tất cả tài xế
 */
export function onAllDrivers(callback, maxResults = 200) {
  const q = query(
    collection(db, 'users'),
    where('role', '==', 'driver'),
    limit(maxResults)
  );
  return onSnapshot(q, (snapshot) => {
    const drivers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(drivers);
  }, (error) => {
    console.error('Realtime all drivers error:', error);
  });
}

/**
 * Realtime listener cho tất cả khách hàng
 */
export function onAllCustomers(callback, maxResults = 200) {
  const q = query(
    collection(db, 'users'),
    where('role', '==', 'customer'),
    limit(maxResults)
  );
  return onSnapshot(q, (snapshot) => {
    const customers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(customers);
  }, (error) => {
    console.error('Realtime all customers error:', error);
  });
}

/**
 * Đồng bộ lại số chuyến đi và thu nhập của tất cả tài xế
 */
export async function syncDriverStats() {
  try {
    // 1. Lấy tất cả tài xế
    const driversQuery = query(collection(db, 'users'), where('role', '==', 'driver'));
    const driversSnapshot = await getDocs(driversQuery);
    
    const results = [];
    
    for (const driverDoc of driversSnapshot.docs) {
      const driverId = driverDoc.id;
      
      // 2. Lấy tất cả chuyến đi của tài xế này (không lọc status ở query để tránh lỗi mismatch string)
      const tripsQuery = query(
        collection(db, 'trips'), 
        where('driverId', '==', driverId)
      );
      
      const tripsSnapshot = await getDocs(tripsQuery);
      
      // Lọc các chuyến đã hoàn thành (chấp nhận cả 'completed' và 'Hoàn thành')
      const completedTrips = tripsSnapshot.docs.filter(t => {
        const s = t.data().status;
        return s === 'completed' || s === 'Hoàn thành';
      });

      const totalTrips = completedTrips.length;
      
      // 3. Tính tổng thu nhập
      let earnings = 0;
      completedTrips.forEach(t => {
        earnings += (t.data().fare || 0);
      });
      
      // 4. Cập nhật lại vào bảng users
      await updateDoc(doc(db, 'users', driverId), {
        totalTrips: totalTrips,
        earnings: earnings
      });
      
      results.push({ name: driverDoc.data().name, totalTrips, earnings });
    }
    
    return { success: true, updatedCount: results.length };
  } catch (error) {
    console.error('Error syncing driver stats:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Realtime listener cho vị trí tài xế
 */
export function onDriverLocations(callback) {
  const q = query(collection(db, 'driver_locations'));
  return onSnapshot(q, (snapshot) => {
    const locations = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(locations);
  }, (error) => {
    console.error('Realtime driver locations error:', error);
  });
}
