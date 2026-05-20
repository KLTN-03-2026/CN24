const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const serviceAccount = require('e:/hoc_lap_trinh/laptrinhungdungdidong/ride-now-khoaluan-firebase-adminsdk.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkDrivers() {
  console.log('--- ALL DRIVERS ---');
  const driversSnapshot = await db.collection('users')
    .where('role', '==', 'driver')
    .get();
    
  console.log(`Found ${driversSnapshot.size} driver(s) in users collection:`);
  driversSnapshot.docs.forEach(doc => {
    const data = doc.data();
    console.log(`Driver ID: ${doc.id}`);
    console.log(`  Name: ${data.name}`);
    console.log(`  isOnline: ${data.isOnline} (type: ${typeof data.isOnline})`);
    console.log(`  isAvailable: ${data.isAvailable} (type: ${typeof data.isAvailable})`);
    console.log(`  Phone: ${data.phone}`);
    console.log('------------------------');
  });

  console.log('\n--- ACTIVE RIDE REQUESTS ---');
  const ridesSnapshot = await db.collection('ride_requests').get();
  console.log(`Found ${ridesSnapshot.size} total ride requests.`);
  ridesSnapshot.docs.forEach(doc => {
    const data = doc.data();
    console.log(`Ride ID: ${doc.id}`);
    console.log(`  Customer: ${data.customerName}`);
    console.log(`  Status: ${data.status}`);
    console.log(`  CreatedAt: ${data.createdAt ? data.createdAt.toDate() : 'null'}`);
    console.log('------------------------');
  });
}

checkDrivers().catch(console.error);
