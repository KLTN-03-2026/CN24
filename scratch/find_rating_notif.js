
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

async function findRatingNotif() {
  console.log("--- Searching for rating notifications ---");
  const q = query(collection(db, 'notifications'));
  const snap = await getDocs(q);
  snap.docs.forEach(doc => {
    const data = doc.data();
    if (data.rating !== undefined || data.message?.includes('đánh giá')) {
      console.log(`Notif ${doc.id}:`, JSON.stringify(data, null, 2));
    }
  });
}

findRatingNotif();
