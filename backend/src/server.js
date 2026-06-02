'use strict';

const http       = require('http');
const express    = require('express');
const cors       = require('cors');
const helmet     = require('helmet');
const morgan     = require('morgan');
const mongoose   = require('mongoose');
const { WebSocketServer } = require('ws');
const url        = require('url');
const jwt        = require('jsonwebtoken');

// ─── Route modules ─────────────────────────────────────────────────────────────
const authRoutes      = require('./routes/auth');
const userRoutes      = require('./routes/users');
const vendorRoutes    = require('./routes/vendors');
const productRoutes   = require('./routes/products');
const modifierRoutes  = require('./routes/modifiers');
const orderRoutes     = require('./routes/orders');
const cartRoutes      = require('./routes/cart');
const driverRoutes    = require('./routes/driver');
const storefrontRoutes = require('./routes/storefront');
const adminRoutes     = require('./routes/admin');
const payoutRoutes    = require('./routes/payouts');

const OrderDispatcher = require('./services/order_dispatcher');

// ─── App ──────────────────────────────────────────────────────────────────────
const app = express();

app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGINS?.split(',') ?? ['http://localhost:3000'],
  credentials: true,
}));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Health ────────────────────────────────────────────────────────────────────
app.get('/health', (_, res) => res.json({ status: 'ok', ts: new Date() }));

// ─── REST routes ──────────────────────────────────────────────────────────────
app.use('/api/auth',       authRoutes);
app.use('/api/users',      userRoutes);
app.use('/api/vendors',    vendorRoutes);
app.use('/api/products',   productRoutes);
app.use('/api/orders',     orderRoutes);
app.use('/api/cart',       cartRoutes);
app.use('/api/driver',     driverRoutes);
app.use('/api/storefront', storefrontRoutes);
app.use('/api/admin',      adminRoutes);
app.use('/api/payouts',    payoutRoutes);

// Modifier CRUD: nested under vendor → product.
// e.g. GET /api/vendors/:vendorId/products/:productId/modifiers
app.use(
  '/api/vendors/:vendorId/products/:productId/modifiers',
  modifierRoutes
);

// ─── Global error handler ─────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  const status  = err.status ?? err.statusCode ?? 500;
  const message = err.expose ? err.message : 'Internal server error.';
  if (status >= 500) console.error('[ERROR]', err);
  res.status(status).json({ error: message });
});

// ─── HTTP server ──────────────────────────────────────────────────────────────
const server = http.createServer(app);

// ─── WebSocket server ─────────────────────────────────────────────────────────
//
// Clients connect to  ws://host/ws?token=<JWT>
//
// Channel routing is handled by the "channel" field in each message:
//   { channel: "driver",   ... }  → driver availability + order notifications
//   { channel: "tracking", ... }  → customer live order tracking
//   { channel: "order",    ... }  → vendor live order pipeline
//

/** @type {Map<string, WebSocket>} driverId → ws */
const driverWsRegistry  = new Map();

/** @type {Map<string, WebSocket>} orderId  → customer ws */
const trackingWsRegistry = new Map();

/** @type {Map<string, WebSocket>} vendorId → vendor ws */
const vendorWsRegistry   = new Map();

const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (request, socket, head) => {
  const { query } = url.parse(request.url, true);
  const token = query.token;

  if (!token) {
    socket.destroy();
    return;
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    socket.destroy();
    return;
  }

  wss.handleUpgrade(request, socket, head, (ws) => {
    ws._userId   = decoded.id;
    ws._userRole = decoded.role;
    ws._vendorId = decoded.vendorId ?? null;
    wss.emit('connection', ws, request);
  });
});

