-- =====================================================
-- TAYYEB-GO: COMPLETE DATABASE SCHEMA
-- Syrian Food Delivery Platform (PostgreSQL/Supabase)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- ENUMS
-- =====================================================

CREATE TYPE user_role AS ENUM ('super_admin', 'restaurant_owner', 'cashier', 'driver', 'customer');

CREATE TYPE order_status AS ENUM (
  'pending', 'confirmed', 'preparing', 'ready', 
  'picked_up', 'en_route', 'delivered', 'cancelled'
);

CREATE TYPE delivery_type AS ENUM ('delivery', 'pickup');

CREATE TYPE payment_method AS ENUM ('cash', 'syriatel', 'sham_card', 'credit_card');

CREATE TYPE driver_status AS ENUM ('offline', 'online', 'busy');

-- =====================================================
-- USERS TABLE
-- =====================================================

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  nickname VARCHAR(50),
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'customer',
  
  -- Profile fields
  date_of_birth DATE,
  gender VARCHAR(20),
  
  -- Location
  default_address_id UUID,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address_text TEXT,
  
  -- Driver specific
  driver_license VARCHAR(50),
  vehicle_type VARCHAR(50),
  vehicle_plate VARCHAR(20),
  driver_status driver_status DEFAULT 'offline',
  
  -- Restaurant owner specific
  restaurant_id UUID,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  verification_token VARCHAR(10),
  reset_token VARCHAR(255),
  reset_expires TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP
);

-- Index for role-based queries
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_restaurant ON users(restaurant_id) WHERE role = 'restaurant_owner';

-- =====================================================
-- RESTAURANTS TABLE
-- =====================================================

CREATE TABLE restaurants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Basic info
  name VARCHAR(200) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  cover_image_url TEXT,
  
  -- Location
  address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  area VARCHAR(100),
  city VARCHAR(50) NOT NULL,
  
  -- Contact
  phone VARCHAR(20) NOT NULL,
  whatsapp VARCHAR(20),
  email VARCHAR(255),
  
  -- Business hours
  opening_time TIME NOT NULL,
  closing_time TIME NOT NULL,
  is_open BOOLEAN DEFAULT true,
  
  -- Categories
  cuisine_types TEXT[], -- e.g., ['fast_food', 'shawarma', 'desserts']
  
  -- Rating
  rating DECIMAL(3, 2) DEFAULT 0,
  total_ratings INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  
  -- Commission
  commission_rate DECIMAL(5, 2) DEFAULT 15.00, -- 15% default
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_restaurants_owner ON restaurants(owner_id);
CREATE INDEX idx_restaurants_city ON restaurants(city);
CREATE INDEX idx_restaurants_is_open ON restaurants(is_open);

-- =====================================================
-- RESTAURANT BRANCHES TABLE
-- =====================================================

CREATE TABLE restaurant_branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  
  name VARCHAR(200) NOT NULL,
  address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  
  is_primary BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- CATEGORIES TABLE
