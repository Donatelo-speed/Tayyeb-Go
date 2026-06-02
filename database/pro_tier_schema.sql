-- =====================================================
-- PRO-TIER UPGRADES: TAYYEB-GO ADVANCED FEATURES
-- =====================================================

-- =====================================================
-- LOYALTY POINTS / DIGITAL WALLET
-- =====================================================

CREATE TABLE IF NOT EXISTS loyalty_wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  coins_balance INTEGER DEFAULT 0,
  total_coins_earned INTEGER DEFAULT 0,
  total_coins_spent INTEGER DEFAULT 0,
  
  -- Tier system
  tier_level INTEGER DEFAULT 1, -- 1: Bronze, 2: Silver, 3: Gold, 4: Platinum
  lifetime_value DECIMAL(12, 2) DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID REFERENCES loyalty_wallets(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id),
  
  transaction_type VARCHAR(20) NOT NULL, -- earned, spent, bonus, expired
  coins INTEGER NOT NULL,
  amount_spent DECIMAL(10, 2), -- For earned transactions
  
  description TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Loyalty tier thresholds
CREATE TABLE IF NOT EXISTS loyalty_tiers (
  tier_level INTEGER PRIMARY KEY,
  tier_name VARCHAR(50) NOT NULL,
  coins_to_earn_percentage INTEGER DEFAULT 1, -- 1% of order value
  min_lifetime_value DECIMAL(12, 2) DEFAULT 0,
  max_lifetime_value DECIMAL(12, 2),
  benefits TEXT[]
);

INSERT INTO loyalty_tiers (tier_level, tier_name, coins_to_earn_percentage, min_lifetime_value, max_lifetime_value, benefits)
VALUES 
  (1, 'Bronze', 1, 0, 10000, ARRAY['1% coins back']),
  (2, 'Silver', 2, 10000, 50000, ARRAY['2% coins back', 'Free delivery']),
  (3, 'Gold', 3, 50000, 200000, ARRAY['3% coins back', 'Free delivery', 'Priority support']),
  (4, 'Platinum', 5, 200000, NULL, ARRAY['5% coins back', 'Free delivery', 'Priority support', 'Exclusive offers']);

-- =====================================================
-- PUSH NOTIFICATIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS push_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Notification content
  title_en VARCHAR(200) NOT NULL,
  title_ar VARCHAR(200) NOT NULL,
  body_en TEXT NOT NULL,
  body_ar TEXT NOT NULL,
  image_url TEXT,
  
  -- Targeting
  target_type VARCHAR(20) NOT NULL, -- all, restaurant_area, user_segment
  target_area VARCHAR(100), -- For area-based targeting
  target_user_segment VARCHAR(50), -- For user segment targeting
  
  -- Scheduling
  is_scheduled BOOLEAN DEFAULT false,
  scheduled_at TIMESTAMP,
  
  -- Status
  status VARCHAR(20) DEFAULT 'draft', -- draft, scheduled, sent, failed
  
  -- Analytics
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  
  -- Admin info
  created_by UUID REFERENCES users(id),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sent_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  token VARCHAR(255) NOT NULL,
  device_type VARCHAR(20) NOT NULL, -- android, ios, web
  device_info TEXT,
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- GUEST CART (Pre-Auth)
-- =====================================================

CREATE TABLE IF NOT EXISTS guest_carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Anonymous identifier (stored in local storage)
  device_id VARCHAR(100) NOT NULL,
  
  -- Cart data (stored as JSON for simplicity)
  cart_data JSONB DEFAULT '[]',
  
  -- Created from IP/Location
  ip_address VARCHAR(50),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- DRIVER BATCHING / AI ROUTING
-- =====================================================

CREATE TABLE IF NOT EXISTS delivery_batches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  batch_name VARCHAR(100),
  driver_id UUID REFERENCES users(id),
  
  -- Batch status
  status VARCHAR(20) DEFAULT 'pending', -- pending, active, completed, cancelled
  
  -- Orders in batch
  order_ids UUID[] NOT NULL,
  
  -- Route info
  total_distance DECIMAL(10, 2), -- in km
  estimated_time INTEGER, -- in minutes
  
  -- Savings
  fuel_saved DECIMAL(10, 2),
  time_saved INTEGER,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

