/**
 * /api/driver
 *
 * Driver status management:
 *   POST /api/driver/status         — set online / offline
 *   GET  /api/driver/status         — read current status
 *   POST /api/driver/location       — broadcast GPS position
 *   GET  /api/driver/order/incoming — poll for a new dispatch offer
 *   POST /api/driver/order/:id/accept
 *   POST /api/driver/order/:id/reject
 *   POST /api/driver/order/:id/complete
 *   GET  /api/driver/earnings
 *
 * The module also exports `notifyDriver(driverId, payload)` which the order
 * dispatcher calls to push order notifications via WebSocket.
 */

const express = require('express');
const router  = express.Router();
const mongoose = require('mongoose');
const { authenticate, requireRole } = require('../middleware/auth');
const Order  = require('../models/Order');

// In-memory driver state store.
// Production: replace with Redis for multi-instance deployments.
const _driverState = new Map();
// Map<driverId, { isOnline, lat, lng, lastSeen, pendingOrder: Order|null }>

// WebSocket registry set by server.js after ws upgrade.
// Map<driverId, WebSocket>
let _wsRegistry = null;

/**
 * Called by server.js to pass in the driver WS registry.
 * @param {Map<string, WebSocket>} registry
 */
function setWsRegistry(registry) {
  _wsRegistry = registry;
}

/**
 * Push a real-time order notification to a driver via WebSocket.
 * Falls back gracefully if the driver is not WS-connected.
 * @param {string} driverId
 * @param {object} payload  { type: 'new_order', order: {...}, ... }
 */
function notifyDriver(driverId, payload) {
  if (!_wsRegistry) return;
  const ws = _wsRegistry.get(driverId.toString());
  if (ws && ws.readyState === 1 /* OPEN */) {
    ws.send(JSON.stringify(payload));
  }
}

// ─── Helper: get or init state ────────────────────────────────────────────────

function getState(driverId) {
  const id = driverId.toString();
  if (!_driverState.has(id)) {
    _driverState.set(id, {
      isOnline:     false,
      lat:          null,
      lng:          null,
      lastSeen:     null,
      pendingOrder: null,
    });
  }
  return _driverState.get(id);
}

// ─── POST /driver/status — go online / offline ────────────────────────────────

