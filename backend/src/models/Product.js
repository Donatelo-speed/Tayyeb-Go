const mongoose = require('mongoose');

// ─── Modifier option subdocument ─────────────────────────────────────────────
// A single selectable option within a group (e.g. "Spicy Mayo" = +$0.50).
const modifierOptionSchema = new mongoose.Schema(
  {
    name:         { type: String, required: true, trim: true },
    priceDelta:   { type: Number, default: 0 },   // negative = removal discount
    isDefault:    { type: Boolean, default: false },
    isAvailable:  { type: Boolean, default: true },
    caloriesDelta:{ type: Number, default: null },
  },
  { _id: true }
);

// ─── Modifier group subdocument ───────────────────────────────────────────────
// e.g. "Protein" (single required), "Extras" (multi, max 3), "Remove" (multi).
const modifierGroupSchema = new mongoose.Schema(
  {
    name:          { type: String, required: true, trim: true },
    selectionType: { type: String, enum: ['single', 'multi'], default: 'single' },
    isRequired:    { type: Boolean, default: false },
    minSelections: { type: Number, default: 0 },
    maxSelections: { type: Number, default: 1 },
    options:       [modifierOptionSchema],
    sortOrder:     { type: Number, default: 0 },
  },
  { _id: true }
);

// ─── Upsell link ──────────────────────────────────────────────────────────────
const upsellLinkSchema = new mongoose.Schema(
  {
    targetProduct:      { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    targetProductName:  { type: String },           // denormalized for read speed
    targetProductPrice: { type: Number },
    targetProductImage: { type: String },
    prompt:             { type: String, default: null }, // "Add a drink?"
  },
  { _id: false }
);

// ─── Product ──────────────────────────────────────────────────────────────────
const productSchema = new mongoose.Schema(
  {
    vendor:         { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true, index: true },
    name:           { type: String, required: true, trim: true },
    description:    { type: String, default: '' },
    category:       { type: String, required: true, index: true },
    subCategory:    { type: String, default: null },
    brand:          { type: String, default: null },
    price:          { type: Number, required: true, min: 0 },
    images:         [{ type: String }],
    isAvailable:    { type: Boolean, default: true, index: true },
    isVegetarian:   { type: Boolean, default: false },
    isVegan:        { type: Boolean, default: false },
    isSpicy:        { type: Boolean, default: false },
    preparationTime:{ type: Number, default: 15 },  // minutes
    stock:          { type: Number, default: 100 },

    // ── Modifier system ─────────────────────────────────────────────────────
    modifierGroups: [modifierGroupSchema],

    // ── Upsell engine ────────────────────────────────────────────────────────
    upsellLinks:    [upsellLinkSchema],

    // ── Analytics ────────────────────────────────────────────────────────────
    totalSold:      { type: Number, default: 0 },
    rating:         { type: Number, default: 0 },
    reviewCount:    { type: Number, default: 0 },
    isFeatured:     { type: Boolean, default: false },
  },
  {
    timestamps: true,    // createdAt, updatedAt
    toJSON:  { virtuals: true },
    toObject:{ virtuals: true },
  }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────
productSchema.index({ name: 'text', description: 'text' });
productSchema.index({ vendor: 1, category: 1 });
productSchema.index({ isFeatured: 1, isAvailable: 1 });

// ─── Virtuals ─────────────────────────────────────────────────────────────────
productSchema.virtual('mainImageUrl').get(function () {
  return this.images?.[0] ?? null;
});

productSchema.virtual('inStock').get(function () {
  return this.stock > 0;
});

// ─── Methods ──────────────────────────────────────────────────────────────────

/**
 * Returns a safe client-facing JSON representation:
 * - Maps internal `_id` to `id`
 * - Maps `images` to `image_urls` for Flutter compat
 * - Snake-cases all nested fields
 */
productSchema.methods.toClientJSON = function () {
  const obj = this.toObject({ virtuals: true });
  return {
    id:               obj._id.toString(),
    name:             obj.name,
    description:      obj.description,
    category:         obj.category,
    sub_category:     obj.subCategory,
    brand:            obj.brand,
    price:            obj.price,
    image_urls:       obj.images,
    is_available:     obj.isAvailable,
    is_vegetarian:    obj.isVegetarian,
    is_vegan:         obj.isVegan,
    is_spicy:         obj.isSpicy,
    preparation_time: obj.preparationTime,
    stock_quantity:   obj.stock,
    rating:           obj.rating,
    review_count:     obj.reviewCount,
    is_featured:      obj.isFeatured,
    total_sold:       obj.totalSold,
    created_at:       obj.createdAt,
    modifier_groups:  (obj.modifierGroups || []).map(g => ({
      id:              g._id.toString(),
      name:            g.name,
      selection_type:  g.selectionType,
      is_required:     g.isRequired,
      min_selections:  g.minSelections,
      max_selections:  g.maxSelections,
      options:         (g.options || []).map(o => ({
        id:             o._id.toString(),
        name:           o.name,
        price_delta:    o.priceDelta,
        is_default:     o.isDefault,
        is_available:   o.isAvailable,
        calories_delta: o.caloriesDelta,
      })),
    })),
    upsell_links: (obj.upsellLinks || []).map(u => ({
      source_product_id:      obj._id.toString(),
      target_product_id:      u.targetProduct?.toString(),
      target_product_name:    u.targetProductName,
      target_product_price:   u.targetProductPrice,
      target_product_image_url: u.targetProductImage,
      prompt:                 u.prompt,
    })),
  };
};

module.exports = mongoose.model('Product', productSchema);
