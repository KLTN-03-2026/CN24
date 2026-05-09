
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, query, where } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyBVikoj4G4CKrlNlCFqPwgywZd6UBgG1Po",
  authDomain: "ridenow-app-3aa76.firebaseapp.com",
  projectId: "ridenow-app-3aa76",
  storageBucket: "ridenow-app-3aa76.firebasestorage.app",
  messagingSenderId: "1072950734327",
  appId: "1:1072950734327:web:7dbbc200368892580492f2",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function findByRideId() {
  const rideId = "1777531826543"; // From the notification sample
  const collections = ['reviews', 'ratings', 'user_ratings', 'driver_ratings', 'trip_reviews', 'feedback', 'comments', 'notifications', 'trips'];
  
  for (const name of collections) {
    try {
      const q = query(collection(db, name), where('rideId', '==', rideId));
      const snap = await getDocs(q);
      if (!snap.empty) {
        console.log(`Found in '${name}':`, JSON.stringify(snap.docs[0].data(), null, 2));
      }
      
      // Also try tripId
      const q2 = query(collection(db, name), where('tripId', '==', rideId));
      const snap2 = await getDocs(q2);
      if (!snap2.empty) {
        console.log(`Found in '${name}' (via tripId):`, JSON.stringify(snap2.docs[0].data(), null, 2));
      }
    } catch (e) {}
  }
}

findByRideId();