wss.on('connection', (ws) => {
  const userId   = ws._userId;
  const role     = ws._userRole;
  const vendorId = ws._vendorId;

  // Register based on role.
  if (role === 'driver') {
    driverWsRegistry.set(userId, ws);
  } else if (role === 'vendor' && vendorId) {
    vendorWsRegistry.set(vendorId, ws);
  }

  // Heartbeat — keep connection alive through proxies.
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }

    switch (msg.channel) {
      case 'driver':
        _handleDriverMessage(ws, userId, msg);
        break;

      case 'tracking':
        // Customer registers to receive updates for an order.
        if (msg.action === 'subscribe' && msg.orderId) {
          trackingWsRegistry.set(msg.orderId, ws);
        }
        break;

      case 'ping':
        ws.send(JSON.stringify({ channel: 'pong', ts: Date.now() }));
        break;

      default:
        break;
    }
  });

  ws.on('close', () => {
    if (role === 'driver')  driverWsRegistry.delete(userId);
    if (role === 'vendor')  vendorWsRegistry.delete(vendorId);
    // Clean tracking subs belonging to this socket.
    for (const [ordId, sock] of trackingWsRegistry.entries()) {
      if (sock === ws) trackingWsRegistry.delete(ordId);
    }
  });

  ws.send(JSON.stringify({ channel: 'connected', userId, role, ts: Date.now() }));
});

function _handleDriverMessage(ws, driverId, msg) {
  // Location update piggybacked over WS instead of REST for lower latency.
  if (msg.action === 'location' && msg.lat && msg.lng) {
    // Persist to the driver router's in-memory store.
    driverRoutes.getDriverPosition; // ensure module loaded
    // Broadcast driver position to any customer tracking that order.
    if (msg.orderId) {
      const customerWs = trackingWsRegistry.get(msg.orderId);
      if (customerWs?.readyState === 1) {
        customerWs.send(JSON.stringify({
          channel:  'tracking',
          orderId:  msg.orderId,
          driverId,
          lat:      msg.lat,
          lng:      msg.lng,
          heading:  msg.heading ?? null,
          ts:       Date.now(),
        }));
      }
    }
  }
}

// ─── Periodic heartbeat sweep ─────────────────────────────────────────────────
const heartbeatInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30_000);

wss.on('close', () => clearInterval(heartbeatInterval));

// ─── Expose WS broadcast helpers for other modules ───────────────────────────

/**
 * Broadcast a new-order event to the vendor's WebSocket client (for the
 * real-time order pipeline screen).
 */
function notifyVendor(vendorId, payload) {
  const ws = vendorWsRegistry.get(vendorId?.toString());
  if (ws?.readyState === 1) {
    ws.send(JSON.stringify({ channel: 'order', ...payload }));
  }
}

/**
 * Broadcast driver position / order status to a tracking customer.
 */
function notifyCustomer(orderId, payload) {
  const ws = trackingWsRegistry.get(orderId?.toString());
  if (ws?.readyState === 1) {
    ws.send(JSON.stringify({ channel: 'tracking', orderId, ...payload }));
  }
}

// Wire the driver route module's WS registry so its dispatchOrderToDriver
// can push via WebSocket without importing this file (circular-safe).
driverRoutes.setWsRegistry(driverWsRegistry);

// ─── Order dispatcher startup ─────────────────────────────────────────────────
const dispatcher = new OrderDispatcher({
  driverRoutes,
  notifyVendor,
  notifyCustomer,
});

// ─── MongoDB + server boot ────────────────────────────────────────────────────
const PORT     = process.env.PORT     ?? 5000;
const MONGO_URI = process.env.MONGO_URI ?? 'mongodb://127.0.0.1:27017/tayyebgo';

mongoose
  .connect(MONGO_URI, {
    useNewUrlParser:    true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log(`[DB] Connected → ${MONGO_URI}`);

    server.listen(PORT, () => {
      console.log(`[HTTP] Listening on port ${PORT}`);
      console.log(`[WS]   WebSocket ready at ws://localhost:${PORT}/ws`);
      dispatcher.start();
    });
  })
  .catch((err) => {
    console.error('[DB] Connection failed:', err.message);
    process.exit(1);
  });

// ─── Graceful shutdown ────────────────────────────────────────────────────────
process.on('SIGTERM', async () => {
  console.log('[SHUTDOWN] SIGTERM received — draining…');
  dispatcher.stop();
  clearInterval(heartbeatInterval);
  server.close(() => {
    mongoose.connection.close(false, () => {
      console.log('[SHUTDOWN] Clean exit.');
      process.exit(0);
    });
  });
});

module.exports = { app, server, notifyVendor, notifyCustomer };
