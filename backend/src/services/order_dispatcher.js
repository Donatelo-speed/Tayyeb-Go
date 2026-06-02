'use strict';

/**
 * OrderDispatcher
 *
 * Background service that:
 *   1. Watches for newly-created orders (status = 'pending').
 *   2. Finds the nearest available online driver within MAX_RADIUS_KM.
 *   3. Offers the order to the driver with a WINDOW_SEC countdown.
 *   4. If rejected or timed-out, cascades to the next nearest driver.
 *   5. If no driver is found within MAX_ATTEMPTS, places the order in a
 *      manual-review queue and alerts the admin channel.
 */

const Order = require('../models/Order');

const POLL_INTERVAL_MS = 5_000;   // How often to scan for unassigned orders
const WINDOW_SEC       = 30;      // Accept/reject window per driver
const MAX_RADIUS_KM    = 10;      // Only offer orders to drivers within 10 km
const MAX_ATTEMPTS     = 5;       // Max driver cascade before flagging

class OrderDispatcher {
  /**
   * @param {object} deps
   * @param {object} deps.driverRoutes   - The driver route module (exposes helpers)
   * @param {Function} deps.notifyVendor   - WS broadcast to vendor
   * @param {Function} deps.notifyCustomer - WS broadcast to customer
   */
  constructor({ driverRoutes, notifyVendor, notifyCustomer }) {
    this._driverRoutes    = driverRoutes;
    this._notifyVendor    = notifyVendor;
    this._notifyCustomer  = notifyCustomer;

    /** Orders currently being offered to a driver. orderId → { attempts, lastOfferedTo, timer } */
    this._inFlight = new Map();

    this._pollTimer = null;
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  start() {
    console.log('[Dispatcher] Started. Poll interval:', POLL_INTERVAL_MS, 'ms');
    this._pollTimer = setInterval(() => this._poll(), POLL_INTERVAL_MS);
  }

  stop() {
    if (this._pollTimer) clearInterval(this._pollTimer);
    for (const { timer } of this._inFlight.values()) clearTimeout(timer);
    this._inFlight.clear();
    console.log('[Dispatcher] Stopped.');
  }

  // ─── Poll ───────────────────────────────────────────────────────────────────

  async _poll() {
    try {
      // Find orders that are pending and NOT already being dispatched.
      const inFlightIds = [...this._inFlight.keys()];

      const orders = await Order.find({
        status:       'pending',
        assignedDriver: { $exists: false },
        _id:          { $nin: inFlightIds },
      })
        .sort({ createdAt: 1 }) // FIFO
        .limit(20)
        .lean();

      for (const order of orders) {
        this._dispatchOrder(order).catch((err) => {
          console.error('[Dispatcher] Error dispatching order:', order._id, err.message);
        });
      }
    } catch (err) {
      console.error('[Dispatcher] Poll error:', err.message);
    }
  }

  // ─── Dispatch ───────────────────────────────────────────────────────────────

  async _dispatchOrder(order) {
    const orderId = order._id.toString();

    if (this._inFlight.has(orderId)) return; // already being handled

    this._inFlight.set(orderId, { attempts: 0, lastOfferedTo: null, timer: null });
    await this._offerToNextDriver(order);
  }

  async _offerToNextDriver(order) {
    const orderId  = order._id.toString();
    const state    = this._inFlight.get(orderId);

    if (!state) return;

    if (state.attempts >= MAX_ATTEMPTS) {
      console.warn('[Dispatcher] No driver accepted order', orderId, '— escalating.');
      await Order.findByIdAndUpdate(orderId, {
        $set:  { status: 'dispatch_failed' },
        $push: { statusHistory: { status: 'dispatch_failed', timestamp: new Date() } },
      });
      this._inFlight.delete(orderId);
      // Notify admin via vendor channel (admin vendorId = 'admin').
      this._notifyVendor('admin', {
        action:  'dispatch_failed',
        orderId,
        order,
      });
      return;
    }

    // Find nearest available drivers.
    const availableIds = this._driverRoutes.getAvailableDriverIds();
    const skip         = state.lastOfferedTo ? [state.lastOfferedTo] : [];
    const candidates   = availableIds.filter(id => !skip.includes(id));

    if (candidates.length === 0) {
      // No drivers available right now — retry on next poll.
      this._inFlight.delete(orderId);
      return;
    }

    // Sort by distance to restaurant.
    const restaurantLat = order.restaurantGps?.lat ?? 33.51;
    const restaurantLng = order.restaurantGps?.lng ?? 36.28;

    const sorted = candidates
      .map(driverId => {
        const pos = this._driverRoutes.getDriverPosition(driverId);
        if (!pos?.lat) return null;
        const dist = haversineKm(restaurantLat, restaurantLng, pos.lat, pos.lng);
        return { driverId, dist };
      })
      .filter(Boolean)
      .filter(({ dist }) => dist <= MAX_RADIUS_KM)
      .sort((a, b) => a.dist - b.dist);

    if (sorted.length === 0) {
      this._inFlight.delete(orderId);
      return;
    }

    const { driverId, dist } = sorted[0];
    const estimatedEarnings  = _estimateEarnings(order.deliveryFee, dist);

    state.attempts++;
    state.lastOfferedTo = driverId;

    const offered = this._driverRoutes.dispatchOrderToDriver(
      driverId,
      order,
      { distanceKm: dist, earnings: estimatedEarnings, windowSec: WINDOW_SEC }
    );

    if (!offered) {
      // Driver became unavailable between our check and offer — cascade.
      await this._offerToNextDriver(order);
      return;
    }

    console.log(
      `[Dispatcher] Order ${orderId} → Driver ${driverId} (${dist.toFixed(1)} km, attempt ${state.attempts})`
    );

    // Set a timer: if driver doesn't accept within WINDOW_SEC, cascade.
    state.timer = setTimeout(async () => {
      const currentOrder = await Order.findById(orderId).lean();
      // If the order was already accepted by someone, stop.
      if (!currentOrder || currentOrder.status !== 'pending') {
        this._inFlight.delete(orderId);
        return;
      }
      console.log(`[Dispatcher] Order ${orderId} timed out for driver ${driverId} — cascading.`);
      await this._offerToNextDriver(order);
    }, (WINDOW_SEC + 2) * 1000); // +2 s grace
  }

  /**
   * Called by the order routes when a driver explicitly accepts (so we can
   * cancel the cascade timer immediately).
   */
  orderAccepted(orderId, driverId) {
    const state = this._inFlight.get(orderId);
    if (state?.timer) clearTimeout(state.timer);
    this._inFlight.delete(orderId);
    console.log(`[Dispatcher] Order ${orderId} accepted by driver ${driverId}.`);
  }
}

// ─── Haversine distance (km) ──────────────────────────────────────────────────

function haversineKm(lat1, lng1, lat2, lng2) {
  const R  = 6371;
  const dLat = _toRad(lat2 - lat1);
  const dLng = _toRad(lng2 - lng1);
  const a  =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(_toRad(lat1)) * Math.cos(_toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function _toRad(deg) { return (deg * Math.PI) / 180; }

// ─── Earnings estimate ────────────────────────────────────────────────────────

function _estimateEarnings(deliveryFee = 0, distanceKm = 0) {
  // Base: 80% of the delivery fee + $0.20 per km.
  return +(deliveryFee * 0.8 + distanceKm * 0.2).toFixed(2);
}

module.exports = OrderDispatcher;
