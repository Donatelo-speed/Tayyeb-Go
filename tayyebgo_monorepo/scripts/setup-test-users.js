#!/usr/bin/env node
/**
 * TayyebGo Firebase Test Users Setup Script
 * 
 * Run: node scripts/setup-test-users.js
 * 
 * Prerequisites:
 *   - Firebase CLI installed (npm install -g firebase-tools)
 *   - firebase login (authenticated)
 *   - firebase use tayyebgo (correct project selected)
 * 
 * This script:
 *   1. Lists all existing users (audit)
 *   2. Creates test users in Firebase Auth
 *   3. Creates/updates Firestore user documents with correct roles
 *   4. Outputs a verification report
 */

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin SDK
// Uses GOOGLE_APPLICATION_CREDENTIALS env var or default credentials
try {
  admin.initializeApp({
    projectId: 'tayyebgo',
  });
} catch (e) {
  console.error('Failed to initialize Firebase Admin SDK.');
  console.error('Make sure you have:');
  console.error('  1. Set GOOGLE_APPLICATION_CREDENTIALS env var to your service account key');
  console.error('  2. Or run: firebase functions:config:set ...');
  console.error('');
  console.error('Alternative: Use the Firebase Console to create users manually.');
  console.error('See docs/auth-system-verification.md for manual setup instructions.');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

// ─── Test Users Configuration ──────────────────────────────────────
const TEST_USERS = [
  {
    email: 'admin@test.com',
    password: 'Admin123!',
    displayName: 'Test Admin',
    role: 'superAdmin',
    isActive: true,
    description: 'Super Admin - full access to all apps',
  },
  {
    email: 'customer@test.com',
    password: 'Customer123!',
    displayName: 'Test Customer',
    role: 'customer',
    isActive: true,
    description: 'Customer - access to customer app only',
  },
  {
    email: 'driver@test.com',
    password: 'Driver123!',
    displayName: 'Test Driver',
    role: 'driver',
    isActive: true,
    description: 'Driver - access to driver app only',
    extraFields: {
      online: false,
      available: true,
      vehicleType: 'motorcycle',
      vehiclePlate: 'TEST-123',
      documentsSubmitted: true,
      documentsVerified: true,
    },
  },
  {
    email: 'partner-owner@test.com',
    password: 'Owner123!',
    displayName: 'Test Restaurant Owner',
    role: 'restaurantOwner',
    isActive: true,
    restaurantId: 'test_restaurant_001',
    description: 'Restaurant Owner - access to partner app (owner dashboard)',
  },
  {
    email: 'partner-cashier@test.com',
    password: 'Cashier123!',
    displayName: 'Test Cashier',
    role: 'cashier',
    isActive: true,
    restaurantId: 'test_restaurant_001',
    description: 'Cashier - access to partner app (POS/terminal)',
  },
];

// ─── Helper Functions ──────────────────────────────────────────────

async function findUserByEmail(email) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') return null;
    throw e;
  }
}

async function createAuthUser(userConfig) {
  const userRecord = await auth.createUser({
    email: userConfig.email,
    password: userConfig.password,
    displayName: userConfig.displayName,
    emailVerified: true,
    disabled: false,
  });
  console.log(`  ✓ Created Auth user: ${userConfig.email} (uid: ${userRecord.uid})`);
  return userRecord;
}

