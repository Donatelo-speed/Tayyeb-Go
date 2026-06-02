/**
 * TayybeGo Firestore Seed Script
 *
 * Prerequisites:
 * 1. Go to Firebase Console → Project Settings → Service Accounts → "Generate new private key"
 * 2. Save the downloaded JSON as scripts/service-account-key.json
 * 3. Run: cd scripts && npm install && node seed_firestore.js
 *
 * Firebase Console Setup (before running):
 * 1. Authentication → Sign-in method → Enable "Email/Password"
 * 2. Firestore Database → Create database (start in test mode for dev)
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
async function setDoc(collection, docId, data) {
  await db.collection(collection).doc(docId).set(data);
  console.log(`  ✓ ${collection}/${docId}`);
}

// ---------------------------------------------------------------------------
// Seed Data
// ---------------------------------------------------------------------------
async function seed() {
  console.log('🌱 Seeding Firestore...\n');

  // --- USERS ---------------------------------------------------------------
  console.log('--- Users ---');
  const users = [
    {
      email: 'admin@tayyeb.com',
      role: 'superAdmin',
      displayName: 'Admin User',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      email: 'owner@almandi.com',
      role: 'restaurantOwner',
      displayName: 'Al Mandi Owner',
      restaurantId: 'almandi-house',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      email: 'cashier@almandi.com',
      role: 'cashier',
      displayName: 'Al Mandi Cashier',
      restaurantId: 'almandi-house',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      email: 'driver@company.com',
      role: 'driver',
      displayName: 'Driver User',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
      email: 'user@test.com',
      role: 'customer',
      displayName: 'Test Customer',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  // Also create Firebase Auth accounts for each user
  const auth = admin.auth();
  for (const u of users) {
    try {
      await auth.createUser({
        email: u.email,
        password: 'password123',
        displayName: u.displayName,
      });
      console.log(`  ✓ Auth user created: ${u.email}`);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log(`  ~ Auth user already exists: ${u.email}`);
      } else {
        throw e;
      }
    }
  }

  for (const u of users) {
    const docId = u.email.replace(/[@.]/g, '_');
    await setDoc('users', docId, u);
  }

  // --- DRIVERS -------------------------------------------------------------
  console.log('\n--- Drivers ---');
  const drivers = [
    { id: 'driver-001', name: 'Khaled Al-Sayed', phone: '0933111222', vehicle: 'Toyota Corolla 2020', isOnline: false, isActive: true },
    { id: 'driver-002', name: 'Mohammad Haddad', phone: '0933222333', vehicle: 'Honda Civic 2019', isOnline: false, isActive: true },
    { id: 'driver-003', name: 'Ahmad Khalil', phone: '0933333444', vehicle: 'Kia Rio 2021', isOnline: false, isActive: true },
    { id: 'driver-004', name: 'Hassan Ali', phone: '0933444555', vehicle: 'Hyundai Elantra 2020', isOnline: false, isActive: true },
  ];

  for (const d of drivers) {
    await setDoc('drivers', d.id, d);
  }

  // --- DRIVER LOCATIONS (for Live Map) ------------------------------------
  console.log('\n--- Driver Locations ---');
  const locations = [
    { id: 'loc-001', driverId: 'driver-001', driverName: 'Khaled', lat: 34.7324, lng: 36.7137 },
    { id: 'loc-002', driverId: 'driver-002', driverName: 'Mohammad', lat: 34.7350, lng: 36.7100 },
    { id: 'loc-003', driverId: 'driver-003', driverName: 'Ahmad', lat: 34.7300, lng: 36.7180 },
  ];

  for (const loc of locations) {
    await setDoc('driver_locations', loc.id, loc);
  }

  // --- RESTAURANTS ---------------------------------------------------------
  console.log('\n--- Restaurants ---');
  const restaurants = [
    {
      id: 'almandi-house',
      name: 'Al Mandi House',
      nameAr: 'مندي هاوس',
      description: 'Traditional Yemeni mandi and grilled meats',
      ownerId: 'owner@almandi.com',
      phone: '0933111222',
      address: 'Al-Hamra Street, Homs',
      isActive: true,
      rating: 4.8,
      cuisineType: 'Yemeni',
      deliveryFee: 2000,
      minOrder: 15000,
      estimatedDeliveryTime: 30,
      openingHours: { mon: '10:00-23:00', tue: '10:00-23:00', wed: '10:00-23:00', thu: '10:00-23:00', fri: '12:00-23:00', sat: '10:00-23:00', sun: '10:00-22:00' },
      location: new admin.firestore.GeoPoint(34.7324, 36.7137),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  ];

  for (const r of restaurants) {
    await setDoc('restaurants', r.id, r);
  }

  // --- MENU ITEMS ----------------------------------------------------------
  console.log('\n--- Menu Items ---');
  const menuItems = [
    { id: 'item-001', restaurantId: 'almandi-house', name: 'Mandi Lamb', nameAr: 'مندي لحم', description: 'Tender lamb with fragrant rice', price: 35000, category: 'Mandi', imageUrl: '', isAvailable: true, sortOrder: 1 },
    { id: 'item-002', restaurantId: 'almandi-house', name: 'Mandi Chicken', nameAr: 'مندي دجاج', description: 'Juicy chicken with spiced rice', price: 25000, category: 'Mandi', imageUrl: '', isAvailable: true, sortOrder: 2 },
    { id: 'item-003', restaurantId: 'almandi-house', name: 'Shawarma Plate', nameAr: 'صحن شاورما', description: 'Served with garlic sauce and pickles', price: 18000, category: 'Grills', imageUrl: '', isAvailable: true, sortOrder: 3 },
    { id: 'item-004', restaurantId: 'almandi-house', name: 'Fattoush Salad', nameAr: 'فتوش', description: 'Fresh mixed salad with crispy bread', price: 8000, category: 'Salads', imageUrl: '', isAvailable: true, sortOrder: 4 },
    { id: 'item-005', restaurantId: 'almandi-house', name: 'Hummus', nameAr: 'حمص', description: 'Creamy chickpea dip with tahini', price: 6000, category: 'Appetizers', imageUrl: '', isAvailable: true, sortOrder: 5 },
    { id: 'item-006', restaurantId: 'almandi-house', name: 'Baba Ghanoush', nameAr: 'بابا غنوج', description: 'Smoky eggplant dip', price: 6000, category: 'Appetizers', imageUrl: '', isAvailable: true, sortOrder: 6 },
    { id: 'item-008', restaurantId: 'almandi-house', name: 'Kunafa', nameAr: 'كنافة', description: 'Creamy cheese pastry with syrup', price: 12000, category: 'Desserts', imageUrl: '', isAvailable: true, sortOrder: 7 },
    { id: 'item-009', restaurantId: 'almandi-house', name: 'Fresh Juice', nameAr: 'عصير طازج', description: 'Seasonal fresh fruit juice', price: 5000, category: 'Drinks', imageUrl: '', isAvailable: true, sortOrder: 8 },
    { id: 'item-010', restaurantId: 'almandi-house', name: 'Soft Drink', nameAr: 'مشروب غازي', description: 'Canned soda 330ml', price: 3000, category: 'Drinks', imageUrl: '', isAvailable: true, sortOrder: 9 },
  ];

  for (const m of menuItems) {
    await setDoc('menu_items', m.id, m);
  }

  // --- ORDERS (sample recent orders for vendor dashboard) ------------------
  console.log('\n--- Orders ---');
  const orders = [
    {
      id: 'ord-001',
      restaurantId: 'almandi-house',
      customerName: 'Ahmed K.',
      items: [
        { name: 'Shawarma Plate', quantity: 2, unitPrice: 18000 },
        { name: 'Fries', quantity: 1, unitPrice: 5000 },
      ],
      total: 41000,
      status: 'preparing',
      statusHistory: [
        { status: 'pending', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000)) },
        { status: 'accepted', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3000000)) },
        { status: 'preparing', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 2400000)) },
      ],
      deliveryAddress: 'Al-Mansour, Street 12, Homs',
      customerPhone: '0933555666',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000)),
    },
    {
      id: 'ord-002',
      restaurantId: 'almandi-house',
      customerName: 'Sarah M.',
      items: [
        { name: 'Mandi Chicken', quantity: 1, unitPrice: 25000 },
        { name: 'Soft Drink', quantity: 1, unitPrice: 3000 },
      ],
      total: 28000,
      status: 'ready',
      statusHistory: [
        { status: 'pending', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7200000)) },
        { status: 'accepted', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 6600000)) },
        { status: 'preparing', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 6000000)) },
        { status: 'ready', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1200000)) },
      ],
      deliveryAddress: 'Al-Mazza, Building 5, Homs',
      customerPhone: '0933666777',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7200000)),
    },
    {
      id: 'ord-003',
      restaurantId: 'almandi-house',
      customerName: 'Omar R.',
      items: [
        { name: 'Kunafa', quantity: 2, unitPrice: 12000 },
        { name: 'Fresh Juice', quantity: 2, unitPrice: 5000 },
      ],
      total: 34000,
      status: 'delivered',
      statusHistory: [
        { status: 'pending', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14400000)) },
        { status: 'accepted', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 13800000)) },
        { status: 'preparing', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 13200000)) },
        { status: 'ready', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7200000)) },
        { status: 'picked_up', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000)) },
        { status: 'delivered', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 1800000)) },
      ],
      deliveryAddress: 'Al-Waer, Street 8, Homs',
      customerPhone: '0933777888',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14400000)),
    },
  ];

  for (const o of orders) {
    await setDoc('orders', o.id, o);
  }

  // --- ACTIVITY LOG --------------------------------------------------------
  console.log('\n--- Activity Log ---');
  const activities = [
    { icon: 'store', text: 'New restaurant "Al Mandi House" registered', color: 'blue', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 120000)) },
    { icon: 'person', text: 'New user registered: john@email.com', color: 'green', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 900000)) },
    { icon: 'shopping_cart', text: 'New order #ord-001 placed', color: 'orange', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 3600000)) },
    { icon: 'delivery_dining', text: 'Driver "Khaled" completed delivery', color: 'cyan', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7200000)) },
    { icon: 'attach_money', text: 'Payment received: \$45.00', color: 'purple', timestamp: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14400000)) },
  ];

  for (let i = 0; i < activities.length; i++) {
    await setDoc('activity_log', `activity-${String(i + 1).padStart(3, '0')}`, activities[i]);
  }

  console.log('\n✅ Seeding complete!');
}

seed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