-- =====================================================

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  name_en VARCHAR(100) NOT NULL,
  name_ar VARCHAR(100) NOT NULL,
  description TEXT,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_restaurant ON categories(restaurant_id);

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  
  name_en VARCHAR(200) NOT NULL,
  name_ar VARCHAR(200) NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  
  image_url TEXT,
  thumbnail_url TEXT,
  
  base_price DECIMAL(10, 2) NOT NULL,
  
  -- Options
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  is_vegetarian BOOLEAN DEFAULT false,
  is_spicy BOOLEAN DEFAULT false,
  preparation_time_minutes INTEGER DEFAULT 15,
  
  -- Sort
  sort_order INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_restaurant ON products(restaurant_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_is_available ON products(is_available);

-- =====================================================
-- MODIFIER GROUPS TABLE (For customization)
-- =====================================================

CREATE TABLE modifier_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  
  name_en VARCHAR(100) NOT NULL,
  name_ar VARCHAR(100) NOT NULL,
  
  -- Rules
  is_required BOOLEAN DEFAULT false,
  min_selections INTEGER DEFAULT 1,
  max_selections INTEGER DEFAULT 1,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_modifier_groups_product ON modifier_groups(product_id);

-- =====================================================
-- MODIFIER OPTIONS TABLE
-- =====================================================

CREATE TABLE modifier_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  modifier_group_id UUID REFERENCES modifier_groups(id) ON DELETE CASCADE,
  
  name_en VARCHAR(100) NOT NULL,
  name_ar VARCHAR(100) NOT NULL,
  
  price_adjustment DECIMAL(10, 2) DEFAULT 0,
  is_default BOOLEAN DEFAULT false,
  
  sort_order INTEGER DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_modifier_options_group ON modifier_options(modifier_group_id);

-- =====================================================
-- ORDERS TABLE
-- =====================================================

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number VARCHAR(20) UNIQUE NOT NULL,
  
  -- Relationships
  customer_id UUID REFERENCES users(id),
  restaurant_id UUID REFERENCES restaurants(id),
  driver_id UUID REFERENCES users(id),
  address_id UUID REFERENCES user_addresses(id),
  
  -- Status
  status order_status DEFAULT 'pending',
  delivery_type delivery_type DEFAULT 'delivery',
  
  -- Items summary
  items_count INTEGER DEFAULT 0,
  subtotal DECIMAL(10, 2) NOT NULL,
  delivery_fee DECIMAL(10, 2) DEFAULT 0,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  
  -- Payment
  payment_method payment_method DEFAULT 'cash',
  payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed
  payment_reference VARCHAR(100),
  
  -- Delivery
  estimated_delivery_time TIMESTAMP,
  actual_delivery_time TIMESTAMP,
  delivery_address TEXT,
  delivery_latitude DECIMAL(10, 8),
  delivery_longitude DECIMAL(11, 8),
  
  -- Notes
  customer_notes TEXT,
  admin_notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  confirmed_at TIMESTAMP,
  preparing_at TIMESTAMP,
  ready_at TIMESTAMP,
  picked_up_at TIMESTAMP,
  delivered_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancelled_by UUID,
  cancellation_reason TEXT,
  
  -- Commission tracking
  commission_amount DECIMAL(10, 2),
  restaurant_earnings DECIMAL(10, 2),
  driver_earnings DECIMAL(10, 2)
);

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_driver ON orders(driver_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);

-- =====================================================
-- ORDER ITEMS TABLE
-- =====================================================

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  
  product_name_en VARCHAR(200),
  product_name_ar VARCHAR(200),
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  
  -- Customization
  selected_modifiers JSONB DEFAULT '[]',
  custom_request TEXT,
  
  -- Status (for kitchen)
  status VARCHAR(50) DEFAULT 'pending',
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- =====================================================
-- USER ADDRESSES TABLE
-- =====================================================

CREATE TABLE user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  label VARCHAR(50), -- Home, Work, Other
  address TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  building_number VARCHAR(20),
  floor VARCHAR(20),
  apartment VARCHAR(20),
  instructions TEXT,
  
  is_default BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);

-- =====================================================
-- DRIVER LOCATIONS TABLE (Real-time tracking)
-- =====================================================

CREATE TABLE driver_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  accuracy DECIMAL(5, 2),
  speed DECIMAL(5, 2),
  heading DECIMAL(5, 2),
  
  is_active BOOLEAN DEFAULT true,
  
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_driver_locations_driver ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_recorded ON driver_locations(recorded_at DESC);

-- =====================================================
-- DRIVER ORDERS TABLE
-- =====================================================

CREATE TABLE driver_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID REFERENCES users(id),
  order_id UUID REFERENCES orders(id),
  
  status VARCHAR(50) DEFAULT 'assigned', -- assigned, accepted, picked_up, delivered, cancelled
  
  pickup_time TIMESTAMP,
  delivery_time TIMESTAMP,
  
  earnings DECIMAL(10, 2),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PAYMENTS TABLE
