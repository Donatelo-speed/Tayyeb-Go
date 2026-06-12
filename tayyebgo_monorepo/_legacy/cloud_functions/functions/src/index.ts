import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * Scheduled function: runs daily to create payouts for vendors with completed orders
 * in the previous period.
 */
export const processPayouts = functions.scheduler.onSchedule(
  '0 6 * * *',
  async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    console.log(`[processPayouts] Running payout cycle for ${yesterday.toISOString()} — ${today.toISOString()}`);

    try {
      // Query completed orders in date range
      const completedOrdersSnapshot = await db
        .collection('orders')
        .where('status', '==', 'delivered')
        .where('deliveredAt', '>=', yesterday)
        .where('deliveredAt', '<', today)
        .get();

      console.log(`[processPayouts] Found ${completedOrdersSnapshot.size} completed orders`);

      // Group orders by vendor (restaurant)
      const vendorOrders: Map<string, any[]> = new Map();
      completedOrdersSnapshot.forEach(doc => {
        const order = doc.data();
        const vendorId = order.restaurantId;
        if (!vendorOrders.has(vendorId)) {
          vendorOrders.set(vendorId, []);
        }
        vendorOrders.get(vendorId)!.push(order);
      });

      // Calculate payouts for each vendor
      const batch = db.batch();
      for (const [vendorId, orders] of vendorOrders) {
        const totalRevenue = orders.reduce((sum, order) => sum + (order.totalAmount || 0), 0);
        const commissionRate = orders[0].commissionRate || 0.15;
        const commission = totalRevenue * commissionRate;
        const netAmount = totalRevenue - commission;

        const payoutRef = db.collection('payouts').doc();
        batch.set(payoutRef, {
          id: payoutRef.id,
          vendorId,
          vendorName: orders[0].restaurantName || 'Unknown',
          amount: totalRevenue,
          fee: commission,
          netAmount,
          status: 'pending',
          orderCount: orders.length,
          periodStart: yesterday,
          periodEnd: today,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`[processPayouts] Created payout for vendor ${vendorId}: ${netAmount}`);
      }

      await batch.commit();
      console.log(`[processPayouts] Successfully created ${vendorOrders.size} payouts`);
    } catch (error) {
      console.error('[processPayouts] Error:', error);
      throw error;
    }
  },
);

/**
 * Trigger: When an order is created
 */
export const onOrderCreated = functions.firestore.onDocumentCreated(
  'orders/{orderId}',
  async (event) => {
    const order = event.data?.data();
    if (!order) return;

    console.log(`[onOrderCreated] Order ${event.params.orderId} created`);

    try {
      // Create dispatch request for drivers
      const dispatchRef = db.collection('dispatch_requests').doc();
      await dispatchRef.set({
        id: dispatchRef.id,
        orderId: event.params.orderId,
        restaurantId: order.restaurantId,
        restaurantName: order.restaurantName,
        restaurantLocation: order.restaurantLocation,
        pickupAddress: order.pickupAddress,
        pickupLatitude: order.pickupLatitude,
        pickupLongitude: order.pickupLongitude,
        dropoffAddress: order.dropoffAddress,
        dropoffLatitude: order.dropoffLatitude,
        dropoffLongitude: order.dropoffLongitude,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes
      });

      console.log(`[onOrderCreated] Created dispatch request ${dispatchRef.id}`);
    } catch (error) {
      console.error('[onOrderCreated] Error:', error);
    }
  },
);

/**
 * Trigger: When an order is updated
 */
export const onOrderUpdated = functions.firestore.onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Check if status changed
    if (before.status !== after.status) {
      console.log(`[onOrderUpdated] Order ${event.params.orderId} status changed from ${before.status} to ${after.status}`);

      try {
        // Send notification based on status change
        const notificationRef = db.collection('notifications').doc();
        await notificationRef.set({
          id: notificationRef.id,
          orderId: event.params.orderId,
          customerId: after.customerId,
          title: `Order ${after.status}`,
          body: `Your order is now ${after.status}`,
          status: after.status,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });

        console.log(`[onOrderUpdated] Created notification for order ${event.params.orderId}`);
      } catch (error) {
        console.error('[onOrderUpdated] Error:', error);
      }
    }
  },
);

/**
 * Trigger: When a dispatch request is created
 */
export const onDispatchCreated = functions.firestore.onDocumentCreated(
  'dispatch_requests/{dispatchId}',
  async (event) => {
    const dispatch = event.data?.data();
    if (!dispatch) return;

    console.log(`[onDispatchCreated] Dispatch ${event.params.dispatchId} created`);

    try {
      // Notify nearby drivers
      const driversSnapshot = await db
        .collection('driver_locations')
        .where('isOnline', '==', true)
        .get();

      console.log(`[onDispatchCreated] Found ${driversSnapshot.size} online drivers`);

      const batch = db.batch();
      driversSnapshot.forEach(doc => {
        const driverId = doc.id;
        const notificationRef = db.collection('notifications').doc();
        batch.set(notificationRef, {
          id: notificationRef.id,
          dispatchId: event.params.dispatchId,
          driverId,
          title: 'New Delivery Request',
          body: `New delivery from ${dispatch.restaurantName}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });
      });

      await batch.commit();
      console.log(`[onDispatchCreated] Notified ${driversSnapshot.size} drivers`);
    } catch (error) {
      console.error('[onDispatchCreated] Error:', error);
    }
  },
);

/**
 * Scheduled function: Check for dispatch timeouts and reassign
 */
export const checkDispatchTimeouts = functions.scheduler.onSchedule(
  '*/5 * * * *', // Every 5 minutes
  async () => {
    console.log('[checkDispatchTimeouts] Checking for expired dispatch requests');

    try {
      const now = new Date();
      const expiredDispatches = await db
        .collection('dispatch_requests')
        .where('status', '==', 'pending')
        .where('expiresAt', '<', now)
        .get();

      console.log(`[checkDispatchTimeouts] Found ${expiredDispatches.size} expired dispatches`);

      const batch = db.batch();
      expiredDispatches.forEach(doc => {
        const dispatch = doc.data();
        // Extend expiration by 5 minutes
        const newExpiresAt = new Date(Date.now() + 5 * 60 * 1000);
        batch.update(doc.ref, {
          expiresAt: newExpiresAt,
          retryCount: (dispatch.retryCount || 0) + 1,
        });
      });

      await batch.commit();
      console.log(`[checkDispatchTimeouts] Extended ${expiredDispatches.size} dispatches`);
    } catch (error) {
      console.error('[checkDispatchTimeouts] Error:', error);
    }
  },
);

/**
 * Trigger: When SOS emergency is created
 */
export const onSOSEmergency = functions.firestore.onDocumentCreated(
  'sos_alerts/{sosId}',
  async (event) => {
    const sos = event.data?.data();
    if (!sos) return;

    console.log(`[onSOSEmergency] SOS ${event.params.sosId} created by driver ${sos.driverId}`);

    try {
      // Notify support team
      const supportNotificationRef = db.collection('notifications').doc();
      await supportNotificationRef.set({
        id: supportNotificationRef.id,
        type: 'sos_emergency',
        driverId: sos.driverId,
        title: '🚨 SOS EMERGENCY',
        body: `Driver ${sos.driverName} has triggered SOS`,
        location: {
          latitude: sos.latitude,
          longitude: sos.longitude,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        priority: 'high',
      });

      console.log(`[onSOSEmergency] Notified support team for SOS ${event.params.sosId}`);
    } catch (error) {
      console.error('[onSOSEmergency] Error:', error);
    }
  },
);
