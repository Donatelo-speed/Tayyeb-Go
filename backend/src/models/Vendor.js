'use strict';

/**
 * Vendor model — adds storefrontTheme embedded document so each restaurant
 * can store their full visual identity alongside their core profile.
 * Drop this file over the existing Vendor.js.
 */

const mongoose = require('mongoose');

// ─── Storefront theme subdocument ─────────────────────────────────────────────
const storefrontThemeSchema = new mongoose.Schema(
  {
    primaryColor:         { type: String, default: '#16A085' },
    accentColor:          { type: String, default: '#00B894' },
    surfaceColor:         { type: String, default: '#FFFFFF' },
    onPrimaryColor:       { type: String, default: '#FFFFFF' },
    taglineColor:         { type: String, default: null },
    fontFamily:           { type: String, default: 'Poppins' },
    heroBannerUrl:        { type: String, default: null },
    bannerLayout:         {
      type: String,
      enum: ['fullWidth', 'splitLeft', 'splitRight'],
      default: 'fullWidth',
    },
    tagline:              { type: String, default: null },
    cardStyle:            {
      type: String,
      enum: ['rounded', 'flat', 'elevated'],
      default: 'rounded',
    },
    cardBorderRadius:     { type: Number, default: 16, min: 0, max: 40 },
    menuLayout:           {
      type: String,
      enum: ['grid', 'list', 'compact'],
      default: 'grid',
    },
    showCategoryBar:      { type: Boolean, default: true },
    promoBannerUrl:       { type: String, default: null },
    promoText:            { type: String, default: null },
    showReviewHighlights: { type: Boolean, default: true },
  },
  { _id: false }
);

// ─── Opening hours subdocument ────────────────────────────────────────────────
const openingHoursSchema = new mongoose.Schema(
  {
    day:   { type: Number, min: 0, max: 6 }, // 0 = Sunday
    open:  { type: String },                 // "09:00"
    close: { type: String },                 // "23:00"
    isClosed: { type: Boolean, default: false },
  },
  { _id: false }
);

// ─── Bank / payout details ────────────────────────────────────────────────────
const payoutDetailsSchema = new mongoose.Schema(
  {
    bankName:      { type: String },
    accountHolder: { type: String },
    iban:          { type: String },
    swiftCode:     { type: String },
  },
  { _id: false }
);

// ─── Vendor ───────────────────────────────────────────────────────────────────
const vendorSchema = new mongoose.Schema(
  {
    // ── Identity ───────────────────────────────────────────────────────────
    name:           { type: String, required: true, trim: true },
    description:    { type: String, default: '' },
    email:          { type: String, required: true, unique: true, lowercase: true },
    phone:          { type: String },
    category:       { type: String, required: true },   // e.g. "Burgers"
    tags:           [{ type: String }],                 // ["Fast Food", "Halal"]
    logo:           { type: String, default: null },
    coverImage:     { type: String, default: null },

    // ── Location ───────────────────────────────────────────────────────────
    address:        { type: String },
    city:           { type: String },
    country:        { type: String, default: 'SA' },
    gps: {
      lat: { type: Number },
      lng: { type: Number },
    },

    // ── Operational ────────────────────────────────────────────────────────
    isActive:       { type: Boolean, default: false, index: true },
    isApproved:     { type: Boolean, default: false, index: true },
    isFeatured:     { type: Boolean, default: false },
    isSuspended:    { type: Boolean, default: false },
    suspensionNote: { type: String, default: null },

    minOrderValue:  { type: Number, default: 0 },
    deliveryFee:    { type: Number, default: 5 },
    deliveryRadius: { type: Number, default: 10 }, // km
    estimatedDeliveryMin: { type: Number, default: 30 },
    estimatedDeliveryMax: { type: Number, default: 45 },

    openingHours:   [openingHoursSchema],

    // ── Commission (set by super-admin) ────────────────────────────────────
    commissionType:  { type: String, enum: ['percentage', 'flat'], default: 'percentage' },
    commissionRate:  { type: Number, default: 15 }, // % or flat $ per order

    // ── Auth ───────────────────────────────────────────────────────────────
    ownerId:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    // ── Payout ─────────────────────────────────────────────────────────────
    payoutDetails:  payoutDetailsSchema,

    // ── Storefront design (the new field) ──────────────────────────────────
    storefrontTheme: { type: storefrontThemeSchema, default: () => ({}) },

    // ── Analytics ──────────────────────────────────────────────────────────
    rating:         { type: Number, default: 0 },
    reviewCount:    { type: Number, default: 0 },
    totalOrders:    { type: Number, default: 0 },
    totalRevenue:   { type: Number, default: 0 },
  },
  {
    timestamps: true,
    toJSON:  { virtuals: true },
    toObject:{ virtuals: true },
  }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────
vendorSchema.index({ name: 'text', description: 'text', tags: 'text' });
vendorSchema.index({ 'gps.lat': 1, 'gps.lng': 1 });
vendorSchema.index({ category: 1, isActive: 1, isApproved: 1 });

// ─── Virtuals ─────────────────────────────────────────────────────────────────
vendorSchema.virtual('deliveryTimeDisplay').get(function () {
  return `${this.estimatedDeliveryMin}–${this.estimatedDeliveryMax} min`;
});

vendorSchema.virtual('displayCover').get(function () {
  return this.coverImage ?? this.logo ?? '';
});

// ─── Methods ──────────────────────────────────────────────────────────────────

vendorSchema.methods.isOpenNow = function () {
  const now  = new Date();
  const day  = now.getDay();
  const time = now.toTimeString().slice(0, 5); // "HH:MM"
  const slot = (this.openingHours ?? []).find(h => h.day === day);
  if (!slot || slot.isClosed) return false;
  return time >= slot.open && time <= slot.close;
};

vendorSchema.methods.toListingJSON = function () {
  const obj = this.toObject({ virtuals: true });
  return {
    id:              obj._id.toString(),
    name:            obj.name,
    description:     obj.description,
    category:        obj.category,
    tags:            obj.tags,
    logo:            obj.logo,
    cover_image:     obj.coverImage,
    display_cover:   obj.displayCover,
    rating:          obj.rating,
    review_count:    obj.reviewCount,
    delivery_fee:    obj.deliveryFee,
    delivery_time:   obj.deliveryTimeDisplay,
    min_order_value: obj.minOrderValue,
    is_open:         this.isOpenNow(),
    is_featured:     obj.isFeatured,
    address:         obj.address,
    city:            obj.city,
    gps:             obj.gps,
    storefront_theme: obj.storefrontTheme ?? {},
  };
};

module.exports = mongoose.model('Vendor', vendorSchema);
