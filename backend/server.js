require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const { v4: cloudinaryv4 } = require('cloudinary');
const { pool } = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;

// Security: Rate Limiting (prevent brute-force attacks)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10, // 10 attempts per window
    message: { error: 'Too many attempts, please try again after 15 minutes' },
    standardHeaders: true,
    legacyHeaders: false,
});

const apiLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute
    message: { error: 'Too many requests' },
    standardHeaders: true,
    legacyHeaders: false,
});

// Middleware
app.use(helmet()); // Security headers
app.use(cors());
app.use(apiLimiter); // API rate limit
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cloudinary Config
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'omni_market_super_secret_key_2024';

// ═══════════════════════════════════════════════════════════
// MIDDLEWARE: Auth & Role Check
// ═══════════════════════════════════════════════════════════
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'Access token required' });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid or expired token' });
        req.user = user;
        next();
    });
};

// Role check middleware
const requireRole = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
};

// ═══════════════════════════════════════════════════════════
// AUTH ROUTES
// ═══════════════════════════════════════════════════════════

// Register (rate limited)
app.post('/api/auth/register', authLimiter, async (req, res) => {
    try {
        const { email, password, full_name, phone, role = 'customer' } = req.body;

        // Check if user exists
        const userExists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const password_hash = await bcrypt.hash(password, salt);

        // Default status based on role
        const status = role === 'delivery' ? 'pending' : 'active';

        // Insert user
        const result = await pool.query(
            `INSERT INTO users (email, password_hash, full_name, phone, role, status)
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, email, full_name, role, status`,
            [email, password_hash, full_name, phone, role, status]
        );

        // Generate token
        const user = result.rows[0];
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({ user, token });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Login (rate limited)
app.post('/api/auth/login', authLimiter, async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = result.rows[0];

        // SECURITY GATE: Delivery users must have 'active' status
        if (user.role === 'delivery' && user.status !== 'active') {
            return res.status(403).json({
                error: 'Your account is not active yet. Please wait for admin approval.',
                status: user.status
            });
        }

        // Blocked users
        if (user.status === 'blocked') {
            return res.status(403).json({ error: 'Your account has been blocked' });
        }

        // Verify password
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate token
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        // Remove password hash from response
        delete user.password_hash;
        res.json({ user, token });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Get current user
app.get('/api/auth/me', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, email, full_name, phone, role, status, created_at FROM users WHERE id = $1',
            [req.user.id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ═══════════════════════════════════════════════════════════
// PRODUCT ROUTES (Optimized for 5,000+ items)
// ═══════════════════════════════════════════════════════════

// Get all products with pagination & search
app.get('/api/products', async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            search = '',
            category = '',
            sub_category = '',
            sort_by = 'created_at',
            order = 'desc',
            min_price,
            max_price,
            brand
        } = req.query;

        const offset = (page - 1) * limit;
        const params = [];
        let whereClause = 'WHERE is_active = true';

        // Search
        if (search) {
            whereClause += ` AND (LOWER(name) LIKE LOWER($${params.length + 1}) OR LOWER(description) LIKE LOWER($${params.length + 1}))`;
            params.push(`%${search}%`);
        }

        // Category filter
        if (category) {
            whereClause += ` AND category = $${params.length + 1}`;
            params.push(category);
        }

        // Sub-category filter
        if (sub_category) {
            whereClause += ` AND sub_category = $${params.length + 1}`;
            params.push(sub_category);
        }

        // Price range
        if (min_price) {
            whereClause += ` AND price >= $${params.length + 1}`;
            params.push(min_price);
        }
        if (max_price) {
            whereClause += ` AND price <= $${params.length + 1}`;
            params.push(max_price);
        }

        // Brand filter
        if (brand) {
            whereClause += ` AND brand = $${params.length + 1}`;
            params.push(brand);
        }

        // Get total count
        const countResult = await pool.query(`SELECT COUNT(*) FROM products ${whereClause}`, params);
        const total = parseInt(countResult.rows[0].count);

        // Get products
        const validSortColumns = ['name', 'price', 'created_at', 'stock_quantity'];
        const sortColumn = validSortColumns.includes(sort_by) ? sort_by : 'created_at';
        const sortOrder = order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

        const productsQuery = `
            SELECT id, name, description, price, stock_quantity, category, sub_category, brand, image_urls, created_at
            FROM products
            ${whereClause}
            ORDER BY ${sortColumn} ${sortOrder}
            LIMIT $${params.length + 1} OFFSET $${params.length + 2}
        `;
        params.push(limit, offset);

        const products = await pool.query(productsQuery, params);

        res.json({
            products: products.rows,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                totalPages: Math.ceil(total / limit)
            }
        });
    } catch (error) {
        console.error('Products error:', error);
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// Get single product
app.get('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            'SELECT * FROM products WHERE id = $1 AND is_active = true',
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Get categories
app.get('/api/categories', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT category, sub_category, COUNT(*) as count
            FROM products
            WHERE is_active = true
            GROUP BY category, sub_category
            ORDER BY category, sub_category
        `);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Admin: Add product
app.post('/api/products', authenticateToken, requireRole('admin'), async (req, res) => {
    try {
        const {
            name, description, price, stock_quantity,
            category, sub_category, brand, image_urls, specifications
        } = req.body;

        const result = await pool.query(`
            INSERT INTO products (name, description, price, stock_quantity, category, sub_category, brand, image_urls, specifications)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
        `, [name, description, price, stock_quantity, category, sub_category, brand, image_urls, specifications]);

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error('Add product error:', error);
        res.status(500).json({ error: 'Failed to add product' });
    }
});

// Admin: Update product
app.put('/api/products/:id', authenticateToken, requireRole('admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        const setClauses = [];
        const values = [];
        let paramCount = 1;

        for (const [key, value] of Object.entries(updates)) {
            setClauses.push(`${key} = $${paramCount}`);
            values.push(value);
            paramCount++;
        }
        setClauses.push(`updated_at = CURRENT_TIMESTAMP`);
        values.push(id);

        const result = await pool.query(
            `UPDATE products SET ${setClauses.join(', ')} WHERE id = $${paramCount} RETURNING *`,
            values
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ═══════════════════════════════════════════════════════════
// ORDER ROUTES
// ═══════════════════════════════════════════════════════════

// Create order
app.post('/api/orders', authenticateToken, async (req, res) => {
    try {
        const { items, delivery_address, delivery_phone, notes } = req.body;
        const customer_id = req.user.id;

        // Calculate total
        let total_amount = 0;
        for (const item of items) {
            const product = await pool.query('SELECT price FROM products WHERE id = $1', [item.product_id]);
            if (product.rows.length > 0) {
                total_amount += product.rows[0].price * item.quantity;
            }
        }

        // Create order
        const orderResult = await pool.query(`
            INSERT INTO orders (customer_id, total_amount, delivery_address, delivery_phone, notes)
            VALUES ($1, $2, $3, $4, $5) RETURNING *
        `, [customer_id, total_amount, delivery_address, delivery_phone, notes]);

        const orderId = orderResult.rows[0].id;

        // Add order items
        for (const item of items) {
            const product = await pool.query('SELECT price FROM products WHERE id = $1', [item.product_id]);
            if (product.rows.length > 0) {
                await pool.query(`
                    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                    VALUES ($1, $2, $3, $4)
                `, [orderId, item.product_id, item.quantity, product.rows[0].price]);
            }
        }

        res.status(201).json({ order: orderResult.rows[0], message: 'Order created successfully' });
    } catch (error) {
        console.error('Order creation error:', error);
        res.status(500).json({ error: 'Failed to create order' });
    }
});

// Get customer orders
app.get('/api/orders', authenticateToken, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT o.*, u.full_name as delivery_name
            FROM orders o
            LEFT JOIN users u ON o.delivery_id = u.id
            WHERE o.customer_id = $1
            ORDER BY o.created_at DESC
        `, [req.user.id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Delivery: Get assigned orders
app.get('/api/delivery/orders', authenticateToken, requireRole('delivery', 'admin'), async (req, res) => {
    try {
        let query = `
            SELECT o.*, u.full_name as customer_name, u.phone as customer_phone
            FROM orders o
            JOIN users u ON o.customer_id = u.id
            WHERE o.delivery_id = $1 OR (o.delivery_id IS NULL AND o.status IN ('confirmed', 'preparing'))
            ORDER BY o.created_at DESC
        `;

        if (req.user.role === 'admin') {
            query = `
                SELECT o.*, u.full_name as customer_name, u.phone as customer_phone
                FROM orders o
                JOIN users u ON o.customer_id = u.id
                WHERE o.status NOT IN ('delivered', 'cancelled')
                ORDER BY o.created_at DESC
            `;
        }

        const result = await pool.query(query, req.user.role === 'admin' ? [] : [req.user.id]);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Update order status (Delivery/Admin)
app.put('/api/orders/:id/status', authenticateToken, requireRole('delivery', 'admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const result = await pool.query(`
            UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *
        `, [status, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }
        res.json(result.rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// ═══════════════════════════════════════════════════════════
// ADMIN ROUTES
// ═══════════════════════════════════════════════════════════

// Get all users
app.get('/api/admin/users', authenticateToken, requireRole('admin'), async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT id, email, full_name, phone, role, status, created_at
            FROM users ORDER BY created_at DESC
        `);
        res.json(result.rows);
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// Update user status (for delivery approval)
app.put('/api/admin/users/:id/status', authenticateToken, requireRole('admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const result = await pool.query(`
            UPDATE users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *
        `, [status, id]);

        res.json(result.rows[0]);
    } catch (error) {
        res.status(500).json({ error: 'Update failed' });
    }
});

// Stats dashboard
app.get('/api/admin/stats', authenticateToken, requireRole('admin'), async (req, res) => {
    try {
        const [users, products, orders, revenue] = await Promise.all([
            pool.query('SELECT role, COUNT(*) as count FROM users GROUP BY role'),
            pool.query('SELECT COUNT(*) as count FROM products WHERE is_active = true'),
            pool.query('SELECT COUNT(*) as count FROM orders'),
            pool.query('SELECT SUM(total_amount) as total FROM orders WHERE status = \'delivered\'')
        ]);

        res.json({
            users: users.rows,
            products: products.rows[0].count,
            orders: orders.rows[0].count,
            revenue: revenue.rows[0].total || 0
        });
    } catch (error) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ═══════════════════════════════════════════════════════════
// IMAGE UPLOAD (Multer + Cloudinary)
// ═══════════════════════════════════════════════════════════

const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'));
        }
    }
});

app.post('/api/upload', authenticateToken, requireRole('admin'), upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        const result = await cloudinary.uploader.upload_stream({
            folder: 'omnimarket',
            resource_type: 'auto'
        }, (error, result) => {
            if (error) throw error;
            res.json({ url: result.secure_url });
        });

        result.end(req.file.buffer);
    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ error: 'Upload failed' });
    }
});

// ═══════════════════════════════════════════════════════════
// HEALTH CHECK
// ═══════════════════════════════════════════════════════════
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 OmniMarket API running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;