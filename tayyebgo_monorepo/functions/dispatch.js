const { functions, admin, db } = require('./config');

const onDispatchCreated = functions.firestore
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

const onDispatchAccepted = functions.firestore
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

const checkDispatchTimeouts = functions.scheduler
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

module.exports = { onDispatchCreated, onDispatchAccepted, checkDispatchTimeouts };
