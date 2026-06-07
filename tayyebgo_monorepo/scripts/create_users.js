const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const auth = admin.auth();

const users = [
  { email: 'admin@test.com', password: 'test123', role: 'superAdmin', displayName: 'Admin' },
  { email: 'owner@test.com', password: 'test123', role: 'restaurantOwner', displayName: 'Owner' },
  { email: 'cashier@test.com', password: 'test123', role: 'cashier', displayName: 'Cashier' },
  { email: 'driver@test.com', password: 'test123', role: 'driver', displayName: 'Driver' },
  { email: 'customer@test.com', password: 'test123', role: 'customer', displayName: 'Customer' },
];

async function main() {
  for (const u of users) {
    try {
      let uid;
      try {
        const existing = await auth.getUserByEmail(u.email);
        uid = existing.uid;
        console.log(`EXISTS ${u.email} - updating role`);
      } catch {
        const created = await auth.createUser({
          email: u.email,
          password: u.password,
          displayName: u.displayName,
        });
        uid = created.uid;
        console.log(`CREATED ${u.email}`);
      }
      await db.collection('users').doc(uid).set(
        { role: u.role, displayName: u.displayName, email: u.email, isActive: true },
        { merge: true }
      );
      console.log(`  -> role: ${u.role}`);
    } catch (err) {
      console.error(`ERR ${u.email}: ${err.message}`);
    }
  }
  console.log('\nAll set! Restart your Flutter apps and log in.');
  process.exit(0);
}

main();