async function upsertFirestoreDoc(uid, userConfig) {
  const docData = {
    email: userConfig.email,
    displayName: userConfig.displayName,
    role: userConfig.role,
    isActive: userConfig.isActive,
    preferredLocale: 'en',
    loyaltyPoints: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (userConfig.restaurantId) {
    docData.restaurantId = userConfig.restaurantId;
  }

  // Merge extra fields (driver-specific, etc.)
  if (userConfig.extraFields) {
    Object.assign(docData, userConfig.extraFields);
  }

  const docRef = db.collection('users').doc(uid);
  const existing = await docRef.get();

  if (existing.exists) {
    // Update existing doc — preserve createdAt
    const existingData = existing.data();
    docData.createdAt = existingData.createdAt || docData.createdAt;
    await docRef.set(docData, { merge: true });
    console.log(`  ✓ Updated Firestore doc: users/${uid} (role: ${userConfig.role})`);
  } else {
    await docRef.set(docData);
    console.log(`  ✓ Created Firestore doc: users/${uid} (role: ${userConfig.role})`);
  }

  return docData;
}

async function listExistingUsers() {
  console.log('\n📋 Existing Firebase Auth users:');
  console.log('─'.repeat(60));
  
  const listResult = await auth.listUsers(100);
  const users = listResult.users;
  
  if (users.length === 0) {
    console.log('  (no users found)');
    return users;
  }

  for (const user of users) {
    const doc = await db.collection('users').doc(user.uid).get();
    const role = doc.exists ? (doc.data().role || 'MISSING') : 'NO_FIRESTORE_DOC';
    console.log(`  ${user.email || 'no-email'} | uid: ${user.uid} | role: ${role}`);
  }
  
  console.log(`\n  Total: ${users.length} users`);
  return users;
}

async function cleanupDuplicateDocs(existingUsers) {
  console.log('\n🧹 Checking for duplicate/conflicting user docs...');
  
  // Check for users collection vs users collection (same name, no dups possible in Firestore)
  // But check for wrong field names
  const usersSnapshot = await db.collection('users').get();
  const issues = [];
  
  for (const doc of usersSnapshot.docs) {
    const data = doc.data();
    const problems = [];
    
    // Check for wrong role field names
    if (data.userRole && !data.role) {
      problems.push(`Has 'userRole' instead of 'role'`);
    }
    if (data.accountType) {
      problems.push(`Has 'accountType' field (should be 'role')`);
    }
    if (data.permissions && !data.role) {
      problems.push(`Has 'permissions' instead of 'role'`);
    }
    
    // Check if role value is valid
    const validRoles = ['superAdmin', 'restaurantOwner', 'cashier', 'driver', 'customer'];
    if (data.role && !validRoles.includes(data.role)) {
      problems.push(`Invalid role value: '${data.role}'`);
    }
    
    // Check for missing role
    if (!data.role) {
      problems.push(`Missing 'role' field entirely`);
    }
    
    if (problems.length > 0) {
      issues.push({ docId: doc.id, problems });
      console.log(`  ⚠ users/${doc.id}:`);
      for (const p of problems) {
        console.log(`    - ${p}`);
      }
    }
  }
  
  if (issues.length === 0) {
    console.log('  ✓ No issues found');
  } else {
    console.log(`\n  Found ${issues.length} documents with issues`);
  }
  
  return issues;
}

// ─── Main ──────────────────────────────────────────────────────────

async function main() {
  console.log('🚀 TayyebGo Firebase Test Users Setup');
  console.log('═'.repeat(60));
  
  // Step 1: List existing users
  const existingUsers = await listExistingUsers();
  
  // Step 2: Check for data issues
  await cleanupDuplicateDocs();
  
  // Step 3: Create/update test users
  console.log('\n👤 Creating test users...');
  console.log('─'.repeat(60));
  
  const results = [];
  
  for (const userConfig of TEST_USERS) {
    console.log(`\n  Processing: ${userConfig.email}`);
    console.log(`  Role: ${userConfig.role} | ${userConfig.description}`);
    
    try {
      let authUser = await findUserByEmail(userConfig.email);
      
      if (authUser) {
        console.log(`  ℹ Auth user already exists (uid: ${authUser.uid})`);
        // Update password if needed
        try {
          await auth.updateUser(authUser.uid, { password: userConfig.password });
          console.log(`  ✓ Password updated`);
        } catch (e) {
          console.log(`  ℹ Password update skipped: ${e.message}`);
        }
      } else {
        authUser = await createAuthUser(userConfig);
      }
      
      const firestoreDoc = await upsertFirestoreDoc(authUser.uid, userConfig);
      
      results.push({
        email: userConfig.email,
        uid: authUser.uid,
        role: userConfig.role,
        status: 'SUCCESS',
        restaurantId: userConfig.restaurantId || null,
      });
    } catch (e) {
      console.error(`  ✗ FAILED: ${e.message}`);
      results.push({
        email: userConfig.email,
        role: userConfig.role,
        status: 'FAILED',
        error: e.message,
      });
    }
  }
  
  // Step 4: Summary
  console.log('\n\n📊 Summary');
  console.log('═'.repeat(60));
  console.log('');
  console.log('  Email                      | Role            | Status');
  console.log('  ' + '─'.repeat(58));
  
  for (const r of results) {
    const email = (r.email || '').padEnd(26);
    const role = (r.role || '').padEnd(16);
    const status = r.status === 'SUCCESS' ? '✓' : '✗';
    console.log(`  ${email} | ${role} | ${status} ${r.status}`);
    if (r.uid) console.log(`    uid: ${r.uid}`);
    if (r.restaurantId) console.log(`    restaurantId: ${r.restaurantId}`);
    if (r.error) console.log(`    error: ${r.error}`);
  }
  
  const successCount = results.filter(r => r.status === 'SUCCESS').length;
  console.log(`\n  ${successCount}/${results.length} users created/updated successfully`);
  
  // Step 5: Expected login behavior
  console.log('\n\n🔑 Expected Login Behavior');
  console.log('═'.repeat(60));
  console.log('');
  console.log('  Email                      | App Target | Expected Screen');
  console.log('  ' + '─'.repeat(58));
  console.log('  admin@test.com             | admin      | Admin Dashboard');
  console.log('  customer@test.com          | customer   | Customer Home');
  console.log('  driver@test.com            | driver     | Driver Dashboard');
  console.log('  partner-owner@test.com     | partner    | Owner Dashboard');
  console.log('  partner-cashier@test.com   | partner    | Cashier Terminal');
  console.log('');
  console.log('  Password for all: [see above]');
  console.log('');
  
  console.log('\n✅ Setup complete!');
}

main().catch(e => {
  console.error('\n❌ Fatal error:', e.message);
  process.exit(1);
});
