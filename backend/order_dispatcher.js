// ==================== PHASE 2: SMART ORDER DISPATCHER ====================
// This module handles notification broadcasting to drivers
// In production, integrate with Firebase Cloud Messaging (FCM)

const { pool } = require('./db');

// ==================== DRIVER STATUS ====================
const DriverStatus = {
  OFFLINE: 'offline',
  ONLINE: 'offline', 
  BUSY: 'busy',
};

// ==================== ORDER STATES ====================
const OrderStatus = {
  PENDING: 'pending',
  ACCEPTED: 'accepted',
  PROCESSING: 'processing',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
};

// Simulated driver notification queue (in production, use Firebase/FCM)
let _orderBroadcastQueue = [];
let _smsQueue = [];

// ==================== BROADCAST NEW ORDER ====================
const broadcastNewOrder = async (orderId, orderData) => {
  try {
    // Find available drivers (online + not busy)
    const drivers = await findAvailableDrivers();
    
    if (drivers.length === 0) {
      console.log(`[Dispatcher] No available drivers for order ${orderId}`);
      return { success: false, message: 'No drivers available' };
    }

    // Create broadcast notification
    const notification = {
      orderId,
      orderData,
      drivers: drivers.map(d => d.id),
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 60000), // 60 seconds to accept
    };

    // Add to broadcast queue
    _orderBroadcastQueue.push(notification);

    // Send push notifications to drivers (simulated)
    for (const driver of drivers) {
      await sendPushNotification(driver.fcm_token, {
        type: 'new_order',
        title: '🚚 New Order Available!',
        body: `Order #${orderId} - ${orderData.total} SAR`,
        orderId,
        data: orderData,
      });
    }

    // Schedule SMS backup after 60 seconds
    setTimeout(() => sendSMSBackup(orderId, drivers), 60000);

    console.log(`[Dispatcher] Broadcast order ${orderId} to ${drivers.length} drivers`);
    return { success: true, driversNotified: drivers.length };
  } catch (error) {
    console.error('[Dispatcher] Error broadcasting order:', error);
    return { success: false, error: error.message };
  }
};

// Find available drivers
const findAvailableDrivers = async () => {
  // In production, query database
  // SELECT * FROM users WHERE role = 'delivery' AND status = 'active' AND is_online = true AND is_busy = false
  const result = await pool.query(`
    SELECT id, name, phone, fcm_token, current_location
    FROM users 
    WHERE role = 'delivery' 
    AND status = 'active'
    AND is_online = true 
    AND is_busy = false
  `);
  return result.rows;
};

// Send push notification (simulated - integrate FCM in production)
const sendPushNotification = async (fcmToken, notification) => {
  // In production, use firebase-admin to send via FCM
  // const admin = require('firebase-admin');
  // await admin.messaging().send({
  //   token: fcmToken,
  //   notification: { title: notification.title, body: notification.body },
  //   data: notification.data,
  // });
  
  console.log(`[FCM] Push sent:`, notification.title);
  return { success: true };
};

// Send SMS backup (simulated - integrate Twilio in production)
const sendSMSBackup = async (orderId, drivers) => {
  // Check if order still pending
  const orderResult = await pool.query(
    'SELECT status FROM orders WHERE id = $1',
    [orderId]
  );
  
  if (orderResult.rows[0]?.status !== 'pending') {
    return; // Order already accepted
  }

  // Send SMS to first available driver
  // In production, use Twilio:
  // const twilio = require('twilio')(accountSid, authToken);
  // await twilio.messages.create({ ... });

  const message = 'New order waiting! Open OmniMarket to accept. Order #' + orderId;
  
  for (const driver of drivers.slice(0, 1)) {
    console.log(`[SMS] To ${driver.phone}: ${message}`);
    _smsQueue.push({ to: driver.phone, message });
  }
};

// Handle driver accepting order
const acceptOrder = async (driverId, orderId) => {
  try {
    // Update order status
    await pool.query(`
      UPDATE orders 
      SET assigned_driver_id = $1, status = $2, accepted_at = NOW()
      WHERE id = $3 AND status = 'pending'
    `, [driverId, OrderStatus.ACCEPTED, orderId]);

    // Mark driver as busy
    await pool.query(`
      UPDATE users SET is_busy = true WHERE id = $1
    `, [driverId]);

    // Remove from broadcast queue
    _orderBroadcastQueue = _orderBroadcastQueue.filter(n => n.orderId !== orderId);

    console.log(`[Dispatcher] Driver ${driverId} accepted order ${orderId}`);
    return { success: true };
  } catch (error) {
    console.error('[Dispatcher] Error accepting order:', error);
    return { success: false, error: error.message };
  }
};

// Handle driver declining order
const declineOrder = async (driverId, orderId) => {
  // In production, track declined count and ban after 3 declines
  console.log(`[Dispatcher] Driver ${driverId} declined order ${orderId}`);
  
  // Notify next available driver
  const notification = _orderBroadcastQueue.find(n => n.orderId === orderId);
  if (notification && notification.drivers.length > 1) {
    const nextDriver = notification.drivers.find(d => d !== driverId);
    if (nextDriver) {
      await sendPushNotification(nextDriver.fcm_token, {
        type: 'order_available',
        title: 'New Order Available!',
        body: `Order #${orderId} is now available`,
        orderId,
      });
    }
  }
  
  return { success: true };
};

// ==================== MODULE EXPORTS ====================
module.exports = {
  broadcastNewOrder,
  acceptOrder,
  declineOrder,
  findAvailableDrivers,
  DriverStatus,
  OrderStatus,
};

// ==================== DATABASE SCHEMA ADDITIONS ====================
/*
-- Add to database.sql:

-- Driver status fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_busy BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_location JSONB;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP;

-- Orders table updates
ALTER TABLE orders ADD COLUMN IF NOT EXISTS assigned_driver_id INTEGER REFERENCES users(id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_location JSONB;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_notes TEXT;

-- Driver earnings table
CREATE TABLE IF NOT EXISTS driver_earnings (
  id SERIAL PRIMARY KEY,
  driver_id INTEGER REFERENCES users(id),
  order_id INTEGER REFERENCES orders(id),
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, paid
  created_at TIMESTAMP DEFAULT NOW(),
  paid_at TIMESTAMP
);

-- Driver cash out requests
CREATE TABLE IF NOT EXISTS driver_cashouts (
  id SERIAL PRIMARY KEY,
  driver_id INTEGER REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, paid
  created_at TIMESTAMP DEFAULT NOW(),
  processed_at TIMESTAMP
);
*/