-- =====================================================
-- KITCHEN SETTINGS (Smart Mode)
-- =====================================================

CREATE TABLE IF NOT EXISTS kitchen_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  
  -- Smart Kitchen Mode
  smart_mode_enabled BOOLEAN DEFAULT false,
  auto_accept_orders BOOLEAN DEFAULT false,
  
  -- Sound settings
  sound_enabled BOOLEAN DEFAULT true,
  sound_volume INTEGER DEFAULT 100,
  custom_sound_url TEXT,
  
  -- Printer settings
  printer_enabled BOOLEAN DEFAULT false,
  printer_name VARCHAR(100),
  printer_ip VARCHAR(50),
  printer_port INTEGER DEFAULT 9100,
  
  -- Alert settings
  alert_for_pickup BOOLEAN DEFAULT true,
  alert_for_delivery BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- ORDER REORDER TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS order_reorders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  original_order_id UUID REFERENCES orders(id) NOT NULL,
  reorder_order_id UUID REFERENCES orders(id),
  
  customer_id UUID REFERENCES users(id),
  restaurant_id UUID REFERENCES restaurants(id),
  
  -- Reorder validation results
  was_restaurant_open BOOLEAN DEFAULT true,
  were_items_available BOOLEAN DEFAULT true,
  price_changed BOOLEAN DEFAULT false,
  old_prices JSONB, -- Old prices at time of original order
  new_prices JSONB, -- Current prices
  
  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, success, failed, price_changed
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SYSTEM THEME SETTINGS
-- =====================================================

CREATE TABLE IF NOT EXISTS theme_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  theme_mode VARCHAR(20) DEFAULT 'system', -- light, dark, system
  
  -- Custom colors (optional)
  primary_color VARCHAR(10),
  accent_color VARCHAR(10),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add theme to system settings
INSERT INTO system_settings (key, value, description) VALUES
('default_theme', '"system"', 'Default theme: light, dark, or system'),
('push_notifications_enabled', 'true', 'Enable push notifications'),
('loyalty_program_enabled', 'true', 'Enable loyalty points program'),
('smart_kitchen_default', 'false', 'Default smart kitchen mode'),
('guest_checkout_enabled', 'true', 'Enable guest checkout'),
('batch_deliveries_enabled', 'true', 'Enable AI driver batching');

-- =====================================================
-- FUNCTIONS FOR SMART FEATURES
-- =====================================================

-- Function to calculate loyalty coins earned
CREATE OR REPLACE FUNCTION calculate_loyalty_coins(
  p_order_total DECIMAL,
  p_tier_level INTEGER
) RETURNS INTEGER AS $$
DECLARE
  p_percentage INTEGER;
BEGIN
  SELECT coins_to_earn_percentage INTO p_percentage
  FROM loyalty_tiers
  WHERE tier_level = p_tier_level;
  
  RETURN (p_order_total * p_percentage / 100)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to validate reorder
CREATE OR REPLACE FUNCTION validate_reorder(
  p_user_id UUID,
  p_restaurant_id UUID,
  p_order_id UUID
) RETURNS TABLE (
  can_reorder BOOLEAN,
  is_open BOOLEAN,
  items_available BOOLEAN,
  has_price_changes BOOLEAN,
  price_changes JSONB
) AS $$
DECLARE
  v_restaurant RECORD;
  v_original_items JSONB;
  v_current_items JSONB;
  v_price_changes JSONB := '[]'::JSONB;
  v_can_reorder BOOLEAN := true;
BEGIN
  -- Check 1: Is restaurant open?
  SELECT * INTO v_restaurant
  FROM restaurants
  WHERE id = p_restaurant_id;
  
  IF NOT v_restaurant.is_open OR 
     CURRENT_TIME < v_restaurant.opening_time OR 
     CURRENT_TIME > v_restaurant.closing_time THEN
    RETURN QUERY SELECT false, false, NULL, NULL, NULL;
  END IF;
  
  -- Check 2 & 3: Items and prices
  -- (In production, this would compare actual menu items)
  
  RETURN QUERY SELECT true, true, true, false, '[]'::JSONB;
END;
$$ LANGUAGE plpgsql;

SELECT '✅ Pro-tier features schema created!' as status;