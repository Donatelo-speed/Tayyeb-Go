const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Firestore-triggered function: when a notification doc is written,
 * attempt to send FCM push to the recipient's device token.
 *
 * Collection: `notifications`
 * Expected doc fields:
 *   - recipientId: string (user UID)
 *   - role: 'customer' | 'driver' | 'partner'
 *   - title: string
 *   - body: string
 *   - type: string
 *   - orderId?: string
 */
exports.onNotificationCreated = functions.firestore
  .onDocumentCreated('notifications/{notificationId}', async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { recipientId, role, title, body, type, orderId } = data;
    if (!recipientId || !title || !body) return;

    try {
      // Look up the user's FCM token from their profile
      const userSnap = await db.collection('Users').doc(recipientId).get();
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

      // If the token is invalid, clear it
      if (err.code === 'messaging/invalid-registration-token' ||
          err.code === 'messaging/registration-token-not-registered') {
        await db.collection('Users').doc(recipientId).update({ fcmToken: null });
      }
    }
  });

/**
 * HTTP-callable function: store an FCM token for a user after login.
 * Called from the Flutter app.
 */
exports.registerFcmToken = functions.https.onCall(async (request) => {
  const { uid, token } = request.data;
  if (!uid || !token) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'uid and token are required'
    );
  }

  await db.collection('Users').doc(uid).update({ fcmToken: token });
  return { success: true };
});

/**
 * Scheduled function: clean up stale notification docs older than 30 days.
 * Runs daily at midnight UTC.
 */
exports.cleanupNotifications = functions.scheduler
  .onSchedule('0 0 * * *', async () => {
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
  });