-- =====================================================

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id),
  
  amount DECIMAL(10, 2) NOT NULL,
  method payment_method NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  
  -- Payment gateway info
  gateway_reference VARCHAR(100),
  transaction_id VARCHAR(100),
  gateway_response JSONB,
  
  paid_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_order ON payments(order_id);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  type VARCHAR(50) NOT NULL, -- order, payment, system, chat
  title_en VARCHAR(200),
  title_ar VARCHAR(200),
  body_en TEXT,
  body_ar TEXT,
  
  data JSONB DEFAULT '{}',
  
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- =====================================================
-- CHAT MESSAGES TABLE
-- =====================================================

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Conversation identifier
  conversation_type VARCHAR(50) NOT NULL, -- order, customer_driver, customer_restaurant
  conversation_id UUID NOT NULL,
  
  sender_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  
  message_text TEXT,
  message_type VARCHAR(50) DEFAULT 'text', -- text, image, location
  
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_conversation ON chat_messages(conversation_type, conversation_id);
CREATE INDEX idx_chat_receiver ON chat_messages(receiver_id, is_read);

-- =====================================================
-- REVIEWS TABLE
-- =====================================================

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  order_id UUID REFERENCES orders(id),
  customer_id UUID REFERENCES users(id),
  restaurant_id UUID REFERENCES restaurants(id),
  driver_id UUID REFERENCES users(id),
  
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  
  -- Ratings breakdown
  food_rating INTEGER CHECK (food_rating >= 1 AND food_rating <= 5),
  delivery_rating INTEGER CHECK (delivery_rating >= 1 AND delivery_rating <= 5),
  service_rating INTEGER CHECK (service_rating >= 1 AND service_rating <= 5),
  
  is_visible BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_restaurant ON reviews(restaurant_id);
CREATE INDEX idx_reviews_order ON reviews(order_id);

-- =====================================================
-- DELIVERY ZONES TABLE
-- =====================================================

CREATE TABLE delivery_zones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
  
  name_en VARCHAR(100) NOT NULL,
  name_ar VARCHAR(100) NOT NULL,
  
  -- Zone polygon (stored as JSON)
  coordinates JSONB NOT NULL,
  
  delivery_fee DECIMAL(10, 2) NOT NULL,
  minimum_order DECIMAL(10, 2) DEFAULT 0,
  estimated_time_minutes INTEGER DEFAULT 30,
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PROMOTIONS TABLE
-- =====================================================

CREATE TABLE promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  code VARCHAR(50) UNIQUE NOT NULL,
  name_en VARCHAR(200) NOT NULL,
  name_ar VARCHAR(200) NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  
  discount_type VARCHAR(20) NOT NULL, -- percentage, fixed
  discount_value DECIMAL(10, 2) NOT NULL,
  maximum_discount DECIMAL(10, 2),
  
  min_order_amount DECIMAL(10, 2),
  max_uses INTEGER,
  uses_count INTEGER DEFAULT 0,
  
  valid_from TIMESTAMP NOT NULL,
  valid_until TIMESTAMP NOT NULL,
  
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- OFFLINE SYNC QUEUE TABLE
-- =====================================================

CREATE TABLE sync_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  user_id UUID REFERENCES users(id),
  device_id VARCHAR(100),
  
  operation VARCHAR(20) NOT NULL, -- create, update, delete
  table_name VARCHAR(50) NOT NULL,
  record_id UUID NOT NULL,
  data JSONB NOT NULL,
  
  status VARCHAR(20) DEFAULT 'pending', -- pending, synced, failed
  retry_count INTEGER DEFAULT 0,
  error_message TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMP
);

