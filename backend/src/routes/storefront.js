'use strict';

/**
 * /api/storefront
 *
 * GET  /api/storefront/:vendorId          — public; read a vendor's theme
 * PUT  /api/storefront/:vendorId          — vendor / admin; save full theme
 * PATCH /api/storefront/:vendorId         — vendor / admin; partial update
 * DELETE /api/storefront/:vendorId/reset  — admin; restore to system defaults
 */

const express  = require('express');
const router   = express.Router();
const { body, validationResult } = require('express-validator');
const { authenticate, requireRole } = require('../middleware/auth');
const Vendor   = require('../models/Vendor');

// ─── Validation helper ────────────────────────────────────────────────────────

function guard(req, res, next) {
  const e = validationResult(req);
  if (!e.isEmpty()) return res.status(422).json({ errors: e.array() });
  next();
}

// Color hex validator (accepts '#RRGGBB' or 'RRGGBB').
function isHexColor(value) {
  if (!value) return true; // optional fields pass
  return /^#?([0-9A-Fa-f]{6})$/.test(value);
}

const colorFields = [
  'primary_color', 'accent_color', 'surface_color', 'on_primary_color', 'tagline_color'
];

const themeValidators = [
  ...colorFields.map(f =>
    body(f).optional().custom(isHexColor).withMessage(`${f} must be a 6-digit hex color.`)
  ),
  body('font_family').optional().trim().isString(),
  body('hero_banner_url').optional().trim().isURL(),
  body('banner_layout').optional().isIn(['fullWidth', 'splitLeft', 'splitRight']),
  body('tagline').optional().trim().isString().isLength({ max: 120 }),
  body('card_style').optional().isIn(['rounded', 'flat', 'elevated']),
  body('card_border_radius').optional().isFloat({ min: 0, max: 40 }),
  body('menu_layout').optional().isIn(['grid', 'list', 'compact']),
  body('show_category_bar').optional().isBoolean(),
  body('promo_banner_url').optional().trim().isURL(),
  body('promo_text').optional().trim().isString().isLength({ max: 200 }),
  body('show_review_highlights').optional().isBoolean(),
];

// ─── GET — public theme read ──────────────────────────────────────────────────

router.get('/:vendorId', async (req, res) => {
  try {
    const vendor = await Vendor.findById(req.params.vendorId)
      .select('storefrontTheme name')
      .lean();

    if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });

    const theme = vendor.storefrontTheme ?? {};
    return res.json({
      vendor_id:              req.params.vendorId,
      primary_color:          theme.primaryColor          ?? '#16A085',
      accent_color:           theme.accentColor           ?? '#00B894',
      surface_color:          theme.surfaceColor          ?? '#FFFFFF',
      on_primary_color:       theme.onPrimaryColor        ?? '#FFFFFF',
      font_family:            theme.fontFamily            ?? 'Poppins',
      hero_banner_url:        theme.heroBannerUrl         ?? null,
      banner_layout:          theme.bannerLayout          ?? 'fullWidth',
      tagline:                theme.tagline               ?? null,
      tagline_color:          theme.taglineColor          ?? null,
      card_style:             theme.cardStyle             ?? 'rounded',
      card_border_radius:     theme.cardBorderRadius      ?? 16,
      menu_layout:            theme.menuLayout            ?? 'grid',
      show_category_bar:      theme.showCategoryBar       ?? true,
      promo_banner_url:       theme.promoBannerUrl        ?? null,
      promo_text:             theme.promoText             ?? null,
      show_review_highlights: theme.showReviewHighlights  ?? true,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT — replace full theme ─────────────────────────────────────────────────

router.put(
  '/:vendorId',
  authenticate,
  requireRole(['vendor', 'admin']),
  themeValidators,
  guard,
  async (req, res) => {
    try {
      if (!_canEdit(req)) return res.status(403).json({ error: 'Forbidden.' });

      const update = _buildThemeUpdate(req.body);
      const vendor = await Vendor.findByIdAndUpdate(
        req.params.vendorId,
        { $set: { storefrontTheme: update } },
        { new: true, runValidators: true }
      ).select('storefrontTheme');

      if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });
      res.json({ message: 'Theme saved.', theme: vendor.storefrontTheme });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── PATCH — partial update ───────────────────────────────────────────────────

router.patch(
  '/:vendorId',
  authenticate,
  requireRole(['vendor', 'admin']),
  themeValidators,
  guard,
  async (req, res) => {
    try {
      if (!_canEdit(req)) return res.status(403).json({ error: 'Forbidden.' });

      const partial = _buildThemeUpdate(req.body);
      // Prefix each key for a dot-notation partial update.
      const $set = {};
      for (const [k, v] of Object.entries(partial)) {
        $set[`storefrontTheme.${k}`] = v;
      }

      const vendor = await Vendor.findByIdAndUpdate(
        req.params.vendorId,
        { $set },
        { new: true }
      ).select('storefrontTheme');

      if (!vendor) return res.status(404).json({ error: 'Vendor not found.' });
      res.json({ message: 'Theme partially updated.', theme: vendor.storefrontTheme });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── DELETE /reset — admin resets to defaults ─────────────────────────────────

router.delete(
  '/:vendorId/reset',
  authenticate,
  requireRole(['admin']),
  async (req, res) => {
    try {
      await Vendor.findByIdAndUpdate(
        req.params.vendorId,
        { $unset: { storefrontTheme: '' } }
      );
      res.json({ message: 'Storefront theme reset to defaults.' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

function _canEdit(req) {
  if (req.user.role === 'admin') return true;
  return req.user.vendorId?.toString() === req.params.vendorId;
}

function _buildThemeUpdate(body) {
  const map = {
    primary_color:          'primaryColor',
    accent_color:           'accentColor',
    surface_color:          'surfaceColor',
    on_primary_color:       'onPrimaryColor',
    tagline_color:          'taglineColor',
    font_family:            'fontFamily',
    hero_banner_url:        'heroBannerUrl',
    banner_layout:          'bannerLayout',
    tagline:                'tagline',
    card_style:             'cardStyle',
    card_border_radius:     'cardBorderRadius',
    menu_layout:            'menuLayout',
    show_category_bar:      'showCategoryBar',
    promo_banner_url:       'promoBannerUrl',
    promo_text:             'promoText',
    show_review_highlights: 'showReviewHighlights',
  };

  const out = {};
  for (const [clientKey, modelKey] of Object.entries(map)) {
    if (body[clientKey] !== undefined) {
      out[modelKey] = body[clientKey];
    }
  }
  return out;
}

module.exports = router;