router.post(
  '/status',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const driverId = req.user.id;
      const { is_online, lat, lng } = req.body;

      if (typeof is_online !== 'boolean') {
        return res.status(422).json({ error: 'is_online (boolean) is required.' });
      }

      const state = getState(driverId);
      state.isOnline = is_online;
      state.lastSeen = new Date();
      if (lat !== undefined) state.lat = lat;
      if (lng !== undefined) state.lng = lng;

      // If going offline, drop any pending order offer so it can be
      // reassigned by the dispatcher.
      if (!is_online && state.pendingOrder) {
        state.pendingOrder = null;
      }

      res.json({
        is_online: state.isOnline,
        lat:       state.lat,
        lng:       state.lng,
        last_seen: state.lastSeen,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── GET /driver/status ───────────────────────────────────────────────────────

router.get(
  '/status',
  authenticate,
  requireRole(['driver', 'admin']),
  (req, res) => {
    const state = getState(req.user.id);
    res.json({
      is_online: state.isOnline,
      lat:       state.lat,
      lng:       state.lng,
      last_seen: state.lastSeen,
    });
  }
);

// ─── POST /driver/location — broadcast GPS position ───────────────────────────

router.post(
  '/location',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const { lat, lng, accuracy, heading } = req.body;

      if (!lat || !lng) {
        return res.status(422).json({ error: 'lat and lng are required.' });
      }

      const state = getState(req.user.id);
      state.lat      = lat;
      state.lng      = lng;
      state.lastSeen = new Date();

      // If driver is on an active order, update the order document so
      // customer tracking streams get the new position.
      if (state.activeOrderId) {
        await Order.findByIdAndUpdate(state.activeOrderId, {
          $set: {
            'assignedDriver.lat':       lat,
            'assignedDriver.lng':       lng,
            'assignedDriver.updatedAt': new Date(),
          },
        });
      }

      res.json({ ok: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── GET /driver/order/incoming — poll for a dispatch offer ──────────────────

router.get(
  '/order/incoming',
  authenticate,
  requireRole(['driver', 'admin']),
  (req, res) => {
    const state = getState(req.user.id);

    if (!state.isOnline || !state.pendingOrder) {
      return res.json({ order: null });
    }

    // Check if the offer window has expired (30 s default).
    const now     = Date.now();
    const offered = state.pendingOrderOfferedAt?.getTime() ?? now;
    const window  = state.pendingOrderWindowSec * 1000 ?? 30_000;

    if (now - offered > window) {
      state.pendingOrder        = null;
      state.pendingOrderOfferedAt = null;
      return res.json({ order: null });
    }

    res.json({
      order:               state.pendingOrder,
      distance_km:         state.pendingOrderDistanceKm ?? 1,
      estimated_earnings:  state.pendingOrderEarnings   ?? 5,
      window_seconds:      state.pendingOrderWindowSec  ?? 30,
    });
  }
);

// ─── POST /driver/order/:id/accept ────────────────────────────────────────────

router.post(
  '/order/:id/accept',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const driverId = req.user.id;
      const state    = getState(driverId);

      if (!state.pendingOrder || state.pendingOrder.id !== req.params.id) {
        return res.status(409).json({ error: 'No matching pending order to accept.' });
      }

      // Claim the order in the database.
      const order = await Order.findByIdAndUpdate(
        req.params.id,
        {
          $set: {
            'assignedDriver.id':  driverId,
            'assignedDriver.lat': state.lat,
            'assignedDriver.lng': state.lng,
            status:               'accepted',
            acceptedAt:           new Date(),
          },
          $push: {
            statusHistory: {
              status:    'accepted',
              changedBy: driverId,
              timestamp: new Date(),
            },
          },
        },
        { new: true }
      );

      if (!order) {
        return res.status(404).json({ error: 'Order not found.' });
      }

      state.pendingOrder     = null;
      state.activeOrderId    = order._id.toString();

      res.json({ order: order.toJSON(), message: 'Order accepted.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── POST /driver/order/:id/reject ────────────────────────────────────────────

router.post(
  '/order/:id/reject',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const state = getState(req.user.id);
      state.pendingOrder = null;
      res.json({ message: 'Order rejected. You remain available.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── POST /driver/order/:id/complete — mark delivered ────────────────────────

router.post(
  '/order/:id/complete',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const driverId = req.user.id;
      const { proof_url, signature, lat, lng } = req.body;

      const update = {
        status:               'delivered',
        deliveredAt:          new Date(),
        proofOfDeliveryUrl:   proof_url   || null,
        customerSignature:    signature   || null,
        $push: {
          statusHistory: {
            status:    'delivered',
            changedBy: driverId,
            timestamp: new Date(),
          },
        },
      };

      if (lat && lng) {
        update['deliveryGps'] = { lat, lng };
      }

      const order = await Order.findByIdAndUpdate(req.params.id, update, { new: true });
      if (!order) return res.status(404).json({ error: 'Order not found.' });

      const state          = getState(driverId);
      state.activeOrderId  = null;

      res.json({ order: order.toJSON(), message: 'Delivery completed.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── GET /driver/earnings ─────────────────────────────────────────────────────

router.get(
  '/earnings',
  authenticate,
  requireRole(['driver', 'admin']),
  async (req, res) => {
    try {
      const driverId = req.user.id;
      const now      = new Date();

      const todayStart = new Date(now); todayStart.setHours(0, 0, 0, 0);
      const weekStart  = new Date(now); weekStart.setDate(now.getDate() - now.getDay());
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

      const [today, week, month, completedToday] = await Promise.all([
        sumDeliveryFees(driverId, todayStart),
        sumDeliveryFees(driverId, weekStart),
        sumDeliveryFees(driverId, monthStart),
        Order.countDocuments({
          'assignedDriver.id': driverId,
          status:              'delivered',
          deliveredAt:         { $gte: todayStart },
        }),
      ]);

      res.json({
        today,
        week,
        month,
        total:           month, // simple proxy — real totals need ledger table
        completed_today: completedToday,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

async function sumDeliveryFees(driverId, since) {
  const result = await Order.aggregate([
    {
      $match: {
        'assignedDriver.id': driverId.toString(),
        status:              'delivered',
        deliveredAt:         { $gte: since },
      },
    },
    { $group: { _id: null, total: { $sum: '$deliveryFee' } } },
  ]);
  return result[0]?.total ?? 0;
}

// ─── Internal: push an order offer to a driver ────────────────────────────────

/**
 * Called by the smart dispatcher (order_dispatcher.js) when an order is ready
 * to be matched.
 *
 * @param {string}  driverId
 * @param {object}  orderDoc     Raw Order Mongoose document (toJSON)
 * @param {number}  distanceKm
 * @param {number}  earnings     Estimated driver cut
 * @param {number}  windowSec    Accept window in seconds
 */
function dispatchOrderToDriver(driverId, orderDoc, { distanceKm, earnings, windowSec = 30 }) {
  const state = getState(driverId);

  if (!state.isOnline || state.pendingOrder || state.activeOrderId) {
    return false; // driver is busy or offline
  }

  state.pendingOrder             = orderDoc;
  state.pendingOrderOfferedAt    = new Date();
  state.pendingOrderDistanceKm   = distanceKm;
  state.pendingOrderEarnings     = earnings;
  state.pendingOrderWindowSec    = windowSec;

  // Push via WebSocket so the driver app doesn't wait for the poll cycle.
  notifyDriver(driverId, {
    type:               'new_order',
    order:              orderDoc,
    distance_km:        distanceKm,
    estimated_earnings: earnings,
    window_seconds:     windowSec,
    offered_at:         state.pendingOrderOfferedAt.toISOString(),
  });

  return true;
}

/**
 * Returns a list of all driver IDs that are currently online and idle.
 */
function getAvailableDriverIds() {
  const available = [];
  for (const [id, state] of _driverState.entries()) {
    if (state.isOnline && !state.pendingOrder && !state.activeOrderId) {
      available.push(id);
    }
  }
  return available;
}

/**
 * Returns the current position of a driver (for live tracking by customers).
 */
function getDriverPosition(driverId) {
  const state = _driverState.get(driverId.toString());
  if (!state) return null;
  return { lat: state.lat, lng: state.lng, lastSeen: state.lastSeen };
}

module.exports = router;
module.exports.setWsRegistry       = setWsRegistry;
module.exports.dispatchOrderToDriver = dispatchOrderToDriver;
module.exports.getAvailableDriverIds = getAvailableDriverIds;
module.exports.getDriverPosition     = getDriverPosition;
module.exports.notifyDriver          = notifyDriver;
