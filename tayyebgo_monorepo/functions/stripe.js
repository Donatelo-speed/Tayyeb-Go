const { functions, admin, db, rateLimit } = require('./config');

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

const createStripePaymentIntent = functions.https.onCall(async (request) => {
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

  if (amountInCents > 1000000) {
    throw new functions.https.HttpsError('invalid-argument', 'Amount exceeds maximum allowed');
  }

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

const createWalletTopUpIntent = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

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

const confirmWalletTopUp = functions.https.onCall(async (request) => {
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
      const userId = request.auth.uid;
      const userSnap = await db.collection('users').doc(userId).get();
      const currentBalance = userSnap.data()?.walletBalance ?? 0;
      return { success: true, newBalance: currentBalance, message: 'Already processed' };
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

    const updatedUserSnap = await db.collection('users').doc(userId).get();
    const actualNewBalance = updatedUserSnap.data()?.walletBalance ?? amountInDollars;
    return { success: true, newBalance: actualNewBalance };
  } catch (err) {
    console.error('confirmWalletTopUp error:', err.message);
    throw new functions.https.HttpsError('internal', err.message);
  }
});

const transferWalletFunds = functions.https.onCall(async (request) => {
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

const processDriverPayout = functions.https.onCall(async (request) => {
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

module.exports = {
  createStripePaymentIntent,
  createWalletTopUpIntent,
  confirmWalletTopUp,
  transferWalletFunds,
  processDriverPayout,
};
