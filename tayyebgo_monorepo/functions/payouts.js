const { functions, admin, db } = require('./config');

const processPayouts = functions.scheduler.onSchedule('0 6 * * *', async () => {
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

    const vendors = Object.entries(vendorOrders);
    let processed = 0;

    // S8 FIX: Process in chunks of 400 to avoid batch size limit
    for (let i = 0; i < vendors.length; i += 400) {
      const chunk = vendors.slice(i, i + 400);
      const batch = db.batch();

      for (const [vendorId, orders] of chunk) {
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

        processed++;
      }

      await batch.commit();
    }

    console.log(`[processPayouts] Created ${processed} payouts`);
  } catch (error) {
    console.error('[processPayouts] Error:', error);
    throw error;
  }
});

module.exports = { processPayouts };
