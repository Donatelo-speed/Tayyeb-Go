const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const auth = admin.auth();

async function main() {
  for (const email of ['admin@test.com', 'owner@test.com', 'cashier@test.com', 'driver@test.com', 'customer@test.com']) {
    try {
      const user = await auth.getUserByEmail(email);
      console.log(`${email}:`);
      console.log(`  UID:      ${user.uid}`);
      console.log(`  Disabled: ${user.disabled}`);
      console.log(`  Provider: ${user.providerData.map(p => p.providerId).join(', ')}`);
    } catch (err) {
      console.error(`${email}: NOT FOUND - ${err.message}`);
    }
  }
  process.exit(0);
}

main();
