
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc } from 'firebase/firestore';

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

async function probeSpecificTrip() {
  const tripId = "1777531826543";
  const tripRef = doc(db, 'trips', tripId);
  const snap = await getDoc(tripRef);
  if (snap.exists()) {
    console.log("Trip 1777531826543 data:", JSON.stringify(snap.data(), null, 2));
  } else {
    console.log("Trip 1777531826543 not found in 'trips'");
    // Try ride_requests
    const reqRef = doc(db, 'ride_requests', tripId);
    const snap2 = await getDoc(reqRef);
    if (snap2.exists()) {
       console.log("Trip 1777531826543 found in 'ride_requests':", JSON.stringify(snap2.data(), null, 2));
    }
  }
}

probeSpecificTrip();
