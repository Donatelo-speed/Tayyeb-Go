const { functions, admin, db, isSuperAdmin } = require('./config');

const setUserRole = functions.https.onCall(async (request) => {
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
    const claims = { role };
    if (restaurantId) claims.restaurantId = restaurantId;

    await admin.auth().setCustomUserClaims(uid, claims);

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

const getUserRole = functions.https.onCall(async (request) => {
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

module.exports = { setUserRole, getUserRole };
