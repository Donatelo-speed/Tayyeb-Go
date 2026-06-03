const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY) {
  console.warn('OPENAI_API_KEY not set. AI features will fail.');
}

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

  // Only allow registering own FCM token
  if (!request.auth || request.auth.uid !== uid) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Can only register own FCM token'
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

/**
 * HTTP-callable function: proxy AI requests to OpenAI.
 * Requires authentication.
 * Called from Flutter app instead of calling OpenAI directly.
 */
exports.processAiMenuImage = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const { base64Image, prompt } = request.data;
  if (!base64Image) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'base64Image is required'
    );
  }

  if (!OPENAI_API_KEY) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured on server'
    );
  }

  const finalPrompt = prompt || 'Extract all menu items from this image. Return JSON array with: name, price (as number), category, description (optional). Arabic text supported.';

  try {
    const https = require('https');

    const response = await new Promise((resolve, reject) => {
      const body = JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: finalPrompt },
              { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
            ],
          },
        ],
        response_format: { type: 'json_object' },
      });

      const req = https.request(
        'https://api.openai.com/v1/chat/completions',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${OPENAI_API_KEY}`,
          },
        },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            try {
              resolve({ status: res.statusCode, body: JSON.parse(data) });
            } catch {
              reject(new Error('Invalid JSON from OpenAI'));
            }
          });
        }
      );

      req.on('error', reject);
      req.write(body);
      req.end();
    });

    if (response.status !== 200) {
      console.error('OpenAI error:', response.body);
      throw new functions.https.HttpsError(
        'internal',
        `AI processing failed (${response.status})`
      );
    }

    return { result: response.body };
  } catch (err) {
    console.error('AI proxy error:', err.message);
    throw new functions.https.HttpsError(
      'internal',
      err.message || 'AI processing failed'
    );
  }
});
