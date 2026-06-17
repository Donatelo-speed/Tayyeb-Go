const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Logs an admin action to the audit_log collection.
 * Call from client: firebase.functions().httpsCallable('logAuditEvent')({...})
 */
exports.logAuditEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const callerUid = context.auth.uid;
  const callerDoc = await db.collection('users').doc(callerUid).get();
  const callerRole = callerDoc.data()?.role;

  if (callerRole !== 'admin' && callerRole !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const { action, targetType, targetId, details } = data;

  if (!action || !targetType) {
    throw new functions.https.HttpsError('invalid-argument', 'action and targetType required');
  }

  await db.collection('audit_log').add({
    action,
    targetType,
    targetId: targetId || '',
    details: details || {},
    actorId: callerUid,
    actorRole: callerRole,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ip: context.rawRequest?.headers?.['x-forwarded-for'] || 'unknown',
  });

  return { success: true };
});

/**
 * Firestore trigger: logs when a user document is updated with sensitive fields.
 */
exports.onUserSensitiveUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    const sensitiveFields = ['role', 'isBlocked', 'isVerified', 'commissionPercent', 'phone', 'email'];
    const changes = {};

    for (const field of sensitiveFields) {
      if (before[field] !== after[field]) {
        changes[field] = { from: before[field], to: after[field] };
      }
    }

    if (Object.keys(changes).length === 0) return null;

    await db.collection('audit_log').add({
      action: 'user_field_update',
      targetType: 'user',
      targetId: userId,
      details: { changedFields: changes },
      actorId: after.updatedBy || 'system',
      actorRole: 'system_trigger',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * Firestore trigger: logs when an order status changes.
 */
exports.onOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    if (before.status === after.status) return null;

    await db.collection('audit_log').add({
      action: 'order_status_change',
      targetType: 'order',
      targetId: orderId,
      details: {
        fromStatus: before.status,
        toStatus: after.status,
        customerId: after.customerId,
        driverId: after.driverId,
        restaurantId: after.restaurantId,
      },
      actorId: after.updatedBy || 'system',
      actorRole: 'system_trigger',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * Returns recent audit log entries (admin only).
 */
exports.getAuditLog = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const callerDoc = await db.collection('users').doc(context.auth.uid).get();
  const callerRole = callerDoc.data()?.role;

  if (callerRole !== 'admin' && callerRole !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin only');
  }

  const { targetType, targetId, limit = 50 } = data || {};

  let query = db.collection('audit_log').orderBy('timestamp', 'desc').limit(limit);

  if (targetType) query = query.where('targetType', '==', targetType);
  if (targetId) query = query.where('targetId', '==', targetId);

  const snap = await query.get();
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
});
