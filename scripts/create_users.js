const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const auth = admin.auth();
const db = admin.firestore();

const users = [
  { email: 'admin@test.com', password: 'test123', role: 'superAdmin', displayName: 'Admin User' },
  { email: 'owner@test.com', password: 'test123', role: 'restaurantOwner', displayName: 'Restaurant Owner' },
  { email: 'cashier@test.com', password: 'test123', role: 'cashier', displayName: 'Cashier User' },
  { email: 'driver@test.com', password: 'test123', role: 'driver', displayName: 'Driver User' },
  { email: 'user@test.com', password: 'test123', role: 'customer', displayName: 'Test Customer' },
];

async function run() {
  for (const u of users) {
    try {
      await auth.createUser({ email: u.email, password: u.password, displayName: u.displayName });
      console.log(`Auth created: ${u.email}`);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log(`Already exists: ${u.email}`);
      } else {
        console.error(`Failed ${u.email}:`, e.message);
        continue;
      }
    }
    const docId = u.email.replace(/[@.]/g, '_');
    await db.collection('users').doc(docId).set({
      email: u.email,
      role: u.role,
      displayName: u.displayName,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Firestore doc: ${docId}`);
  }
  console.log('Done!');
}

run().catch(console.error);