CREATE INDEX idx_sync_queue_user ON sync_queue(user_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(status);

-- =====================================================
-- SYSTEM SETTINGS TABLE
-- =====================================================

CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  key VARCHAR(100) UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Default settings
INSERT INTO system_settings (key, value, description) VALUES
('app_name', '"Tayyeb-Go"', 'Application name'),
('default_language', '"en"', 'Default language'),
('supported_languages', '["en", "ar"]', 'Supported languages'),
('default_delivery_fee', '1500', 'Default delivery fee in SYP'),
('default_commission_rate', '15', 'Default commission rate in percentage'),
('max_retry_sync', '5', 'Maximum retry count for offline sync'),
('maintenance_mode', 'false', 'System maintenance mode - kill switch');

-- =====================================================
-- ANALYTICS TABLES
-- =====================================================

CREATE TABLE daily_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  date DATE NOT NULL,
  restaurant_id UUID REFERENCES restaurants(id),
  
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(12, 2) DEFAULT 0,
  total_delivery_fee DECIMAL(10, 2) DEFAULT 0,
  total_commission DECIMAL(10, 2) DEFAULT 0,
  total_discount DECIMAL(10, 2) DEFAULT 0,
  
  new_customers INTEGER DEFAULT 0,
  new_restaurants INTEGER DEFAULT 0,
  new_drivers INTEGER DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_daily_stats_date_restaurant ON daily_stats(date, restaurant_id);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
  order_count INTEGER;
  year_str TEXT;
BEGIN
  year_str := EXTRACT(YEAR FROM CURRENT_DATE)::TEXT;
  SELECT COUNT(*) + 1 INTO order_count FROM orders WHERE created_at >= CURRENT_DATE;
  NEW.order_number := 'TG' || year_str || LPAD(order_count::TEXT, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for order number
CREATE TRIGGER set_order_number
  BEFORE INSERT ON orders
  FOR EACH ROW
  WHEN (NEW.order_number IS NULL)
  EXECUTE FUNCTION generate_order_number();

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- FINAL INDEXES FOR PERFORMANCE
-- =====================================================

-- Full-text search index for products
CREATE INDEX idx_products_search_en ON products USING gin(to_tsvector('english', name_en || ' ' || COALESCE(description_en, '')));
CREATE INDEX idx_products_search_ar ON products USING gin(to_tsvector('arabic', name_ar || ' ' || COALESCE(description_ar, '')));

-- Full-text search index for restaurants
CREATE INDEX idx_restaurants_search_en ON restaurants USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));
CREATE INDEX idx_restaurants_search_ar ON restaurants USING gin(to_tsvector('arabic', name || ' ' || COALESCE(description, '')));

-- =====================================================
-- SEEDS (Initial Data)
-- =====================================================

-- Create Super Admin
INSERT INTO users (email, phone, password_hash, display_name, role, is_verified)
VALUES ('admin@tayyeb.com', '+963999999999', '$2a$10$dummy_hash_for_demo', 'System Admin', 'super_admin', true);

-- Create sample restaurants
INSERT INTO restaurants (name, slug, address, city, phone, latitude, longitude, opening_time, closing_time, cuisine_types, rating, is_active)
VALUES 
  ('Al Mandi House', 'al-mandi-house', 'Al-Mansour, Damascus', 'Damascus', '+963112345678', 33.5138, 36.2765, '10:00', '23:00', ARRAY['syrian', 'middle_eastern'], 4.5, true),
  ('Pizza Al Sheikh', 'pizza-al-sheikh', 'Al-Mazza, Damascus', 'Damascus', '+963112345679', 33.5250, 36.2900, '11:00', '00:00', ARRAY['pizza', 'italian'], 4.3, true),
  ('Sweet Dreams Bakery', 'sweet-dreams-bakery', 'Al-Karaj, Damascus', 'Damascus', '+963112345680', 33.5200, 36.2800, '08:00', '22:00', ARRAY['desserts', 'bakery'], 4.7, true);

-- Create sample users for demo
INSERT INTO users (email, phone, password_hash, display_name, role, restaurant_id, is_verified)
SELECT 
  email, phone, password_hash, display_name, role, 
  (SELECT id FROM restaurants LIMIT 1), 
  true
FROM (
  SELECT 'owner@almandi.com' as email, '+963951111111' as phone, '$2a$10$dummy' as password_hash, 'Al Mandi Owner' as display_name, 'restaurant_owner' as role
  UNION ALL
  SELECT 'cashier@almandi.com', '+963951111112', '$2a$10$dummy', 'Ahmed Cashier', 'cashier'
  UNION ALL
  SELECT 'driver@company.com', '+963951111113', '$2a$10$dummy', 'Khaled Driver', 'driver'
  UNION ALL
  SELECT 'user@test.com', '+963951111114', '$2a$10$dummy', 'John Customer', 'customer'
) AS users;

SELECT 'Database schema created successfully!' as status;