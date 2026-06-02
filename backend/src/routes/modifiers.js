/**
 * /api/vendors/:vendorId/products/:productId/modifiers
 *
 * Full CRUD for modifier groups and their options.
 * All routes require a valid JWT that belongs to the owning vendor or an admin.
 */

const express  = require('express');
const router   = express.Router({ mergeParams: true }); // inherits vendorId, productId
const mongoose = require('mongoose');
const { body, param, validationResult } = require('express-validator');
const { authenticate, requireRole } = require('../middleware/auth');
const Product  = require('../models/Product');

// ─── Helpers ──────────────────────────────────────────────────────────────────

function validationGuard(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }
  next();
}

/** Resolves and owns-checks the product. Attaches it to req.product. */
async function resolveProduct(req, res, next) {
  const { vendorId, productId } = req.params;

  if (!mongoose.Types.ObjectId.isValid(productId)) {
    return res.status(400).json({ error: 'Invalid product ID.' });
  }

  const product = await Product.findOne({ _id: productId, vendor: vendorId });
  if (!product) {
    return res.status(404).json({ error: 'Product not found for this vendor.' });
  }

  // Vendor owners may only edit their own products; admins bypass.
  if (req.user.role !== 'admin' && req.user.vendorId?.toString() !== vendorId) {
    return res.status(403).json({ error: 'Forbidden.' });
  }

  req.product = product;
  next();
}

// ─── GET all modifier groups ───────────────────────────────────────────────────

