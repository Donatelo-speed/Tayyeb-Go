const express = require('express');
const router = express.Router();

const driverRoutes      = require('./driver');
const modifierRoutes    = require('./modifiers');
const storefrontRoutes  = require('./storefront');

router.use('/driver',      driverRoutes);
router.use('/modifiers',   modifierRoutes);
router.use('/storefront',  storefrontRoutes);

module.exports = router;