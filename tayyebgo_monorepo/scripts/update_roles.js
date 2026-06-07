const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const auth = admin.auth();

const users = [
  { email: 'owner@test.com', role: 'restaurantOwner', displayName: 'Owner' },
  { email: 'cashier@test.com', role: 'cashier', displayName: 'Cashier' },
  { email: 'driver@test.com', role: 'driver', displayName: 'Driver' },
  { email: 'customer@test.com', role: 'customer', displayName: 'Customer' },
];

async function main() {
  for (const u of users) {
    try {
      const user = await auth.getUserByEmail(u.email);
      await db.collection('users').doc(user.uid).set(
        { role: u.role, displayName: u.displayName, email: u.email, isActive: true },
        { merge: true }
      );
      console.log(`OK  ${u.email} -> ${u.role} (UID: ${user.uid})`);
    } catch (err) {
      console.error(`ERR ${u.email}: ${err.message}`);
    }
  }
  console.log('\nDone. Restart your Flutter apps and try logging in.');
  process.exit(0);
}

main();
