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
  addDoc,
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
 * Realtime listener cho tất cả người dùng (Quản lý tài khoản)
 */
export function onAllUsers(callback, maxResults = 500) {
  const q = query(
    collection(db, 'users'),
    limit(maxResults)
  );
  return onSnapshot(q, (snapshot) => {
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(users);
  }, (error) => {
    console.error('Realtime all users error:', error);
  });
}

/**
 * Cập nhật trạng thái tài khoản (Block/Unblock)
 */
export async function updateUserStatus(userId, isBlocked) {
  try {
    await updateDoc(doc(db, 'users', userId), {
      isBlocked: isBlocked,
      updatedAt: new Date()
    });
    return { success: true };
  } catch (error) {
    console.error('Error updating user status:', error);
    return { success: false, error: error.message };
  }
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
 * Đồng bộ lại số chuyến đi của tất cả khách hàng
 */
export async function syncCustomerStats() {
  try {
    // 1. Lấy tất cả khách hàng
    const customersQuery = query(collection(db, 'users'), where('role', '==', 'customer'));
    const customersSnapshot = await getDocs(customersQuery);

    const results = [];

    for (const customerDoc of customersSnapshot.docs) {
      const customerId = customerDoc.id;

      // 2. Lấy tất cả chuyến đi của khách hàng này
      const tripsQuery = query(
        collection(db, 'trips'),
        where('customerId', '==', customerId)
      );

      const tripsSnapshot = await getDocs(tripsQuery);

      // Lọc các chuyến đã hoàn thành
      const completedTrips = tripsSnapshot.docs.filter(t => {
        const s = t.data().status;
        return s === 'completed' || s === 'Hoàn thành';
      });

      const totalTrips = completedTrips.length;

      // 3. Cập nhật lại vào bảng users
      await updateDoc(doc(db, 'users', customerId), {
        totalTrips: totalTrips
      });

      results.push({ name: customerDoc.data().name, totalTrips });
    }

    return { success: true, updatedCount: results.length };
  } catch (error) {
    console.error('Error syncing customer stats:', error);
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

/**
 * Lấy danh sách khiếu nại (Complaints)
 */
export async function getComplaints(statusFilter = null, maxResults = 100) {
  try {
    let q;
    if (statusFilter && statusFilter !== 'all') {
      q = query(
        collection(db, 'complaints'),
        where('status', '==', statusFilter),
        orderBy('createdAt', 'desc'),
        limit(maxResults)
      );
    } else {
      q = query(
        collection(db, 'complaints'),
        orderBy('createdAt', 'desc'),
        limit(maxResults)
      );
    }
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching complaints:', error);
    return [];
  }
}

/**
 * Realtime listener cho khiếu nại
 */
export function onComplaints(callback, statusFilter = null, maxResults = 100) {
  let q;
  if (statusFilter && statusFilter !== 'all') {
    q = query(
      collection(db, 'complaints'),
      where('status', '==', statusFilter),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
  } else {
    q = query(
      collection(db, 'complaints'),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
  }
  return onSnapshot(q, (snapshot) => {
    const complaints = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    callback(complaints);
  }, (error) => {
    console.error('Realtime complaints error:', error);
  });
}

/**
 * Cập nhật trạng thái khiếu nại
 */
export async function updateComplaintStatus(complaintId, status, adminNotes = '') {
  try {
    const updateData = { status };
    if (adminNotes) {
      updateData.adminNotes = adminNotes;
    }
    await updateDoc(doc(db, 'complaints', complaintId), updateData);
    return { success: true };
  } catch (error) {
    console.error('Error updating complaint status:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Lấy danh sách đánh giá (Reviews)
 */
export async function getReviews(maxResults = 100) {
  try {
    const q = query(
      collection(db, 'reviews'),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching reviews:', error);
    return [];
  }
}

/**
 * Realtime listener cho đánh giá
 * Kết hợp từ bộ sưu tập 'reviews' và 'notifications' (type: 'rating')
 */
export function onReviews(callback, maxResults = 100) {
  // 1. Listen to 'reviews' collection (thường là nguồn chính)
  const qReviews = query(
    collection(db, 'reviews'),
    orderBy('createdAt', 'desc'),
    limit(maxResults)
  );

  // 2. Listen to 'notifications' collection (fallback cho dữ liệu cũ/khác)
  // Bỏ orderBy ở đây để tránh lỗi "Missing Index" nếu chưa cấu hình composite index
  const qNotifs = query(
    collection(db, 'notifications'),
    where('type', '==', 'rating'),
    limit(maxResults)
  );

  let reviewsData = [];
  let notifsData = [];

  const emitMerged = () => {
    // Gộp và loại bỏ trùng lặp theo ID hoặc tripId
    const combined = [...reviewsData];
    const seenIds = new Set(reviewsData.map(r => r.id));
    const seenTripIds = new Set(reviewsData.map(r => r.tripId).filter(Boolean));

    notifsData.forEach(n => {
      if (!seenIds.has(n.id) && (!n.tripId || !seenTripIds.has(n.tripId))) {
        combined.push(n);
      }
    });

    // Sắp xếp lại theo thời gian giảm dần
    combined.sort((a, b) => {
      const timeA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.createdAt || 0);
      const timeB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.createdAt || 0);
      return timeB - timeA;
    });

    callback(combined.slice(0, maxResults));
  };

  const unsubReviews = onSnapshot(qReviews, (snapshot) => {
    reviewsData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    emitMerged();
  }, (err) => console.error("Error fetching reviews collection:", err));

  const unsubNotifs = onSnapshot(qNotifs, (snapshot) => {
    notifsData = snapshot.docs.map(doc => {
      const data = doc.data();

      // Ưu tiên lấy từ trường rating có sẵn, nếu không mới parse từ string
      let rating = data.rating;
      if (rating === undefined || rating === null) {
        const titleMatch = data.title?.match(/(\d+(\.\d+)?)/);
        const msgMatch = data.message?.match(/(\d+(\.\d+)?)\s*sao/);
        if (titleMatch) rating = parseFloat(titleMatch[1]);
        else if (msgMatch) rating = parseFloat(msgMatch[1]);
        else rating = 5;
      }

      // Ưu tiên lấy từ trường comment có sẵn, nếu không mới parse từ message
      let comment = data.comment;
      if (comment === undefined || comment === null) {
        const commentMatch = data.message?.match(/Nhận xét:\s*['"](.*)['"]/);
        if (commentMatch) comment = commentMatch[1];
        else comment = '';
      }

      return {
        id: doc.id,
        rating: rating,
        comment: comment,
        customerName: data.customerName || data.username || 'Khách hàng',
        username: data.username || data.customerName || 'Khách hàng',
        customerID: data.customerID || data.customerId || '',
        driverName: data.driverName || data.name || 'Tài xế',
        name: data.name || data.driverName || 'Tài xế',
        driverID: data.driverID || data.driverId || '',
        tripId: data.rideId || data.tripId || '',
        createdAt: data.createdAt,
        ...data
      };
    });
    emitMerged();
  }, (err) => {
    console.error("Error fetching notifications (ratings):", err);
    // Nếu lỗi index, vẫn gọi callback với dữ liệu từ reviewsData
    emitMerged();
  });

  return () => {
    unsubReviews();
    unsubNotifs();
  };
}

/**
 * Xóa đánh giá
 */
export async function deleteReview(reviewId) {
  try {
    // Thử xóa ở cả 2 collection (reviews và notifications)
    // Vì merge data nên ID có thể thuộc 1 trong 2
    const reviewRef = doc(db, 'reviews', reviewId);
    const notifRef = doc(db, 'notifications', reviewId);
    
    await Promise.allSettled([
      deleteDoc(reviewRef),
      deleteDoc(notifRef)
    ]);
    
    return { success: true };
  } catch (error) {
    console.error('Error deleting review:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Lấy danh sách đánh giá của một tài xế cụ thể
 */
export async function getDriverReviews(driverId, maxResults = 50) {
  try {
    const q = query(
      collection(db, 'reviews'),
      where('driverId', '==', driverId),
      orderBy('createdAt', 'desc'),
      limit(maxResults)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (error) {
    console.error('Error fetching driver reviews:', error);
    return [];
  }
}

/**
 * Realtime listener cho đánh giá của một tài xế cụ thể
 */
export function onDriverReviews(driverId, callback, maxResults = 50) {
  // 1. Listen to 'reviews' collection
  const qReviews = query(
    collection(db, 'reviews'),
    where('driverId', '==', driverId),
    limit(maxResults)
  );

  // 2. Listen to 'notifications' collection
  const qNotifs = query(
    collection(db, 'notifications'),
    where('driverId', '==', driverId),
    where('type', '==', 'rating'),
    limit(maxResults)
  );

  let reviewsData = [];
  let notifsData = [];

  const emitMerged = () => {
    const combined = [...reviewsData];
    const seenIds = new Set(reviewsData.map(r => r.id));
    const seenTripIds = new Set(reviewsData.map(r => r.tripId).filter(Boolean));

    notifsData.forEach(n => {
      if (!seenIds.has(n.id) && (!n.tripId || !seenTripIds.has(n.tripId))) {
        combined.push(n);
      }
    });

    combined.sort((a, b) => {
      const timeA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.createdAt || 0);
      const timeB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.createdAt || 0);
      return timeB - timeA;
    });

    callback(combined.slice(0, maxResults));
  };

  const unsubReviews = onSnapshot(qReviews, (snapshot) => {
    reviewsData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    emitMerged();
  }, (err) => console.error("Error driver reviews:", err));

  const unsubNotifs = onSnapshot(qNotifs, (snapshot) => {
    notifsData = snapshot.docs.map(doc => {
      const data = doc.data();

      // Ưu tiên lấy từ trường rating có sẵn, nếu không mới parse từ string
      let rating = data.rating;
      if (rating === undefined || rating === null) {
        const titleMatch = data.title?.match(/(\d+(\.\d+)?)/);
        const msgMatch = data.message?.match(/(\d+(\.\d+)?)\s*sao/);
        if (titleMatch) rating = parseFloat(titleMatch[1]);
        else if (msgMatch) rating = parseFloat(msgMatch[1]);
        else rating = 5;
      }

      // Ưu tiên lấy từ trường comment có sẵn, nếu không mới parse từ message
      let comment = data.comment;
      if (comment === undefined || comment === null) {
        const commentMatch = data.message?.match(/Nhận xét:\s*['"](.*)['"]/);
        if (commentMatch) comment = commentMatch[1];
        else comment = '';
      }

      return {
        id: doc.id,
        rating: rating,
        comment: comment,
        customerName: data.customerName || data.username || 'Khách hàng',
        username: data.username || data.customerName || 'Khách hàng',
        customerID: data.customerID || data.customerId || '',
        driverName: data.driverName || data.name || 'Tài xế',
        name: data.name || data.driverName || 'Tài xế',
        driverID: data.driverID || data.driverId || '',
        tripId: data.rideId || data.tripId || '',
        createdAt: data.createdAt,
        ...data
      };
    });
    emitMerged();
  }, (err) => {
    console.error("Error driver notifs:", err);
    emitMerged();
  });

  return () => {
    unsubReviews();
    unsubNotifs();
  };
}

/**
 * Gửi đánh giá mới (Chỉ dành cho Khách hàng đánh giá Tài xế)
 * Standardized fields: customerID, username, driverID, name
 */
export async function submitReview(reviewData) {
  try {
    const { 
      customerID, 
      username, 
      driverID, 
      name, 
      rating, 
      comment, 
      tripId 
    } = reviewData;

    if (!customerID || !driverID || !rating) {
      throw new Error('Thiếu thông tin customerID, driverID hoặc rating');
    }

    const newReview = {
      customerID,
      customerId: customerID, // Backward compatibility
      username: username || 'Khách hàng',
      customerName: username || 'Khách hàng', // Backward compatibility
      driverID,
      driverId: driverID, // Backward compatibility
      name: name || 'Tài xế',
      driverName: name || 'Tài xế', // Backward compatibility
      rating: parseFloat(rating),
      comment: comment || '',
      tripId: tripId || '',
      createdAt: new Date(),
      type: 'rating'
    };

    const docRef = await addDoc(collection(db, 'reviews'), newReview);
    return { success: true, id: docRef.id };
  } catch (error) {
    console.error('Error submitting review:', error);
    return { success: false, error: error.message };
  }
}
