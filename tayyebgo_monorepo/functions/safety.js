const { functions, admin, db } = require('./config');

const onSOSEmergency = functions.firestore.onDocumentCreated(
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

const validateOrderPricing = functions.firestore.onDocumentCreated(
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
      const menuSnapshot = await db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .get();

      const menuPrices = {};
      menuSnapshot.forEach(doc => {
        const menuData = doc.data();
        menuPrices[doc.id] = {
          price: menuData.price || 0,
          name: menuData.name || 'Unknown',
        };
      });

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

      const deliveryFee = Math.max(0, Math.min(order.deliveryFee || 0, 50));
      const taxRate = Math.max(0, Math.min(order.taxRate || 0, 0.3));
      const tip = Math.max(0, Math.min(order.tip || 0, 100));
      const discount = Math.max(0, Math.min(order.discount || 0, expectedTotal));

      expectedTotal += deliveryFee;
      expectedTotal += expectedTotal * taxRate;
      expectedTotal += tip;
      expectedTotal -= discount;

      const expectedCents = Math.round(expectedTotal * 100);
      const clientCents = order.totalAmount || 0;

      if (Math.abs(expectedCents - clientCents) > 1) {
        console.warn(
          `[validateOrderPricing] Order ${orderId} price mismatch: ` +
          `expected=${expectedCents}cents, client=${clientCents}cents. ` +
          `Correcting.`
        );

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
        await snap.ref.update({
          serverValidated: true,
          validatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log(`[validateOrderPricing] Order ${orderId} validated: expected=${expectedCents}cents, client=${clientCents}cents`);
    } catch (error) {
      console.error(`[validateOrderPricing] Error validating order ${orderId}:`, error);
    }
  }
);

module.exports = { onSOSEmergency, validateOrderPricing };
