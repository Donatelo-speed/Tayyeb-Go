const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY) {
  console.warn('OPENAI_API_KEY not set. AI features will fail.');
}

// ─── Rate Limiter ────────────────────────────────────────────────────
// Simple Firestore-based rate limiter per user per function.
// Usage: await rateLimit(request.auth.uid, 'functionName', { maxRequests: 10, windowMs: 60000 });
async function rateLimit(uid, fnName, { maxRequests = 10, windowMs = 60000 } = {}) {
  if (!uid) return { allowed: true };
  const now = Date.now();
  const windowStart = now - windowMs;
  const ref = db.collection('_rate_limits').doc(`${uid}_${fnName}`);
  try {
    const snap = await ref.get();
    if (!snap.exists) {
      await ref.set({ timestamps: [now], count: 1 });
      return { allowed: true };
    }
    const data = snap.data();
    const timestamps = (data.timestamps || []).filter(t => t > windowStart);
    if (timestamps.length >= maxRequests) {
      const oldest = timestamps[0];
      const retryAfterMs = oldest + windowMs - now;
      console.warn(`[rateLimit] ${uid} exceeded ${maxRequests}/${windowMs}ms on ${fnName}, retryAfter=${retryAfterMs}ms`);
      return { allowed: false, retryAfterMs };
    }
    timestamps.push(now);
    await ref.set({ timestamps, count: timestamps.length }, { merge: true });
    return { allowed: true };
  } catch (e) {
    console.error('[rateLimit] Error:', e);
    return { allowed: true }; // Fail open
  }
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

      // If the token is invalid, clear it
      if (err.code === 'messaging/invalid-registration-token' ||
          err.code === 'messaging/registration-token-not-registered') {
        await db.collection('users').doc(recipientId).update({ fcmToken: null });
      }
    }
  });

/**
 * Firestore-triggered function: when a dispatch request is created with
 * status 'pending', mark it 'scoring' and set needsAutoAssign so the
 * Flutter dispatcher can pick it up asynchronously.
 */
