const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPENAI_API_KEY) {
  console.warn('OPENAI_API_KEY not set. AI features will fail.');
}

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

module.exports = { functions, admin, db, OPENAI_API_KEY, rateLimit, isSuperAdmin };
