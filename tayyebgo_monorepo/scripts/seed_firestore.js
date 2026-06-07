/**
 * TayyebGo Seed Script — v2
 *
 * Creates Firebase Auth users + Firestore seed data.
 *
 * Usage:
 *   1. Download serviceAccountKey.json from Firebase Console > Project Settings > Service Accounts
 *   2. Place it in the monorepo root (already there? check serviceAccountKey.json)
 *   3. Run: node scripts/seed_firestore.js
 *
 * Dry-run: node scripts/seed_firestore.js --dry-run
 */

const admin = require('firebase-admin');
const path = require('path');

const DRY_RUN = process.argv.includes('--dry-run');

let serviceAccount;
try {
  serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
} catch {
  console.log('No serviceAccountKey.json found. Run with --dry-run to preview.');
  if (!DRY_RUN) process.exit(1);
}

if (!DRY_RUN) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const auth = DRY_RUN ? null : admin.auth();
const db = DRY_RUN ? null : admin.firestore();

const TEST_PASSWORD = 'test123';

async function seed() {
  const batch = DRY_RUN ? null : db.batch();

  // =========================================================================
  // Firebase Auth Users
  // =========================================================================
  const authUsers = [
    { uid: 'admin-test', email: 'admin@test.com',      displayName: 'Super Admin',        role: 'superAdmin' },
    { uid: 'owner-test',  email: 'owner@test.com',      displayName: 'Restaurant Owner',   role: 'restaurantOwner' },
    { uid: 'cashier-test',email: 'cashier@test.com',    displayName: 'Cashier',            role: 'cashier' },
    { uid: 'driver-test',  email: 'driver@test.com',     displayName: 'Driver',             role: 'driver' },
    { uid: 'customer-test',email: 'customer@test.com',   displayName: 'Customer',           role: 'customer' },
  ];

  const users = [
    { uid: 'admin-test', email: 'admin@test.com',      displayName: 'Super Admin',        photoUrl: null, role: 'superAdmin',      isActive: true, phone: '+963911111111' },
    { uid: 'owner-test',  email: 'owner@test.com',      displayName: 'Restaurant Owner',   photoUrl: null, role: 'restaurantOwner', isActive: true, phone: '+963911111112' },
    { uid: 'cashier-test',email: 'cashier@test.com',    displayName: 'Cashier',            photoUrl: null, role: 'cashier',         isActive: true, phone: '+963911111113' },
    { uid: 'driver-test',  email: 'driver@test.com',     displayName: 'Driver',             photoUrl: null, role: 'driver',          isActive: true, phone: '+963911111114' },
    { uid: 'customer-test',email: 'customer@test.com',   displayName: 'Customer',           photoUrl: null, role: 'customer',        isActive: true, phone: '+963911111115' },
  ];

  const restaurants = [
    { id: 'rest-almandi',  name: 'Al Mandi Restaurant', cuisineType: 'Arabian',   isActive: true, ownerId: 'owner-test', address: 'Al Hamidiya Souq, Homs, Syria',   phone: '+963911111120', commissionPercent: 15.0, latitude: 34.7324, longitude: 36.7137 },
    { id: 'rest-shaverma', name: 'Shawarma House',       cuisineType: 'Levantine', isActive: true, ownerId: 'owner-test', address: 'Quwatli Street, Homs, Syria',    phone: '+963911111121', commissionPercent: 12.0, latitude: 34.7340, longitude: 36.7150 },
  ];

  const menuItems = [
    { id: 'item-mandi-chicken', restaurantId: 'rest-almandi', name: 'Chicken Mandi',     description: 'Tender chicken with saffron rice',        price: 25000, category: 'Main Course', isAvailable: true, sortOrder: 1 },
    { id: 'item-mandi-lamb',    restaurantId: 'rest-almandi', name: 'Lamb Mandi',        description: 'Slow-cooked lamb with spiced rice',        price: 35000, category: 'Main Course', isAvailable: true, sortOrder: 2 },
    { id: 'item-hummus',        restaurantId: 'rest-almandi', name: 'Hummus',            description: 'Creamy chickpea dip with tahini',         price: 8000,  category: 'Appetizer',   isAvailable: true, sortOrder: 3 },
    { id: 'item-fattoush',      restaurantId: 'rest-almandi', name: 'Fattoush Salad',    description: 'Crispy bread salad with sumac',            price: 10000, category: 'Salad',       isAvailable: true, sortOrder: 4 },
    { id: 'item-chicken-sha',   restaurantId: 'rest-shaverma',name: 'Chicken Shawarma',  description: 'Marinated chicken with garlic sauce',     price: 15000, category: 'Main Course', isAvailable: true, sortOrder: 1 },
    { id: 'item-beef-sha',      restaurantId: 'rest-shaverma',name: 'Beef Shawarma',     description: 'Spiced beef with tahini sauce',           price: 18000, category: 'Main Course', isAvailable: true, sortOrder: 2 },
  ];

  const orders = [
    {
      id: 'order-001',
      customerId: 'customer-test', customerName: 'Customer', customerEmail: 'customer@test.com', customerPhone: '+963911111115',
      restaurantId: 'rest-almandi', restaurantName: 'Al Mandi Restaurant',
      status: 'delivered',
      items: [{ name: 'Chicken Mandi', price: 25000, quantity: 2 }, { name: 'Hummus', price: 8000, quantity: 1 }],
      subtotal: 58000, deliveryFee: 3000, tax: 2900, totalAmount: 63900,
      deliveryAddress: 'Al Waer District, Homs', fulfillmentType: 'delivery',
      statusHistory: [
        { from: '', to: 'placed', timestamp: new Date('2025-01-15T10:00:00'), actorId: 'customer-test', note: 'Order placed' },
        { from: 'placed', to: 'accepted', timestamp: new Date('2025-01-15T10:02:00'), actorId: 'cashier-test', note: 'Order accepted' },
        { from: 'accepted', to: 'preparing', timestamp: new Date('2025-01-15T10:05:00'), actorId: 'cashier-test', note: 'Started preparing' },
        { from: 'preparing', to: 'ready', timestamp: new Date('2025-01-15T10:15:00'), actorId: 'cashier-test', note: 'Ready for pickup' },
        { from: 'ready', to: 'ready_for_driver', timestamp: new Date('2025-01-15T10:16:00'), actorId: 'cashier-test', note: 'Made available' },
        { from: 'ready_for_driver', to: 'dispatched', timestamp: new Date('2025-01-15T10:20:00'), actorId: 'driver-test', note: 'Driver accepted' },
        { from: 'dispatched', to: 'picked_up', timestamp: new Date('2025-01-15T10:25:00'), actorId: 'driver-test', note: 'Picked up' },
        { from: 'picked_up', to: 'delivered', timestamp: new Date('2025-01-15T10:40:00'), actorId: 'driver-test', note: 'Delivered' },
      ],
    },
    {
      id: 'order-002',
      customerId: 'customer-test', customerName: 'Customer', customerEmail: 'customer@test.com', customerPhone: '+963911111115',
      restaurantId: 'rest-shaverma', restaurantName: 'Shawarma House',
      status: 'placed',
      items: [{ name: 'Chicken Shawarma', price: 15000, quantity: 3 }],
      subtotal: 45000, deliveryFee: 3000, tax: 2250, totalAmount: 50250,
      deliveryAddress: 'Al Hamidiya Souq, Homs', fulfillmentType: 'pickup',
      statusHistory: [
        { from: '', to: 'placed', timestamp: new Date('2026-05-24T12:00:00'), actorId: 'customer-test', note: 'Order placed' },
      ],
    },
  ];

  // NOTE: driver profile data lives in Users collection (role='driver').
  // The legacy 'drivers' collection is no longer queried by the apps.

  const promos = [
    { id: 'promo-welcome', code: 'WELCOME50', name: 'Welcome50', description: '50% off your first order', type: 'percentage', value: 50, maxDiscount: 25000, minOrder: 10000, active: true, usageLimit: 100, usedCount: 5, endDate: new Date('2027-01-01') },
    { id: 'promo-free-del', code: 'FREEDEL',  name: 'FreeDelivery', description: 'Free delivery on orders over 20000 SYP', type: 'fixed', value: 3000, minOrder: 20000, active: true, usageLimit: 50, usedCount: 10, endDate: new Date('2027-06-01'), restaurantId: 'rest-almandi' },
  ];

  const config = {
    id: 'platform',
    maintenanceMode: false,
    allowRegistrations: true,
    driverCommission: true,
    pushEnabled: true,
    commissionPercent: 15,
  };

  const activityEntries = [
    { id: 'act-1', text: 'Admin signed in', color: 'blue' },
    { id: 'act-2', text: 'New user registered: customer@test.com', color: 'green' },
    { id: 'act-3', text: 'Order #001 delivered by Ahmed', color: 'orange' },
    { id: 'act-4', text: 'Al Mandi added Chicken Mandi to menu', color: 'purple' },
    { id: 'act-5', text: 'Driver Ahmed went online', color: 'cyan' },
  ];

  console.log('Seeding:');
  console.log(`  ${authUsers.length} Firebase Auth users`);
  console.log(`  ${users.length} Firestore users`);
  console.log(`  ${restaurants.length} restaurants`);
  console.log(`  ${menuItems.length} menu items`);
  console.log(`  ${orders.length} orders`);
  console.log(`  0 drivers (data in Users collection)`);
  console.log(`  ${promos.length} promos`);
  console.log(`  1 config entry`);
  console.log(`  ${activityEntries.length} activity entries`);

  if (DRY_RUN) {
    console.log('\n--dry-run: no data written.');
    return;
  }

  // 1. Create Firebase Auth users
  console.log('\n--- Creating Auth Users ---');
  for (const u of authUsers) {
    try {
      await auth.createUser({
        uid: u.uid,
        email: u.email,
        emailVerified: true,
        password: TEST_PASSWORD,
        displayName: u.displayName,
        disabled: false,
      });
      console.log(`  ✓ ${u.email} (${u.role}) — password: ${TEST_PASSWORD}`);
    } catch (err) {
      if (err.code === 'auth/uid-already-exists' || err.code === 'auth/email-already-exists') {
        console.log(`  ~ ${u.email} already exists, skipping`);
      } else {
        throw err;
      }
    }
  }

  // 2. Write Firestore documents
  console.log('\n--- Writing Firestore ---');

  for (const u of users) {
    const { uid, ...data } = u;
    batch.set(db.collection('users').doc(uid), { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }

  for (const r of restaurants) {
    const { id, ...data } = r;
    batch.set(db.collection('restaurants').doc(id), { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }

  for (const m of menuItems) {
    const { id, ...data } = m;
    batch.set(db.collection('menu_items').doc(id), { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }

  for (const o of orders) {
    const { id, ...data } = o;
    batch.set(db.collection('orders').doc(id), { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }

  for (const p of promos) {
    const { id, ...data } = p;
    batch.set(db.collection('promos').doc(id), { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  }

  batch.set(db.collection('config').doc('platform'), { ...config, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

  for (const a of activityEntries) {
    const { id, ...data } = a;
    batch.set(db.collection('activity_log').doc(id), { ...data, timestamp: admin.firestore.FieldValue.serverTimestamp() });
  }

  await batch.commit();
  console.log('\n✓ Seed complete!');
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
