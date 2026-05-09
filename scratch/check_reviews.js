
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

async function checkCollections() {
  console.log("--- Checking 'reviews' collection ---");
  const reviewsSnap = await getDocs(query(collection(db, 'reviews'), limit(5)));
  console.log(`Found ${reviewsSnap.size} docs in 'reviews'`);
  reviewsSnap.docs.forEach(doc => console.log(doc.id, doc.data()));

  console.log("\n--- Checking 'notifications' collection with type 'rating' ---");
  const notifSnap = await getDocs(query(collection(db, 'notifications'), where('type', '==', 'rating'), limit(5)));
  console.log(`Found ${notifSnap.size} docs in 'notifications' with type 'rating'`);
  notifSnap.docs.forEach(doc => console.log(doc.id, doc.data()));
}

checkCollections();
