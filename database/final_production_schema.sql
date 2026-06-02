-- =====================================================
-- TAYYEB-GO: FINAL PRODUCTION SCHEMA
-- All Features Including Pro-Tier & Production Requirements
-- =====================================================

-- =====================================================
-- ENHANCED USER ROLES WITH DEVICE BINDING
-- =====================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS device_uuid VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP;

-- Rate limiting for auth
CREATE TABLE IF NOT EXISTS auth_rate_limits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ip_address VARCHAR(50) NOT NULL,
  endpoint VARCHAR(50) NOT NULL,
  attempts INTEGER DEFAULT 0,
  first_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '15 minutes')
);

-- =====================================================
-- DELIVERY PIN SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) NOT NULL,
  pin VARCHAR(4) NOT NULL,
  is_used BOOLEAN DEFAULT false,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  used_at TIMESTAMP,
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '2 hours')
);

-- =====================================================
-- PAYMENT NETWORKS (Sham Cash, PAYMERA, Visa Placeholder)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id),
  user_id UUID REFERENCES users(id),
  
  -- Sham Cash
  sham_account_number VARCHAR(50),
  sham_is_active BOOLEAN DEFAULT false,
  
  -- PAYMERA
  paymera_wallet_id VARCHAR(50),
  paymera_is_active BOOLEAN DEFAULT false,
  
  -- Visa (Coming Soon - placeholder)
  visa_merchant_id VARCHAR(100),
  visa_status VARCHAR(20) DEFAULT 'coming_soon',
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payment transactions
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id),
  
  payment_method VARCHAR(20) NOT NULL, -- cash, sham, paymera, visa
  
  -- Transaction details
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'SYP',
  status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed, refunded
  
  -- Provider references
  provider_reference VARCHAR(100),
  provider_response JSONB,
  
  -- Timestamps
  initiated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  failed_at TIMESTAMP
);

-- =====================================================
-- B2B COMMISSION & DEBT SYSTEM
-- =====================================================

ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5, 2) DEFAULT 15.00;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS commission_debt_ceiling DECIMAL(12, 2) DEFAULT 500000;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS current_commission_debt DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS suspension_reason TEXT;

-- Commission transactions
CREATE TABLE IF NOT EXISTS commission_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) NOT NULL,
  order_id UUID REFERENCES orders(id),
  
  order_amount DECIMAL(10, 2) NOT NULL,
  commission_percentage DECIMAL(5, 2) NOT NULL,
  commission_amount DECIMAL(10, 2) NOT NULL,
  
  status VARCHAR(20) DEFAULT 'pending', -- pending, settled, overdue
  due_date DATE,
  settled_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Settlement records
