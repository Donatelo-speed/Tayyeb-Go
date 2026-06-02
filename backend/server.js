const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.get('/api/test', (req, res) => {
  res.json({ message: 'API working!' });
});

app.get('/api/admin/dashboard', (req, res) => {
  res.json({
    totalRestaurants: 45,
    activeUsers: 1234,
    totalOrders: 5678,
    revenue: '$45K',
    drivers: 89,
    pendingOrders: 12,
    recentActivity: [
      { icon: 'store', text: 'New restaurant "Al Mandi House" registered', time: '2 min ago', color: 'blue' },
      { icon: 'person', text: 'New user registered: john@email.com', time: '15 min ago', color: 'green' },
      { icon: 'shopping_cart', text: 'New order #1234 placed', time: '30 min ago', color: 'orange' },
      { icon: 'delivery', text: 'Driver "Khaled" completed delivery', time: '1 hour ago', color: 'cyan' },
      { icon: 'money', text: 'Payment received: $45.00', time: '2 hours ago', color: 'purple' },
    ]
  });
});

app.get('/api/driver/:id', (req, res) => {
  res.json({
    driverId: 'DRV-1234',
    name: 'Ahmed Hassan',
    rating: '4.9',
    isOnline: true,
    todayDeliveries: 12,
    todayEarnings: '$85',
    onlineTime: '4.5h',
    activeDeliveries: [
      { orderId: '#ORD-4521', address: 'Al-Mansour, Street 12', customer: 'Mohammad', amount: '$8.50', distance: '2.3 km', status: 'Picked Up' },
      { orderId: '#ORD-4522', address: 'Al-Mazza, Building 5', customer: 'Sara', amount: '$12.00', distance: '1.8 km', status: 'En Route' },
    ]
  });
});

app.patch('/api/driver/:id', (req, res) => {
  res.json({ success: true, isOnline: req.body.isOnline });
});

app.get('/api/vendor/:id/dashboard', (req, res) => {
  res.json({
    vendorId: parseInt(req.params.id),
    vendorName: 'Al Mandi House',
    todayOrders: 23,
    todayRevenue: '$340',
    rating: '4.8',
    recentOrders: [
      { customer: 'Ahmed K.', items: '2x Shawarma, 1x Fries', total: '$12.50', status: 'Preparing', time: '5 min ago' },
      { customer: 'Sarah M.', items: '1x Burger, 1x Coke', total: '$8.00', status: 'Ready', time: '12 min ago' },
      { customer: 'Omar R.', items: '3x Pizza', total: '$15.00', status: 'Delivered', time: '25 min ago' },
    ]
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});