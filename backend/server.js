const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = 'omnimarket_secret_key_2024';
const PORT = 5000;

// ============ DATABASE ============
const db = {
  users: [],
  products: [
    { id: 1, name: 'Fresh Apples', price: 3.99, stock: 50, category: 'Fruits', image: 'https://via.placeholder.com/300?text=Apples' },
    { id: 2, name: 'Bananas', price: 1.49, stock: 100, category: 'Fruits', image: 'https://via.placeholder.com/300?text=Bananas' },
    { id: 3, name: 'Organic Milk', price: 4.99, stock: 30, category: 'Dairy', image: 'https://via.placeholder.com/300?text=Milk' },
    { id: 4, name: 'Whole Bread', price: 2.99, stock: 20, category: 'Bakery', image: 'https://via.placeholder.com/300?text=Bread' },
    { id: 5, name: 'Tomatoes', price: 2.49, stock: 40, category: 'Vegetables', image: 'https://via.placeholder.com/300?text=Tomatoes' },
    { id: 6, name: 'Orange Juice', price: 3.49, stock: 25, category: 'Beverages', image: 'https://via.placeholder.com/300?text=Juice' },
    { id: 7, name: 'Chicken Breast', price: 7.99, stock: 15, category: 'Meat', image: 'https://via.placeholder.com/300?text=Chicken' },
    { id: 8, name: 'Greek Yogurt', price: 2.99, stock: 35, category: 'Dairy', image: 'https://via.placeholder.com/300?text=Yogurt' },
  ],
  categories: ['Fruits', 'Vegetables', 'Dairy', 'Meat', 'Bakery', 'Beverages'],
  orders: [],
  deliveryApplications: [],
  notifications: [],
  verificationCodes: [],
  passwordResetCodes: [],
};

// ============ HELPER FUNCTIONS ============
const generateId = () => Math.floor(Math.random() * 1000000);
const generateToken = (user) => jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });

// ============ AUTH ROUTES ============

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, name, phone } = req.body;
    
    if (db.users.find(u => u.email === email)) {
      return res.status(400).json({ error: 'Email already exists' });
    }
    
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = {
      id: generateId(),
      email,
      password: hashedPassword,
      name,
      phone,
      role: 'customer',
      status: 'pending',
      verified: false,
      emailVerified: false,
      phoneVerified: false,
      createdAt: new Date().toISOString(),
    };
    
    db.users.push(user);
    
    // Send verification code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    db.verificationCodes.push({ email, code, type: 'email_verification', expires: Date.now() + 3600000 });
    
    res.json({ 
      success: true, 
      message: 'Registration successful. Please verify your email.',
      user: { id: user.id, email: user.email, name: user.name, role: user.role }
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Verify Email
app.post('/api/auth/verify-email', (req, res) => {
  const { email, code } = req.body;
  const verification = db.verificationCodes.find(v => v.email === email && v.code === code && v.type === 'email_verification');
  
  if (!verification || verification.expires < Date.now()) {
    return res.status(400).json({ error: 'Invalid or expired code' });
  }
  
  const user = db.users.find(u => u.email === email);
  if (user) {
    user.emailVerified = true;
    if (user.phoneVerified) user.status = 'active';
  }
  
  db.verificationCodes = db.verificationCodes.filter(v => v.email !== email || v.code !== code);
  res.json({ success: true, message: 'Email verified successfully' });
});

// Verify Phone (OTP)
app.post('/api/auth/verify-phone', (req, res) => {
  const { phone, code } = req.body;
  const verification = db.verificationCodes.find(v => v.phone === phone && v.code === code && v.type === 'phone_verification');
  
  if (!verification || verification.expires < Date.now()) {
    return res.status(400).json({ error: 'Invalid or expired code' });
  }
  
  const user = db.users.find(u => u.phone === phone);
  if (user) {
    user.phoneVerified = true;
    if (user.emailVerified) user.status = 'active';
  }
  
  db.verificationCodes = db.verificationCodes.filter(v => v.phone !== phone || v.code !== code);
  res.json({ success: true, message: 'Phone verified successfully' });
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = db.users.find(u => u.email === email);
    
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    if (user.status === 'pending') {
      return res.status(400).json({ error: 'Please verify your email and phone' });
    }
    
    const token = generateToken(user);
    res.json({ 
      token, 
      user: { 
        id: user.id, 
        email: user.email, 
        name: user.name, 
        phone: user.phone,
        role: user.role 
      } 
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Forgot Password
app.post('/api/auth/forgot-password', (req, res) => {
  const { email } = req.body;
  const user = db.users.find(u => u.email === email);
  
  if (!user) {
    return res.status(404).json({ error: 'Email not found' });
  }
  
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  db.passwordResetCodes.push({ email, code, expires: Date.now() + 3600000 });
  
  res.json({ success: true, message: 'Password reset code sent to your email' });
});

// Reset Password
app.post('/api/auth/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;
  const reset = db.passwordResetCodes.find(r => r.email === email && r.code === code);
  
  if (!reset || reset.expires < Date.now()) {
    return res.status(400).json({ error: 'Invalid or expired code' });
  }
  
  const user = db.users.find(u => u.email === email);
  if (user) {
    user.password = await bcrypt.hash(newPassword, 10);
  }
  
  db.passwordResetCodes = db.passwordResetCodes.filter(r => r.email !== email);
  res.json({ success: true, message: 'Password reset successfully' });
});

// Get Current User
app.get('/api/auth/me', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.users.find(u => u.id === decoded.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    res.json({ 
      id: user.id, 
      email: user.email, 
      name: user.name, 
      phone: user.phone,
      role: user.role,
      verified: user.verified
    });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// ============ PRODUCTS ============
app.get('/api/products', (req, res) => {
  res.json({ products: db.products });
});

app.get('/api/categories', (req, res) => {
  res.json({ categories: db.categories });
});

// ============ ORDERS ============
app.get('/api/orders', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const userOrders = db.orders.filter(o => o.customerId === decoded.id);
    res.json({ orders: userOrders });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

app.post('/api/orders', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { items, address, phone, notes } = req.body;
    
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const deliveryFee = subtotal > 50 ? 0 : 5;
    const total = subtotal + deliveryFee;
    
    const order = {
      id: generateId(),
      orderNumber: `OM${Date.now()}`,
      customerId: decoded.id,
      items,
      subtotal,
      deliveryFee,
      total,
      address,
      phone,
      notes,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };
    
    db.orders.push(order);
    res.json({ success: true, order });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// ============ DELIVERY APPLICATION ============
app.post('/api/delivery/apply', (req, res) => {
  const { firstName, middleName, nickname, phone, altPhone, email, city, vehicleType, vehicleDetails } = req.body;
  
  const application = {
    id: generateId(),
    firstName,
    middleName,
    nickname,
    phone,
    altPhone,
    email,
    city,
    vehicleType,
    vehicleDetails,
    status: 'pending',
    appliedAt: new Date().toISOString(),
    deliveries: 0,
    rating: 5.0,
  };
  
  db.deliveryApplications.push(application);
  
  // Create notification for admin
  db.notifications.push({
    id: generateId(),
    type: 'new_delivery_application',
    title: 'New Delivery Application',
    message: `${firstName} ${middleName} applied as delivery driver`,
    data: application,
    createdAt: new Date().toISOString(),
    read: false,
  });
  
  res.json({ success: true, message: 'Application submitted successfully!' });
});

// Get Delivery Applications (Admin only)
app.get('/api/admin/delivery-applications', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }
    res.json({ applications: db.deliveryApplications });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Approve/Reject Delivery Application
app.post('/api/admin/delivery-applications/:id', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }
    
    const { id } = req.params;
    const { status, message } = req.body;
    
    const application = db.deliveryApplications.find(a => a.id == id);
    if (!application) {
      return res.status(404).json({ error: 'Application not found' });
    }
    
    application.status = status;
    application.updatedAt = new Date().toISOString();
    
    // Send notification to applicant
    db.notifications.push({
      id: generateId(),
      type: 'application_update',
      title: status === 'approved' ? 'Application Approved!' : 'Application Rejected',
      message: message || (status === 'approved' ? 'Your application has been approved!' : 'Your application has been rejected'),
      data: application,
      createdAt: new Date().toISOString(),
      read: false,
    });
    
    res.json({ success: true });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// ============ ADMIN DASHBOARD STATS ============
app.get('/api/admin/stats', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }
    
    const totalOrders = db.orders.length;
    const totalRevenue = db.orders.reduce((sum, o) => sum + o.total, 0);
    const totalProducts = db.products.length;
    const totalUsers = db.users.length;
    const totalDrivers = db.deliveryApplications.filter(a => a.status === 'approved').length;
    const pendingOrders = db.orders.filter(o => o.status === 'pending').length;
    const deliveredOrders = db.orders.filter(o => o.status === 'delivered').length;
    
    // Daily stats for chart
    const today = new Date().toISOString().split('T')[0];
    const dailySales = db.orders
      .filter(o => o.createdAt.startsWith(today))
      .reduce((sum, o) => sum + o.total, 0);
    
    // Orders by day (last 7 days)
    const ordersByDay = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];
      const dayOrders = db.orders.filter(o => o.createdAt.startsWith(dateStr));
      ordersByDay.push({
        date: dateStr,
        orders: dayOrders.length,
        revenue: dayOrders.reduce((sum, o) => sum + o.total, 0),
      });
    }
    
    res.json({
      totalOrders,
      totalRevenue,
      totalProducts,
      totalUsers,
      totalDrivers,
      pendingOrders,
      deliveredOrders,
      dailySales,
      ordersByDay,
    });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Get All Orders (Admin)
app.get('/api/admin/orders', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }
    res.json({ orders: db.orders });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Get All Users (Admin)
app.get('/api/admin/users', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Admin only' });
    }
    res.json({ users: db.users.map(u => ({ id: u.id, email: u.email, name: u.name, phone: u.phone, role: u.role, status: u.status })) });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// ============ NOTIFICATIONS ============
app.get('/api/notifications', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const userNotifications = db.notifications.filter(n => n.data?.id === decoded.id);
    res.json({ notifications: userNotifications.reverse() });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

app.post('/api/notifications/:id/read', (req, res) => {
  const { id } = req.params;
  const notification = db.notifications.find(n => n.id == id);
  if (notification) {
    notification.read = true;
  }
  res.json({ success: true });
});

// ============ DELIVERY ORDERS ============
app.get('/api/delivery/orders', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.role !== 'delivery') {
      return res.status(403).json({ error: 'Delivery only' });
    }
    
    const deliveryOrders = db.orders.filter(o => o.status === 'accepted' || o.status === 'picked_up');
    res.json({ orders: deliveryOrders });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

app.post('/api/delivery/accept', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { orderId } = req.body;
    
    const order = db.orders.find(o => o.id === orderId);
    if (order) {
      order.status = 'accepted';
      order.driverId = decoded.id;
      order.acceptedAt = new Date().toISOString();
    }
    
    res.json({ success: true });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

app.put('/api/delivery/orders/:id/status', (req, res) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const { id } = req.params;
    const { status } = req.body;
    
    const order = db.orders.find(o => o.id == id);
    if (order) {
      order.status = status;
      order.updatedAt = new Date().toISOString();
      
      // If delivered, update driver stats
      if (status === 'delivered') {
        const application = db.deliveryApplications.find(a => a.phone === decoded.phone);
        if (application) {
          application.deliveries = (application.deliveries || 0) + 1;
        }
      }
    }
    
    res.json({ success: true });
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

// ============ START SERVER ============
app.listen(PORT, () => {
  console.log(`OmniMarket Server running on port ${PORT}`);
  console.log(`API: http://localhost:${PORT}/api`);
});