CREATE TABLE IF NOT EXISTS settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) NOT NULL,
  
  amount DECIMAL(12, 2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL, -- cash, bank_transfer, sham
  
  notes TEXT,
  settled_by UUID REFERENCES users(id),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- LANDMARK-ANCHORED ADDRESS SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS landmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  city_id VARCHAR(20) NOT NULL, -- e.g., 'HOMS'
  name_en VARCHAR(200) NOT NULL,
  name_ar VARCHAR(200) NOT NULL,
  
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  admin_level INTEGER DEFAULT 1, -- 1: major area, 2: neighborhood
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS landmark_id UUID REFERENCES landmarks(id);
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS micro_directions TEXT;
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS building_number VARCHAR(20);
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS floor VARCHAR(20);
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS apartment VARCHAR(20);

-- =====================================================
-- LOGISTICS ZONES & FUEL SURGE
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  city_id VARCHAR(20) NOT NULL,
  name_en VARCHAR(100) NOT NULL,
  name_ar VARCHAR(100) NOT NULL,
  
  base_delivery_fee DECIMAL(10, 2) NOT NULL,
  minimum_order DECIMAL(10, 2) DEFAULT 0,
  
  -- Surge multiplier (1.0 = normal, 1.5 = 50% surge)
  surge_multiplier DECIMAL(4, 2) DEFAULT 1.00,
  surge_reason TEXT, -- e.g., 'Fuel shortage'
  surge_active BOOLEAN DEFAULT false,
  surge_start_time TIMESTAMP,
  surge_end_time TIMESTAMP,
  
  polygon_coords JSONB, -- Zone boundary
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- CAMPAIGNS (Ramadan, Holidays, etc.)
-- =====================================================

CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  name_en VARCHAR(200) NOT NULL,
  name_ar VARCHAR(200) NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  
  campaign_type VARCHAR(30) NOT NULL, -- ramadan, holiday, flash_sale, custom
  
  -- Schedule
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  is_active BOOLEAN DEFAULT true,
  
  -- Theme changes (JSON for frontend to apply)
  theme_overrides JSONB, -- { primary_color, banner_image, etc }
  category_reorder JSONB, -- Reorder categories
  
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PROMOTIONS SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  code VARCHAR(50) UNIQUE NOT NULL,
  name_en VARCHAR(200) NOT NULL,
  name_ar VARCHAR(200) NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  
  type VARCHAR(20) NOT NULL, -- percentage, fixed, free_delivery, bundle
  
  -- Discount value
  discount_percentage DECIMAL(5, 2),
  discount_fixed DECIMAL(10, 2),
  free_delivery_min_order DECIMAL(10, 2),
  
  -- Constraints
  min_order_amount DECIMAL(10, 2),
  max_uses INTEGER,
  uses_count INTEGER DEFAULT 0,
  max_uses_per_user INTEGER DEFAULT 1,
  
  -- Valid for specific restaurants or all
  restaurant_ids UUID[],
  city_ids VARCHAR[],
  
  valid_from TIMESTAMP NOT NULL,
  valid_until TIMESTAMP NOT NULL,
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- NOTIFICATION FALLBACK (SMS/WhatsApp)
-- =====================================================

CREATE TABLE IF NOT EXISTS notification_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID REFERENCES users(id),
  order_id UUID REFERENCES orders(id),
  
  type VARCHAR(30) NOT NULL, -- push, sms, whatsapp
  
  -- Status tracking
  status VARCHAR(20) DEFAULT 'pending', -- pending, sent, delivered, failed
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  failed_at TIMESTAMP,
  
  -- Message content
  message_en TEXT,
  message_ar TEXT,
  
  -- Fallback tracking
  was_push_fallback BOOLEAN DEFAULT false,
  fallback_triggered_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- GUEST MODE HIGH-VALUE FLAG
-- =====================================================

CREATE TABLE IF NOT EXISTS guest_order_limits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  city_id VARCHAR(20) NOT NULL,
  
  high_value_threshold DECIMAL(12, 2) DEFAULT 50000, -- Orders above this need verification
  require_phone_verification BOOLEAN DEFAULT true,
  
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- IMAGE OPTIMIZATION
-- =====================================================

CREATE TABLE IF NOT EXISTS image_optimizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  original_url TEXT NOT NULL,
  optimized_url TEXT,
  
  original_size INTEGER, -- bytes
  optimized_size INTEGER,
  
  format VARCHAR(10) DEFAULT 'webp',
  width INTEGER,
  height INTEGER,
  
  status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- ADMIN DEBT CEILING CHECK FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION check_restaurant_debt_ceiling()
RETURNS TRIGGER AS $$
DECLARE
  v_debt_ceiling DECIMAL;
  v_current_debt DECIMAL;
BEGIN
  -- Get restaurant debt ceiling
  SELECT commission_debt_ceiling, current_commission_debt
  INTO v_debt_ceiling, v_current_debt
  FROM restaurants
  WHERE id = NEW.restaurant_id;
  
  -- If debt exceeds ceiling, suspend restaurant
  IF v_current_debt > v_debt_ceiling THEN
    UPDATE restaurants
    SET is_suspended = true,
        suspension_reason = 'Commission debt exceeded ceiling'
    WHERE id = NEW.restaurant_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_commission_debt_check
AFTER INSERT ON commission_transactions
FOR EACH ROW
EXECUTE FUNCTION check_restaurant_debt_ceiling();

-- =====================================================
-- SEED DATA FOR HOMS (Phase 1)
-- =====================================================

-- Landmarks for Homs
INSERT INTO landmarks (city_id, name_en, name_ar, latitude, longitude, admin_level) VALUES
('HOMS', 'Al-Masjid Al-Kabir Area', 'منطقة المسجد الكبير', 34.7321, 36.7249, 1),
('HOMS', 'Al-Nasr Area', 'منطقة النصر', 34.7350, 36.7200, 1),
('HOMS', 'Al-Khatuniyyah', 'الخطوطية', 34.7400, 36.7150, 1),
('HOMS', 'Al-Wadi', 'الوادي', 34.7250, 36.7300, 1),
('HOMS', 'Al-Mansour', 'المنصور', 34.7380, 36.7100, 2),
('HOMS', 'Al-Mazza', 'المزة', 34.7420, 36.7180, 2),
('HOMS', 'Al-Karaj', 'الكراج', 34.7300, 36.7250, 2);

-- Delivery Zones for Homs
INSERT INTO delivery_zones (city_id, name_en, name_ar, base_delivery_fee, minimum_order, surge_multiplier) VALUES
('HOMS', 'Central Homs', 'وسط حمص', 1500, 5000, 1.00),
('HOMS', 'North Homs', 'شمال حمص', 2000, 8000, 1.00),
('HOMS', 'South Homs', 'جنوب حمص', 2500, 10000, 1.00),
('HOMS', 'East Homs', 'شرق حمص', 2000, 8000, 1.20),
('HOMS', 'West Homs', 'غرب حمص', 1800, 6000, 1.00);

-- Guest order limits for Homs
INSERT INTO guest_order_limits (city_id, high_value_threshold, require_phone_verification)
VALUES ('HOMS', 50000, true);

-- Campaign: Ramadan (template)
INSERT INTO campaigns (name_en, name_ar, campaign_type, start_date, end_date, is_active, theme_overrides)
VALUES 
('Ramadan Campaign 2026', 'رمضان 2026', 'ramadan', '2026-03-01', '2026-04-01', false,
 '{"primary_color": "#16A085", "banner_image": "ramadan_banner.png", "category_order": ["breakfast", "iftar", "dinner", "desserts"]}'),
('Summer Sale', 'البيع الصيفي', 'flash_sale', '2026-06-01', '2026-08-31', false, NULL);

SELECT '✅ Final Production Schema Complete!' as status;