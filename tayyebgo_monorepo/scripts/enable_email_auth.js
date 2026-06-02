const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Firebase Admin SDK doesn't have an API to check/enable sign-in methods.
// This script verifies everything is correct and provides instructions.

const { auth } = admin;
const { projectId } = serviceAccount;

async function main() {
  console.log(`Firebase Project: ${projectId}\n`);

  // Verify users exist
  const emails = ['admin@test.com', 'owner@test.com', 'cashier@test.com', 'driver@test.com', 'customer@test.com'];
  let ok = 0;
  for (const email of emails) {
    try {
      const user = await auth.getUserByEmail(email);
      console.log(`[OK] ${email} (UID: ${user.uid})`);
      ok++;
    } catch (err) {
      console.log(`[--] ${email}: ${err.message}`);
    }
  }

  if (ok === emails.length) {
    console.log(`\n✅ All ${ok} accounts exist in Firebase Auth.`);
  }

  console.log(`\n🚨 Likely cause: Email/Password sign-in is DISABLED in Firebase Console.`);
  console.log(`\nFix: Go to this URL and ENABLE "Email/Password":`);
  console.log(`https://console.firebase.google.com/project/${projectId}/authentication/providers`);
  console.log(`\nThen click "Email/Password" -> Enable -> Save.`);
  console.log(`\nAfter that, restart your Flutter apps and try again.`);
  process.exit(0);
}

main();
