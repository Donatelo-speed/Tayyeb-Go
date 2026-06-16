const { functions, admin, db, rateLimit } = require('./config');

const onNotificationCreated = functions.firestore
  .onDocumentCreated('notifications/{notificationId}', async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { recipientId, role, title, body, type, orderId } = data;
    if (!recipientId || !title || !body) return;

    try {
      const userSnap = await db.collection('users').doc(recipientId).get();
      if (!userSnap.exists) return;

      const userData = userSnap.data();
      const fcmToken = userData?.fcmToken;
      if (!fcmToken) return;

      const message = {
        notification: { title, body },
        data: {
          type: type || 'order_update',
          ...(orderId ? { orderId } : {}),
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`FCM sent to ${recipientId}: ${title}`);
    } catch (err) {
      console.error(`FCM send error for ${recipientId}:`, err.message);

      if (err.code === 'messaging/invalid-registration-token' ||
          err.code === 'messaging/registration-token-not-registered') {
        await db.collection('users').doc(recipientId).update({ fcmToken: null });
      }
    }
  });

const registerFcmToken = functions.https.onCall(async (request) => {
  const { uid, token } = request.data;
  if (!uid || !token) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'uid and token are required'
    );
  }

  if (!request.auth || request.auth.uid !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Can only register own FCM token'
    );
  }

  const rl = await rateLimit(request.auth.uid, 'registerFcmToken', { maxRequests: 10, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  try {
    await db.collection('users').doc(uid).update({ fcmToken: token });
    return { success: true };
  } catch (err) {
    console.error('registerFcmToken error:', err.message);
    throw new functions.https.HttpsError('internal', 'Failed to register token');
  }
});

const cleanupNotifications = functions.scheduler
  .onSchedule('0 0 * * *', async () => {
    try {
      const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const oldNotifications = await db
        .collection('notifications')
        .where('createdAt', '<', cutoff)
        .get();

      let deleted = 0;
      const batch = db.batch();
      oldNotifications.forEach((doc) => {
        batch.delete(doc.ref);
        deleted++;
      });
      if (deleted > 0) await batch.commit();

      console.log(`Cleaned up ${deleted} stale notifications`);
    } catch (error) {
      console.error('[cleanupNotifications] Error:', error);
    }
  });

module.exports = { onNotificationCreated, registerFcmToken, cleanupNotifications };
