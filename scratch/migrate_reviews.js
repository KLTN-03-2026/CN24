const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Path to your service account key
const serviceAccount = require('e:/hoc_lap_trinh/laptrinhungdungdidong/ride-now-khoaluan-firebase-adminsdk.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function migrateReviews() {
  console.log('Starting migration of reviews from trips to reviews collection...');
  
  const tripsSnapshot = await db.collection('trips')
    .where('rating', '>', 0)
    .get();
    
  console.log(`Found ${tripsSnapshot.size} trips with ratings.`);
  
  let migratedCount = 0;
  
  for (const tripDoc of tripsSnapshot.docs) {
    const tripData = tripDoc.data();
    const rideId = tripDoc.id;
    const reviewId = `rev_${rideId}`;
    
    // Check if review already exists
    const reviewRef = db.collection('reviews').doc(reviewId);
    const reviewSnap = await reviewRef.get();
    
    if (!reviewSnap.exists) {
      await reviewRef.set({
        id: reviewId,
        tripId: rideId,
        customerId: tripData.customerId || '',
        customerID: tripData.customerId || '', // Standardized field
        customerName: tripData.customerName || 'Khách hàng',
        username: tripData.customerName || 'Khách hàng', // Standardized field
        driverId: tripData.driverId || '',
        driverID: tripData.driverId || '',     // Standardized field
        driverName: tripData.driverName || 'Tài xế',
        name: tripData.driverName || 'Tài xế',          // Standardized field
        rating: tripData.rating,
        comment: tripData.feedback || '',
        createdAt: tripData.completedAt || tripData.createdAt || new Date(),
      });
      migratedCount++;
    }
  }

  // 2. Scan and update existing driver notifications
  console.log('Scanning notif_rating notifications...');
  const notifsSnapshot = await db.collection('notifications')
    .where('id', '>=', 'notif_rating_')
    .where('id', '<=', 'notif_rating_\uf8ff')
    .get();

  console.log(`Found ${notifsSnapshot.size} rating notifications.`);
  let notifsUpdated = 0;

  for (const notifDoc of notifsSnapshot.docs) {
    const notifData = notifDoc.data();
    const rideId = notifData.rideId;
    
    if (rideId) {
      // Find trip data to get missing fields
      const tripDoc = await db.collection('trips').doc(rideId).get();
      if (tripDoc.exists) {
        const tripData = tripDoc.data();
        
        // Extract rating and comment from message if missing
        let rating = notifData.rating;
        if (!rating) {
          const match = notifData.title?.match(/(\d+(\.\d+)?)/);
          if (match) rating = parseFloat(match[1]);
        }
        
        let comment = notifData.comment;
        if (!comment) {
          const match = notifData.message?.match(/Nhận xét:\s*['"](.*)['"]/);
          if (match) comment = match[1];
          else comment = tripData.feedback || '';
        }

        await notifDoc.ref.update({
          customerId: notifData.customerId || tripData.customerId || '',
          customerName: notifData.customerName || tripData.customerName || 'Khách hàng',
          username: notifData.customerName || tripData.customerName || 'Khách hàng', // Consistency
          driverId: notifData.driverId || tripData.driverId || '',
          driverID: notifData.driverId || tripData.driverId || '', // Consistency
          driverName: notifData.driverName || tripData.driverName || 'Tài xế',
          name: notifData.driverName || tripData.driverName || 'Tài xế',         // Consistency
          rating: rating || tripData.rating || 5,
          comment: comment,
          type: 'info' // Changed to info so drivers don't see "Rate Now"
        });
        notifsUpdated++;
      }
    }
  }

  console.log(`Migration completed. Migrated ${migratedCount} reviews and updated ${notifsUpdated} notifications.`);
}

migrateReviews().catch(console.error);
