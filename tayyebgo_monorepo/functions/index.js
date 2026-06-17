const { onNotificationCreated, registerFcmToken, cleanupNotifications } = require('./notifications');
const { onDispatchCreated, onDispatchAccepted, checkDispatchTimeouts } = require('./dispatch');
const { setUserRole, getUserRole } = require('./admin');
const { processAiMenuImage } = require('./ai');
const {
  createStripePaymentIntent,
  createWalletTopUpIntent,
  confirmWalletTopUp,
  transferWalletFunds,
  processDriverPayout,
} = require('./stripe');
const { processPayouts } = require('./payouts');
const { onSOSEmergency, validateOrderPricing } = require('./safety');
const { validatePromo } = require('./promos');
const {
  logAuditEvent,
  onUserSensitiveUpdate,
  onOrderStatusChange,
  getAuditLog,
} = require('./audit');

module.exports = {
  onNotificationCreated,
  registerFcmToken,
  cleanupNotifications,
  onDispatchCreated,
  onDispatchAccepted,
  checkDispatchTimeouts,
  setUserRole,
  getUserRole,
  processAiMenuImage,
  createStripePaymentIntent,
  createWalletTopUpIntent,
  confirmWalletTopUp,
  transferWalletFunds,
  processDriverPayout,
  processPayouts,
  onSOSEmergency,
  validateOrderPricing,
  validatePromo,
  logAuditEvent,
  onUserSensitiveUpdate,
  onOrderStatusChange,
  getAuditLog,
};