exports.onDispatchCreated = functions.firestore
  .onDocumentCreated('dispatch_requests/{dispatchId}', async (event) => {
    try {
      const snap = event.data;
      if (!snap) return;
      const data = snap.data();
      if (data.status !== 'pending') return;

      console.log(`Dispatch created: ${snap.id}, triggering auto-assign`);
      await snap.ref.update({
        status: 'scoring',
        needsAutoAssign: true,
        scoredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error('[onDispatchCreated] Error:', error);
    }
  });

/**
 * Firestore-triggered function: when a dispatch request is updated to
 * 'accepted', update the associated order's driverId and status.
 */
exports.onDispatchAccepted = functions.firestore
  .onDocumentUpdated('dispatch_requests/{dispatchId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== 'accepted') return;

    const orderId = after.orderId;
    const driverId = after.assignedDriverId;
    if (!orderId || !driverId) return;

    await db.collection('orders').doc(orderId).update({
      driverId: driverId,
      status: 'dispatched',
      dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch((err) => console.error(`Order update failed for ${orderId}:`, err.message));
  });

/**
 * Scheduled function: check for dispatch requests in 'awaiting_acceptance'
 * whose acceptanceDeadline has passed. Time them out and trigger reassignment.
 * Runs every 30 seconds.
 */
exports.checkDispatchTimeouts = functions.scheduler
  .onSchedule('*/30 * * * *', async () => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = new Date(now.toDate().getTime() - 45000);

    const timedOut = await db
      .collection('dispatch_requests')
      .where('status', '==', 'awaiting_acceptance')
      .where('acceptanceDeadline', '<', cutoff)
      .get();

    let timedOutCount = 0;
    for (const doc of timedOut.docs) {
      const data = doc.data();
      const previousDriverId = data.assignedDriverId;

      await doc.ref.update({
        status: 'timedOut',
        timedOutAt: admin.firestore.FieldValue.serverTimestamp(),
        previousDriverId: previousDriverId,
      });

      if (previousDriverId) {
        await db.collection('users').doc(previousDriverId).update({
          activeDeliveries: admin.firestore.FieldValue.increment(-1),
          currentOrderId: admin.firestore.FieldValue.delete(),
        }).catch(() => {});
      }

      await db.collection('dispatch_requests').doc(doc.id).update({
        status: 'reassigning',
        needsReassign: true,
      });

      timedOutCount++;
    }

    if (timedOutCount > 0) {
      console.log(`Timed out ${timedOutCount} expired dispatch requests`);
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

  // Rate limiting
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

/**
 * Scheduled function: clean up stale notification docs older than 30 days.
 * Runs daily at midnight UTC.
 */
exports.cleanupNotifications = functions.scheduler
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

/**
 * Helper: check if the caller is a super admin using Firestore as source of truth.
 */
async function isSuperAdmin(request) {
  if (!request.auth) return false;
  try {
    const userDoc = await db.collection('users').doc(request.auth.uid).get();
    if (!userDoc.exists) return false;
    return userDoc.data().role === 'superAdmin';
  } catch {
    return false;
  }
}

/**
 * HTTP-callable function: set a user's role in Firestore.
 * Only super admins can call this.
 * Firestore is the single source of truth — no custom claims are set.
 */
exports.setUserRole = functions.https.onCall(async (request) => {
  if (!(await isSuperAdmin(request))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only super admins can change roles'
    );
  }

  const { uid, role, restaurantId } = request.data;
  if (!uid || !role) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'uid and role are required'
    );
  }

  const validRoles = ['superAdmin', 'restaurantOwner', 'cashier', 'driver', 'customer'];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid role. Must be one of: ${validRoles.join(', ')}`
    );
  }

  try {
    const updates = {
      role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (restaurantId) {
      updates.restaurantId = restaurantId;
    } else if (role === 'customer' || role === 'driver') {
      updates.restaurantId = admin.firestore.FieldValue.delete();
    }
    await db.collection('users').doc(uid).update(updates);

    console.log(`Role set: ${uid} -> ${role}${restaurantId ? ` (restaurant: ${restaurantId})` : ''}`);
    return { success: true };
  } catch (err) {
    console.error('setUserRole error:', err.message);
    throw new functions.https.HttpsError('internal', err.message);
  }
});

/**
 * HTTP-callable function: get a user's role from Firestore (for debugging).
 * Only super admins can call this.
 */
exports.getUserRole = functions.https.onCall(async (request) => {
  if (!(await isSuperAdmin(request))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only super admins can read user roles'
    );
  }

  const { uid } = request.data;
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'uid is required');
  }

  try {
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return { uid, role: null, message: 'User document not found' };
    }
    const data = doc.data();
    return {
      uid,
      email: data.email || null,
      role: data.role || null,
      displayName: data.displayName || null,
      isActive: data.isActive ?? true,
    };
  } catch (err) {
    throw new functions.https.HttpsError('internal', err.message);
  }
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
  const rl = await rateLimit(request.auth.uid, 'processAiMenuImage', { maxRequests: 5, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { base64Image, prompt } = request.data;
  if (!base64Image) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'base64Image is required'
    );
  }

  // SECURITY: Validate base64 size limit (~10MB)
  const maxBase64Length = 13333334; // ~10MB in base64
  if (base64Image.length > maxBase64Length) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Image too large. Maximum size is 10MB.'
    );
  }

  if (!OPENAI_API_KEY) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured on server'
    );
  }

  // SECURITY: Sanitize prompt — only allow safe prompt text, reject injection attempts
  const safePrompt = 'Extract all menu items from this image. Return JSON array with: name, price (as number), category, description (optional). Arabic text supported.';

  try {
    const https = require('https');

    const response = await new Promise((resolve, reject) => {
      const body = JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: safePrompt },
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
      'AI processing failed. Please try again.'
    );
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE PAYMENT FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
let stripeInstance = null;

function getStripe() {
  if (!stripeInstance) {
    if (!STRIPE_SECRET_KEY) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'STRIPE_SECRET_KEY not configured'
      );
    }
    stripeInstance = require('stripe')(STRIPE_SECRET_KEY);
  }
  return stripeInstance;
}

/**
 * HTTP-callable: Create a Stripe PaymentIntent for order checkout.
 * Returns { clientSecret, paymentIntentId } for the Flutter app to confirm.
 */
exports.createStripePaymentIntent = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  const rl = await rateLimit(request.auth.uid, 'createStripePaymentIntent', { maxRequests: 10, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { amountInCents, currency, orderId, metadata } = request.data;
  if (!amountInCents || amountInCents < 50) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount must be at least 50 cents');
  }

  // SECURITY: Max amount cap ($10,000 = 1,000,000 cents)
  if (amountInCents > 1000000) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount exceeds maximum allowed');
  }

  // SECURITY: Validate currency against Stripe's supported list
  const validCurrencies = ['usd', 'eur', 'gbp', 'cad', 'aud', 'sar', 'aed', 'qar', 'bhd', 'kwd', 'omr', 'jod', 'lbp', 'egp', 'try', 'inr', 'pkr'];
  const finalCurrency = (currency || 'usd').toLowerCase();
  if (!validCurrencies.includes(finalCurrency)) {
    throw new functions.https.HttpsError('invalid-argument', 'Unsupported currency');
  }

  try {
    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: finalCurrency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        orderId: orderId || '',
        userId: request.auth.uid,
      },
    });

    await db.collection('payment_intents').doc(paymentIntent.id).set({
      orderId: orderId || null,
      userId: request.auth.uid,
      amountInCents,
      currency: currency || 'usd',
      method: 'stripe',
      status: 'created',
      stripePaymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (err) {
    console.error('createStripePaymentIntent error:', err.message);
    throw new functions.https.HttpsError('internal', 'Payment processing failed. Please try again.');
  }
});

/**
 * HTTP-callable: Create a Stripe PaymentIntent for wallet top-up.
 * Returns { clientSecret, paymentIntentId } for the Flutter app to confirm.
 */
exports.createWalletTopUpIntent = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  // Rate limiting
  const rl = await rateLimit(request.auth.uid, 'createWalletTopUpIntent', { maxRequests: 10, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { amountInCents, currency } = request.data;
  if (!amountInCents || amountInCents < 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Minimum top-up is $1.00');
  }
  if (amountInCents > 100000) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum top-up is $1,000');
  }

  // Validate currency
  const validCurrencies = ['usd', 'eur', 'gbp', 'cad', 'aud', 'sar', 'aed', 'qar', 'bhd', 'kwd', 'omr', 'jod', 'lbp', 'egp', 'try', 'inr', 'pkr'];
  const finalCurrency = (currency || 'usd').toLowerCase();
  if (!validCurrencies.includes(finalCurrency)) {
    throw new functions.https.HttpsError('invalid-argument', 'Unsupported currency');
  }

  try {
    const stripe = getStripe();
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: finalCurrency,
      automatic_payment_methods: { enabled: true },
      metadata: {
        type: 'wallet_topup',
        userId: request.auth.uid,
      },
    });

    await db.collection('payment_intents').doc(paymentIntent.id).set({
      userId: request.auth.uid,
      type: 'wallet_topup',
      amountInCents,
      currency: finalCurrency,
      status: 'created',
      stripePaymentIntentId: paymentIntent.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (err) {
    console.error('createWalletTopUpIntent error:', err.message);
    throw new functions.https.HttpsError('internal', 'Payment processing failed. Please try again.');
  }
});

/**
 * HTTP-callable: Confirm a wallet top-up after Stripe succeeds.
 * Atomically updates wallet balance and records the transaction.
 */
exports.confirmWalletTopUp = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  const rl = await rateLimit(request.auth.uid, 'confirmWalletTopUp', { maxRequests: 10, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { paymentIntentId } = request.data;
  if (!paymentIntentId) {
    throw new functions.https.HttpsError('invalid-argument', 'paymentIntentId required');
  }

  try {
    const stripe = getStripe();
    const pi = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (pi.status !== 'succeeded') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `PaymentIntent status is ${pi.status}, expected succeeded`
      );
    }

    const intentDoc = await db.collection('payment_intents').doc(paymentIntentId).get();
    if (!intentDoc.exists || intentDoc.data().status === 'completed') {
      return { success: true, message: 'Already processed' };
    }

    const amountInDollars = pi.amount / 100;
    const userId = request.auth.uid;
    const userRef = db.collection('users').doc(userId);

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const currentBalance = userSnap.data()?.walletBalance ?? 0;
      tx.update(userRef, {
        walletBalance: currentBalance + amountInDollars,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('wallet_transactions').doc(), {
        userId,
        type: 'topup',
        amount: amountInDollars,
        description: 'Wallet top-up via card',
        paymentIntentId,
        currency: pi.currency,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('payment_intents').doc(paymentIntentId), {
        status: 'completed',
        confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    return { success: true, newBalance: amountInDollars };
  } catch (err) {
    console.error('confirmWalletTopUp error:', err.message);
    throw new functions.https.HttpsError('internal', err.message);
  }
});

/**
 * HTTP-callable: Transfer funds between two user wallets (peer-to-peer).
 * Uses Firestore transaction for atomic balance update.
 */
exports.transferWalletFunds = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  const rl = await rateLimit(request.auth.uid, 'transferWalletFunds', { maxRequests: 5, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { recipientId, amountInDollars, note } = request.data;
  if (!recipientId || !amountInDollars || amountInDollars <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'recipientId and positive amount required');
  }
  if (recipientId === request.auth.uid) {
    throw new functions.https.HttpsError('invalid-argument', 'Cannot send to yourself');
  }
  if (amountInDollars > 500) {
    throw new functions.https.HttpsError('invalid-argument', 'Maximum transfer is $500');
  }

  try {
    const senderId = request.auth.uid;
    const senderRef = db.collection('users').doc(senderId);
    const recipientRef = db.collection('users').doc(recipientId);

    await db.runTransaction(async (tx) => {
      const senderSnap = await tx.get(senderRef);
      const recipientSnap = await tx.get(recipientRef);

      if (!recipientSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Recipient not found');
      }

      const senderBalance = senderSnap.data()?.walletBalance ?? 0;
      if (senderBalance < amountInDollars) {
        throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
      }

      const recipientBalance = recipientSnap.data()?.walletBalance ?? 0;

      tx.update(senderRef, {
        walletBalance: senderBalance - amountInDollars,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(recipientRef, {
        walletBalance: recipientBalance + amountInDollars,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const transferId = `xfer_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      tx.set(db.collection('wallet_transactions').doc(transferId), {
        userId: senderId,
        type: 'send',
        amount: amountInDollars,
        description: note ?? 'Wallet transfer',
        recipientId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('wallet_transactions').doc(), {
        userId: recipientId,
        type: 'receive',
        amount: amountInDollars,
        description: note ?? 'Wallet transfer',
        senderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { success: true };
  } catch (err) {
    console.error('transferWalletFunds error:', err.message);
    throw new functions.https.HttpsError('internal', err.message);
  }
});

/**
 * HTTP-callable: Process a driver payout request.
 * Marks payout as processing and records in Firestore.
 */
exports.processDriverPayout = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  const rl = await rateLimit(request.auth.uid, 'processDriverPayout', { maxRequests: 5, windowMs: 60000 });
  if (!rl.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', `Too many requests. Try again in ${Math.ceil(rl.retryAfterMs / 1000)}s`);
  }

  const { amountInCents, driverId, payoutMethod } = request.data;
  if (!amountInCents || amountInCents <= 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Positive amount required');
  }

  const uid = request.auth.uid;
  const targetDriverId = driverId || uid;

  // Only allow self-payout unless admin
  if (targetDriverId !== uid) {
    const callerDoc = await db.collection('users').doc(uid).get();
    if (callerDoc.data()?.role !== 'superAdmin') {
      throw new functions.https.HttpsError('permission-denied', 'Cannot process payout for another user');
    }
  }

  try {
    const walletRef = db.collection('driver_wallets').doc(targetDriverId);
    const walletSnap = await walletRef.get();

    if (!walletSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver wallet not found');
    }

    const walletData = walletSnap.data();
    const availableBalance = walletData.availableBalance ?? 0;
    const amountInDollars = amountInCents / 100;

    if (amountInDollars > availableBalance) {
      throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
    }

    const payoutId = `payout_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(walletRef);
      const bal = snap.data()?.availableBalance ?? 0;
      if (amountInDollars > bal) {
        throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
      }

      tx.update(walletRef, {
        availableBalance: bal - amountInDollars,
        totalWithdrawn: (snap.data()?.totalWithdrawn ?? 0) + amountInDollars,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('driver_payouts').doc(payoutId), {
        driverId: targetDriverId,
        amountInDollars,
        payoutMethod: payoutMethod ?? 'bank_transfer',
        status: 'pending',
        requestedBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('wallet_transactions').doc(), {
        userId: targetDriverId,
        type: 'payout',
        amount: amountInDollars,
        description: 'Payout request',
        payoutId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { success: true, payoutId };
  } catch (err) {
    console.error('processDriverPayout error:', err.message);
    throw new functions.https.HttpsError('internal', err.message);
  }
});

// ─── Daily Vendor Payouts ────────────────────────────────────────────
exports.processPayouts = functions.scheduler.onSchedule('0 6 * * *', async () => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  console.log(`[processPayouts] Running payout cycle for ${yesterday.toISOString()} — ${today.toISOString()}`);

  try {
    const snapshot = await db
      .collection('orders')
      .where('status', '==', 'delivered')
      .where('deliveredAt', '>=', yesterday)
      .where('deliveredAt', '<', today)
      .get();

    console.log(`[processPayouts] Found ${snapshot.size} completed orders`);

    const vendorOrders = {};
    snapshot.forEach(doc => {
      const order = doc.data();
      const vendorId = order.restaurantId;
      if (!vendorId) return;
      if (!vendorOrders[vendorId]) vendorOrders[vendorId] = [];
      vendorOrders[vendorId].push(order);
    });

    const batch = db.batch();
    for (const [vendorId, orders] of Object.entries(vendorOrders)) {
      const totalRevenue = orders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);
      const restaurantDoc = await db.collection('restaurants').doc(vendorId).get();
      const commissionRate = restaurantDoc.exists
        ? (restaurantDoc.data().commissionRate || 0.15)
        : 0.15;
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
        commissionRate,
        status: 'pending',
        orderCount: orders.length,
        periodStart: yesterday,
        periodEnd: today,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`[processPayouts] Payout for ${vendorId}: net ${netAmount} (${orders.length} orders)`);
    }

    await batch.commit();
    console.log(`[processPayouts] Created ${Object.keys(vendorOrders).length} payouts`);
  } catch (error) {
    console.error('[processPayouts] Error:', error);
    throw error;
  }
});

// ─── SOS Emergency Alert ─────────────────────────────────────────────
exports.onSOSEmergency = functions.firestore.onDocumentCreated(
  'sos_alerts/{sosId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const sos = snap.data();
    if (!sos) return;

    console.log(`[onSOSEmergency] SOS ${event.params.sosId} from driver ${sos.driverId}`);

    try {
      const notifRef = db.collection('notifications').doc();
      await notifRef.set({
        id: notifRef.id,
        recipientId: 'admin',
        type: 'sos_emergency',
        driverId: sos.driverId,
        title: 'SOS EMERGENCY',
        body: `Driver ${sos.driverName || sos.driverId} triggered SOS at ${sos.latitude || 'unknown'}, ${sos.longitude || 'unknown'}`,
        location: {
          latitude: sos.latitude || 0,
          longitude: sos.longitude || 0,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        priority: 'high',
      });

      console.log(`[onSOSEmergency] Notified admin for SOS ${event.params.sosId}`);
    } catch (error) {
      console.error('[onSOSEmergency] Error:', error);
    }
  }
);

// ─── Server-Side Order Validation ────────────────────────────────────
// Validates order amounts against restaurant menu prices to prevent
// client-side price manipulation. Runs as a Firestore trigger on order creation.
exports.validateOrderPricing = functions.firestore.onDocumentCreated(
  'orders/{orderId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const order = snap.data();
    if (!order) return;

    const orderId = event.params.orderId;
    const restaurantId = order.restaurantId;
    const items = order.items;

    if (!restaurantId || !items || !Array.isArray(items) || items.length === 0) {
      console.log(`[validateOrderPricing] Order ${orderId} missing restaurantId or items, skipping`);
      return;
    }

    console.log(`[validateOrderPricing] Validating order ${orderId} with ${items.length} items`);

    try {
      // Fetch menu items from the restaurant's menu subcollection
      const menuSnapshot = await db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .get();

      // Build price lookup: itemId -> { price, name }
      const menuPrices = {};
      menuSnapshot.forEach(doc => {
        const menuData = doc.data();
        menuPrices[doc.id] = {
          price: menuData.price || 0,
          name: menuData.name || 'Unknown',
        };
      });

      // Calculate expected total from menu prices
      let expectedTotal = 0;
      let unknownItems = [];
      for (const item of items) {
        const menuItem = menuPrices[item.itemId || item.id];
        if (menuItem) {
          const itemPrice = menuItem.price;
          const quantity = item.quantity || 1;
          const modifiers = item.modifiers || [];
          const modifierUpcharge = modifiers.reduce((sum, m) => sum + (m.price || 0), 0);
          expectedTotal += (itemPrice + modifierUpcharge) * quantity;
        } else {
          unknownItems.push(item.itemId || item.id);
          console.warn(`[validateOrderPricing] Menu item ${item.itemId || item.id} not found in restaurant menu`);
        }
      }

      // SECURITY: Reject orders with unknown menu items (prevents free items via spoofing)
      if (unknownItems.length > 0) {
        console.warn(`[validateOrderPricing] Order ${orderId} has ${unknownItems.length} unknown items: ${unknownItems.join(', ')}`);
        await snap.ref.update({
          serverValidated: false,
          validationError: 'unknown_menu_items',
          unknownItems: unknownItems,
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return;
      }

      // SECURITY: Validate fee bounds (prevent client-side manipulation)
      const deliveryFee = Math.max(0, Math.min(order.deliveryFee || 0, 50)); // Max $50 delivery fee
      const taxRate = Math.max(0, Math.min(order.taxRate || 0, 0.3)); // Max 30% tax
      const tip = Math.max(0, Math.min(order.tip || 0, 100)); // Max $100 tip
      const discount = Math.max(0, Math.min(order.discount || 0, expectedTotal)); // Can't discount more than total

      // Apply validated fees
      expectedTotal += deliveryFee;
      expectedTotal += expectedTotal * taxRate;
      expectedTotal += tip;
      expectedTotal -= discount;

      // Convert to cents for comparison (client sends totalAmountInCents)
      const expectedCents = Math.round(expectedTotal * 100);
      const clientCents = order.totalAmount || 0;

      // Allow 1 cent tolerance for rounding
      if (Math.abs(expectedCents - clientCents) > 1) {
        console.warn(
          `[validateOrderPricing] Order ${orderId} price mismatch: ` +
          `expected=${expectedCents}cents, client=${clientCents}cents. ` +
          `Correcting.`
        );

        // Correct the order amount server-side
        await snap.ref.update({
          totalAmount: expectedCents,
          serverValidated: true,
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
          priceAdjustment: {
            original: clientCents,
            corrected: expectedCents,
            reason: 'server_side_validation',
          },
        });
      } else {
        // Mark as validated
        await snap.ref.update({
          serverValidated: true,
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`[validateOrderPricing] Order ${orderId} validated: expected=${expectedCents}cents, client=${clientCents}cents`);
    } catch (error) {
      console.error(`[validateOrderPricing] Error validating order ${orderId}:`, error);
      // Don't throw — order should still be processable even if validation fails
    }
  }
);

// ─── validatePromo ────────────────────────────────────────────────────
// Callable function: validates a promo code server-side and records usage.
// Returns: { valid, discount, type, value, message }
exports.validatePromo = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { code, subtotalCents, restaurantId } = request.data;
  if (!code || typeof code !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Promo code required');
  }

  const rateCheck = await rateLimit(request.auth.uid, 'validatePromo', { maxRequests: 20, windowMs: 60000 });
  if (!rateCheck.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', 'Too many requests. Please try again later.');
  }

  const normalizedCode = code.trim().toUpperCase();

  try {
    const promoQuery = await db.collection('promos')
      .where('code', '==', normalizedCode)
      .limit(1)
      .get();

    if (promoQuery.empty) {
      return { valid: false, message: 'Invalid promo code' };
    }

    const promoDoc = promoQuery.docs[0];
    const promo = promoDoc.data();

    const isActive = promo.isActive ?? promo.active ?? false;
    if (!isActive) {
      return { valid: false, message: 'This promo code is no longer active' };
    }

    if (promo.expiryDate && promo.expiryDate.toDate() < new Date()) {
      return { valid: false, message: 'This promo code has expired' };
    }

    if (promo.usageLimit > 0 && (promo.usageCount || 0) >= promo.usageLimit) {
      return { valid: false, message: 'This promo code has reached its usage limit' };
    }

    const minOrder = (promo.minOrderAmount ?? promo.minOrder ?? 0) * 100;
    if (subtotalCents && subtotalCents < minOrder) {
      return { valid: false, message: `Minimum order of $${(minOrder / 100).toFixed(2)} required` };
    }

    if (restaurantId && promo.restaurantId && promo.restaurantId !== restaurantId) {
      return { valid: false, message: 'This promo code is not valid for this restaurant' };
    }

    const subtotal = (subtotalCents || 0) / 100;
    let discount = 0;
    const type = promo.type || 'percentage';
    const value = promo.value || 0;
    const maxDiscount = promo.maxDiscountAmount || promo.maxDiscount || 0;

    if (type === 'percentage') {
      discount = subtotal * (value / 100);
      if (maxDiscount > 0 && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      discount = value;
    }

    discount = Math.min(discount, subtotal);

    await db.collection('promo_usage').add({
      promoCode: normalizedCode,
      customerId: request.auth.uid,
      discountAmount: discount,
      subtotalCents: subtotalCents || 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await promoDoc.ref.update({
      usageCount: (promo.usageCount || 0) + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[validatePromo] Code ${normalizedCode} validated for user ${request.auth.uid}, discount=${discount}`);

    return {
      valid: true,
      discount,
      type,
      value,
      message: `Discount applied: $${discount.toFixed(2)}`,
    };
  } catch (error) {
    console.error(`[validatePromo] Error:`, error);
    throw new functions.https.HttpsError('internal', 'Failed to validate promo code');
  }
});