router.get(
  '/',
  authenticate,
  resolveProduct,
  async (req, res) => {
    try {
      const groups = req.product.modifierGroups.map(g => ({
        id:             g._id.toString(),
        name:           g.name,
        selection_type: g.selectionType,
        is_required:    g.isRequired,
        min_selections: g.minSelections,
        max_selections: g.maxSelections,
        sort_order:     g.sortOrder,
        options:        g.options.map(o => ({
          id:             o._id.toString(),
          name:           o.name,
          price_delta:    o.priceDelta,
          is_default:     o.isDefault,
          is_available:   o.isAvailable,
          calories_delta: o.caloriesDelta,
        })),
      }));

      res.json({ modifier_groups: groups });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── POST — create a modifier group ───────────────────────────────────────────

router.post(
  '/',
  authenticate,
  requireRole(['vendor', 'admin']),
  [
    body('name').trim().notEmpty().withMessage('Group name is required.'),
    body('selection_type')
      .optional()
      .isIn(['single', 'multi'])
      .withMessage('selection_type must be "single" or "multi".'),
    body('is_required').optional().isBoolean(),
    body('min_selections').optional().isInt({ min: 0 }),
    body('max_selections').optional().isInt({ min: 1 }),
    body('options').optional().isArray(),
    body('options.*.name').notEmpty().withMessage('Each option must have a name.'),
    body('options.*.price_delta').optional().isNumeric(),
  ],
  validationGuard,
  resolveProduct,
  async (req, res) => {
    try {
      const {
        name,
        selection_type = 'single',
        is_required    = false,
        min_selections = 0,
        max_selections = 1,
        sort_order     = req.product.modifierGroups.length,
        options        = [],
      } = req.body;

      const group = {
        name,
        selectionType:  selection_type,
        isRequired:     is_required,
        minSelections:  min_selections,
        maxSelections:  max_selections,
        sortOrder:      sort_order,
        options: options.map(o => ({
          name:          o.name,
          priceDelta:    o.price_delta   ?? 0,
          isDefault:     o.is_default    ?? false,
          isAvailable:   o.is_available  ?? true,
          caloriesDelta: o.calories_delta ?? null,
        })),
      };

      req.product.modifierGroups.push(group);
      await req.product.save();

      const saved = req.product.modifierGroups[req.product.modifierGroups.length - 1];
      res.status(201).json({ modifier_group: _serializeGroup(saved) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── PUT — replace a modifier group entirely ──────────────────────────────────

router.put(
  '/:groupId',
  authenticate,
  requireRole(['vendor', 'admin']),
  [
    param('groupId').isMongoId().withMessage('Invalid group ID.'),
    body('name').trim().notEmpty().withMessage('Group name is required.'),
    body('options').isArray().withMessage('options must be an array.'),
  ],
  validationGuard,
  resolveProduct,
  async (req, res) => {
    try {
      const group = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      const {
        name,
        selection_type = group.selectionType,
        is_required    = group.isRequired,
        min_selections = group.minSelections,
        max_selections = group.maxSelections,
        sort_order     = group.sortOrder,
        options        = [],
      } = req.body;

      group.set({
        name,
        selectionType:  selection_type,
        isRequired:     is_required,
        minSelections:  min_selections,
        maxSelections:  max_selections,
        sortOrder:      sort_order,
        options: options.map(o => ({
          name:          o.name,
          priceDelta:    o.price_delta   ?? 0,
          isDefault:     o.is_default    ?? false,
          isAvailable:   o.is_available  ?? true,
          caloriesDelta: o.calories_delta ?? null,
        })),
      });

      await req.product.save();
      res.json({ modifier_group: _serializeGroup(group) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── PATCH — partial-update a modifier group ──────────────────────────────────

router.patch(
  '/:groupId',
  authenticate,
  requireRole(['vendor', 'admin']),
  resolveProduct,
  async (req, res) => {
    try {
      const group = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      const allowed = ['name', 'isRequired', 'minSelections', 'maxSelections',
                       'selectionType', 'sortOrder'];
      const fieldMap = {
        name:            'name',
        selection_type:  'selectionType',
        is_required:     'isRequired',
        min_selections:  'minSelections',
        max_selections:  'maxSelections',
        sort_order:      'sortOrder',
      };

      for (const [clientKey, modelKey] of Object.entries(fieldMap)) {
        if (req.body[clientKey] !== undefined) {
          group[modelKey] = req.body[clientKey];
        }
      }

      await req.product.save();
      res.json({ modifier_group: _serializeGroup(group) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── DELETE — remove a modifier group ─────────────────────────────────────────

router.delete(
  '/:groupId',
  authenticate,
  requireRole(['vendor', 'admin']),
  resolveProduct,
  async (req, res) => {
    try {
      const group = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      group.deleteOne();
      await req.product.save();
      res.json({ message: 'Modifier group deleted.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Option-level PATCH (toggle availability / update price delta) ─────────────

router.patch(
  '/:groupId/options/:optionId',
  authenticate,
  requireRole(['vendor', 'admin']),
  resolveProduct,
  async (req, res) => {
    try {
      const group  = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      const option = group.options.id(req.params.optionId);
      if (!option) return res.status(404).json({ error: 'Option not found.' });

      const fieldMap = {
        name:           'name',
        price_delta:    'priceDelta',
        is_default:     'isDefault',
        is_available:   'isAvailable',
        calories_delta: 'caloriesDelta',
      };

      for (const [clientKey, modelKey] of Object.entries(fieldMap)) {
        if (req.body[clientKey] !== undefined) {
          option[modelKey] = req.body[clientKey];
        }
      }

      await req.product.save();
      res.json({ option: _serializeOption(option) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── POST new option to an existing group ────────────────────────────────────

router.post(
  '/:groupId/options',
  authenticate,
  requireRole(['vendor', 'admin']),
  [
    body('name').trim().notEmpty(),
    body('price_delta').optional().isNumeric(),
  ],
  validationGuard,
  resolveProduct,
  async (req, res) => {
    try {
      const group = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      const { name, price_delta = 0, is_default = false,
              is_available = true, calories_delta = null } = req.body;

      group.options.push({
        name,
        priceDelta:    price_delta,
        isDefault:     is_default,
        isAvailable:   is_available,
        caloriesDelta: calories_delta,
      });

      await req.product.save();
      const saved = group.options[group.options.length - 1];
      res.status(201).json({ option: _serializeOption(saved) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── DELETE option ─────────────────────────────────────────────────────────────

router.delete(
  '/:groupId/options/:optionId',
  authenticate,
  requireRole(['vendor', 'admin']),
  resolveProduct,
  async (req, res) => {
    try {
      const group  = req.product.modifierGroups.id(req.params.groupId);
      if (!group) return res.status(404).json({ error: 'Modifier group not found.' });

      const option = group.options.id(req.params.optionId);
      if (!option) return res.status(404).json({ error: 'Option not found.' });

      option.deleteOne();
      await req.product.save();
      res.json({ message: 'Option deleted.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Upsell links ─────────────────────────────────────────────────────────────

router.put(
  '/upsell',
  authenticate,
  requireRole(['vendor', 'admin']),
  [
    body('links').isArray().withMessage('links must be an array.'),
    body('links.*.target_product_id')
      .isMongoId()
      .withMessage('Each link needs a valid target_product_id.'),
  ],
  validationGuard,
  resolveProduct,
  async (req, res) => {
    try {
      const { links } = req.body;

      // Resolve target products to denormalize name/price/image.
      const targetIds = links.map(l => l.target_product_id);
      const targets   = await Product.find({ _id: { $in: targetIds } })
                                     .select('name price images');

      const targetMap = Object.fromEntries(
        targets.map(t => [t._id.toString(), t])
      );

      req.product.upsellLinks = links
        .filter(l => targetMap[l.target_product_id])
        .map(l => {
          const t = targetMap[l.target_product_id];
          return {
            targetProduct:      t._id,
            targetProductName:  t.name,
            targetProductPrice: t.price,
            targetProductImage: t.images?.[0] ?? null,
            prompt:             l.prompt ?? null,
          };
        });

      await req.product.save();
      res.json({ message: 'Upsell links updated.', count: req.product.upsellLinks.length });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Serializers ──────────────────────────────────────────────────────────────

function _serializeGroup(g) {
  return {
    id:             g._id.toString(),
    name:           g.name,
    selection_type: g.selectionType,
    is_required:    g.isRequired,
    min_selections: g.minSelections,
    max_selections: g.maxSelections,
    sort_order:     g.sortOrder,
    options:        (g.options || []).map(_serializeOption),
  };
}

function _serializeOption(o) {
  return {
    id:             o._id.toString(),
    name:           o.name,
    price_delta:    o.priceDelta,
    is_default:     o.isDefault,
    is_available:   o.isAvailable,
    calories_delta: o.caloriesDelta,
  };
}

module.exports = router;
