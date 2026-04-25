
import { db } from './src/firebase.js';
import { collection, query, where, getDocs } from 'firebase/firestore';

async function checkDrivers() {
  const q = query(collection(db, 'users'), where('role', '==', 'driver'));
  const snapshot = await getDocs(q);
  const drivers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  console.log('Total Drivers:', drivers.length);
  drivers.forEach(d => {
    console.log(`Driver: ${d.name}, Online: ${d.isOnline}, Lat: ${d.lat || d.latitude}, Lng: ${d.lng || d.longitude}, Status: ${d.status}`);
  });
}

checkDrivers();
