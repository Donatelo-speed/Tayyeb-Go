const { functions, admin, db, rateLimit } = require('./config');

const validatePromo = functions.https.onCall(async (request) => {
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

module.exports = { validatePromo };
