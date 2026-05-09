
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, limit, query } from 'firebase/firestore';

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

async function deepProbe() {
  console.log("--- Deep Probing one trip ---");
  const q = query(collection(db, 'trips'), limit(1));
  const snap = await getDocs(q);
  if (!snap.empty) {
    console.log("Trip data:", JSON.stringify(snap.docs[0].data(), null, 2));
  } else {
    console.log("No trips found.");
  }
}

deepProbe();
