-- OmniMarket Database Schema

-- Drop existing tables if they exist (for fresh setup)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create Users Table (3 roles: admin, delivery, customer)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'delivery', 'customer')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'blocked')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Products Table (optimized for 5,000+ items)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100),
    brand VARCHAR(100),
    image_urls TEXT[], -- Array of image URLs
    specifications JSONB, -- Technical specs stored as JSON
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Orders Table (enhanced with driver tracking)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    delivery_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'picked_up', 'shipped', 'out_for_delivery', 'delivered', 'cancelled')),
    total_amount DECIMAL(10, 2) NOT NULL,
    delivery_address TEXT,
    delivery_phone VARCHAR(20),
    payment_method VARCHAR(20) DEFAULT 'cod' CHECK (payment_method IN ('cod', 'card', 'online')),
    payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    notes TEXT,
    assigned_driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    current_location JSONB,
    estimated_delivery_time TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Order Items Table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes for Performance
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_sub_category ON products(sub_category);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_delivery ON orders(delivery_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_assigned_driver ON orders(assigned_driver_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Add Driver Location Table for Real-Time Tracking
CREATE TABLE driver_locations (
    id SERIAL PRIMARY KEY,
    driver_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    current_location JSONB,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_online BOOLEAN DEFAULT false
);

CREATE INDEX idx_driver_locations_driver ON driver_locations(driver_id);

-- Insert Sample Admin User (password: admin123)
INSERT INTO users (email, password_hash, full_name, role, status)
VALUES ('admin@omnimarket.com', '$2a$10$XQxBtL8qVJ6ZqZqZqZqZuZOJZJ6ZJ6ZJ6ZJ6ZJ6ZJ6ZJ6ZJ6ZJ6Z', 'System Admin', 'admin', 'active');

-- Insert Sample Data Categories
INSERT INTO products (name, description, price, stock_quantity, category, sub_category, brand, image_urls, specifications)
VALUES
('Samsung Galaxy Buds Pro', 'Wireless earbuds with active noise cancellation', 149.99, 100, 'Electronics', 'Audio', 'Samsung', ARRAY['https://placeholder.com/buds.jpg'], '{"color": "Black", "bluetooth": "5.0", "battery_life": "8 hours"}'),
('Nike Air Max 270', 'Men running shoes with air cushioning', 159.99, 50, 'Fashion', 'Shoes', 'Nike', ARRAY['https://placeholder.com/airmax.jpg'], '{"size": "10", "color": "Black/White", "material": "Mesh/Synthetic"}'),
('Sony 55" 4K TV', 'Ultra HD Smart TV with HDR', 599.99, 25, 'Electronics', 'TVs', 'Sony', ARRAY['https://placeholder.com/tv.jpg'], '{"resolution": "3840x2160", "screen_size": "55 inch", "hdr": true}');