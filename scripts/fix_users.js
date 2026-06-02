const admin = require('firebase-admin');
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const auth = admin.auth();
const db = admin.firestore();

const roleMap = {
  'admin@test.com': 'superAdmin',
  'owner@test.com': 'restaurantOwner',
  'cashier@test.com': 'cashier',
  'driver@test.com': 'driver',
  'user@test.com': 'customer',
};

async function run() {
  const list = await auth.listUsers();
  for (const user of list.users) {
    const email = user.email;
    const role = roleMap[email];
    if (!role) {
      console.log(`Skipping unknown user: ${email}`);
      continue;
    }
    await db.collection('Users').doc(user.uid).set({
      email: email,
      role: role,
      displayName: user.displayName || email.split('@')[0],
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Created Users/${user.uid} → ${email} as ${role}`);
  }
  console.log('Done!');
}

run().catch(console.error);
