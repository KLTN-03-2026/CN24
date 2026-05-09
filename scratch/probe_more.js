
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, limit, query, where } from 'firebase/firestore';

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

async function probeMore() {
  // Check trips for rating fields
  console.log("--- Probing 'trips' collection ---");
  const tripsQ = query(collection(db, 'trips'), limit(10));
  const tripsSnap = await getDocs(tripsQ);
  tripsSnap.docs.forEach(doc => {
    const data = doc.data();
    if (data.rating || data.comment || data.feedback) {
      console.log(`Trip ${doc.id} HAS RATING:`, JSON.stringify(data, null, 2));
    }
  });

  // Check more collection names
  const collections = ['user_ratings', 'driver_feedback', 'trip_feedback', 'stars', 'app_reviews', 'ride_reviews'];
  for (const name of collections) {
    try {
      const q = query(collection(db, name), limit(1));
      const snap = await getDocs(q);
      if (!snap.empty) {
        console.log(`Collection '${name}' HAS DATA:`, JSON.stringify(snap.docs[0].data(), null, 2));
      }
    } catch (e) {}
  }
}

probeMore();
