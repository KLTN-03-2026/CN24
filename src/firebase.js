import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyBVikoj4G4CKrlNlCFqPwgywZd6UBgG1Po",
  authDomain: "ridenow-app-3aa76.firebaseapp.com",
  projectId: "ridenow-app-3aa76",
  storageBucket: "ridenow-app-3aa76.firebasestorage.app",
  messagingSenderId: "1072950734327",
  appId: "1:1072950734327:web:7dbbc200368892580492f2",
  measurementId: "G-R9YTRDSNLL"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
export default app;
