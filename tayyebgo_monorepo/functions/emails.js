const { functions, admin, db } = require('./config');

/**
 * Sends a welcome email when a new user document is created.
 * Uses Firebase Auth email (no external email service required).
 * NOTE: Firebase Auth already sends verification emails on signup.
 * This function sends a Firestore-based welcome notification + in-app message.
 */
const onUserCreated = functions.firestore
  .onDocumentCreated('users/{userId}', async (event) => {
    const snap = event.data;
    if (!snap) return;

    const userData = snap.data();
    const { displayName, email, role } = userData;
    const userId = event.params.userId;

    if (!email) return;

    try {
      // Create in-app welcome notification
      await db.collection('notifications').add({
        recipientId: userId,
        title: `Welcome to TayyebGo${displayName ? ', $displayName' : ''}!`,
        body: 'Your account is set up and ready to go. Start exploring restaurants, stores, and services near you.',
        type: 'welcome',
        role: role || 'customer',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Welcome notification sent to ${userId} (${email})`);
    } catch (err) {
      console.error(`Welcome email error for ${userId}:`, err.message);
    }
  });

/**
 * Sends order status update notifications (push + in-app).
 * Triggered when an order document is updated with a new status.
 */
const onOrderStatusChange = functions.firestore
  .onDocumentUpdated('orders/{orderId}', async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const oldStatus = before.status;
    const newStatus = after.status;
    if (oldStatus === newStatus) return;

    const { customerId, driverId, restaurantId, orderId: orderIdField } = after;
    const orderId = event.params.orderId;

    const statusMessages = {
      confirmed: { title: 'Order Confirmed!', body: 'Your order has been confirmed and is being prepared.' },
      preparing: { title: 'Being Prepared', body: 'Your order is being prepared by the restaurant.' },
      ready_for_pickup: { title: 'Ready for Pickup', body: 'Your order is ready and waiting for driver pickup.' },
      picked_up: { title: 'On Its Way!', body: 'Your driver has picked up your order and is heading your way.' },
      delivered: { title: 'Order Delivered!', body: 'Your order has been delivered. Enjoy your meal!' },
      cancelled: { title: 'Order Cancelled', body: 'Your order has been cancelled. Refund will be processed if applicable.' },
    };

    const msg = statusMessages[newStatus];
    if (!msg) return;

    try {
      // Notify customer
      if (customerId) {
        await db.collection('notifications').add({
          recipientId: customerId,
          title: msg.title,
          body: msg.body,
          type: 'order_update',
          orderId: orderId,
          role: 'customer',
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Notify driver (except for ready_for_pickup which is internal)
      if (driverId && newStatus !== 'ready_for_pickup') {
        const driverMessages = {
          confirmed: { title: 'New Order Available', body: 'A new order is ready for pickup. Check available requests.' },
          picked_up: { title: 'Delivering Order', body: 'Navigate to the customer delivery address.' },
          delivered: { title: 'Delivery Complete', body: 'Order delivered successfully. Great job!' },
        };
        const driverMsg = driverMessages[newStatus];
        if (driverMsg) {
          await db.collection('notifications').add({
            recipientId: driverId,
            title: driverMsg.title,
            body: driverMsg.body,
            type: 'order_update',
            orderId: orderId,
            role: 'driver',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      // Notify restaurant partner
      if (restaurantId && (newStatus === 'confirmed' || newStatus === 'cancelled')) {
        const partnerMessages = {
          confirmed: { title: 'New Order Received', body: 'A new order has been placed. Please confirm and start preparing.' },
          cancelled: { title: 'Order Cancelled', body: 'An order has been cancelled by the customer.' },
        };
        const partnerMsg = partnerMessages[newStatus];
        if (partnerMsg) {
          // Get restaurant owner ID from the restaurant document
          const restSnap = await db.collection('restaurants').doc(restaurantId).get();
          if (restSnap.exists) {
            const ownerId = restSnap.data()?.ownerId;
            if (ownerId) {
              await db.collection('notifications').add({
                recipientId: ownerId,
                title: partnerMsg.title,
                body: partnerMsg.body,
                type: 'order_update',
                orderId: orderId,
                role: 'partner',
                read: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      console.log(`Order status notifications sent: ${orderId} → ${newStatus}`);
    } catch (err) {
      console.error(`Order status notification error for ${orderId}:`, err.message);
    }
  });

/**
 * Sends a push notification + in-app message for driver assignment.
 * Triggered when a dispatch request is accepted by a driver.
 */
const onDriverAssigned = functions.firestore
  .onDocumentUpdated('dispatch_requests/{requestId}', async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return;

    const oldDriverId = before.driverId;
    const newDriverId = after.driverId;
    if (!newDriverId || oldDriverId === newDriverId) return;

    const { customerId, restaurantAddress, deliveryAddress } = after;
    const requestId = event.params.requestId;

    try {
      if (customerId) {
        await db.collection('notifications').add({
          recipientId: customerId,
          title: 'Driver Found!',
          body: 'A driver has been assigned to your order and is on the way to pick it up.',
          type: 'driver_assigned',
          orderId: requestId,
          role: 'customer',
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`Driver assigned notification sent for request ${requestId}`);
    } catch (err) {
      console.error(`Driver assigned notification error:`, err.message);
    }
  });

module.exports = { onUserCreated, onOrderStatusChange, onDriverAssigned };
