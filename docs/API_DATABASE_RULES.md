# TayyebGo API & Database Rules

## Database Schema (Firestore)

### Collections

#### users
```
users/{userId}
  - id: string
  - email: string
  - phone: string
  - name: string
  - role: "customer" | "driver" | "partner" | "admin"
  - avatar: string (URL)
  - addresses: array
  - createdAt: timestamp
  - updatedAt: timestamp
  - isActive: boolean
```

#### orders
```
orders/{orderId}
  - id: string
  - customerId: reference (users)
  - driverId: reference (users)
  - partnerId: reference (partners)
  - items: array
  - status: string
  - subtotal: number
  - deliveryFee: number
  - commission: number
  - total: number
  - paymentMethod: string
  - paymentStatus: string
  - deliveryAddress: object
  - pickupAddress: object
  - createdAt: timestamp
  - updatedAt: timestamp
  - estimatedDelivery: timestamp
  - actualDelivery: timestamp
```

#### partners
```
partners/{partnerId}
  - id: string
  - name: string
  - category: string
  - address: object
  - phone: string
  - email: string
  - rating: number
  - totalOrders: number
  - isOpen: boolean
  - menu: array
  - operatingHours: object
  - createdAt: timestamp
  - updatedAt: timestamp
```

#### drivers
```
drivers/{driverId}
  - id: reference (users)
  - status: "online" | "offline" | "busy"
  - vehicleType: string
  - vehiclePlate: string
  - currentLocation: geopoint
  - rating: number
  - totalDeliveries: number
  - totalEarnings: number
  - documents: object
  - createdAt: timestamp
  - updatedAt: timestamp
```

#### transactions
```
transactions/{transactionId}
  - id: string
  - userId: reference (users)
  - orderId: reference (orders)
  - type: "payment" | "payout" | "refund" | "topup"
  - amount: number
  - method: string
  - status: string
  - createdAt: timestamp
```

---

## Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Orders: customer, driver, partner can read; customer can create
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.customerId == request.auth.uid ||
         resource.data.driverId == request.auth.uid ||
         resource.data.partnerId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Partners: public read, owner write
    match /partners/{partnerId} {
      allow read: if true;
      allow write: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }
    
    // Drivers: authenticated read/write
    match /drivers/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == driverId;
    }
  }
}
```

### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images: user can write own, public read
    match /profiles/{userId}/{allPaths} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // Partner images: partner owner can write, public read
    match /partners/{partnerId}/{allPaths} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Driver documents: owner can write, admin read
    match /drivers/{driverId}/{allPaths} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == driverId;
    }
  }
}
```

---

## API Endpoints (Cloud Functions)

### Orders
- `POST /orders` — Create order
- `GET /orders/:id` — Get order details
- `PUT /orders/:id/status` — Update order status
- `GET /orders/customer/:customerId` — Customer order history
- `GET /orders/driver/:driverId` — Driver active/completed orders
- `GET /orders/partner/:partnerId` — Partner order list

### Payments
- `POST /payments/process` — Process payment
- `POST /payments/refund` — Refund order
- `GET /payments/history/:userId` — Payment history

### Drivers
- `PUT /drivers/:id/location` — Update location
- `PUT /drivers/:id/status` — Update online/offline
- `POST /drivers/:id/accept` — Accept order
- `POST /drivers/:id/complete` — Complete delivery

### Partners
- `GET /partners/:id/menu` — Get menu
- `PUT /partners/:id/menu` — Update menu
- `GET /partners/:id/analytics` — Get analytics
- `PUT /partners/:id/status` — Open/close store

### Notifications
- `POST /notifications/send` — Send push notification
- `POST /notifications/batch` — Send batch notifications

---

## Data Validation

### Order Validation
```javascript
{
  customerId: { required: true, type: 'string' },
  partnerId: { required: true, type: 'string' },
  items: { 
    required: true, 
    type: 'array',
    minItems: 1,
    item: {
      productId: { required: true },
      quantity: { required: true, min: 1 },
      price: { required: true, min: 0 }
    }
  },
  deliveryAddress: {
    required: true,
    lat: { required: true },
    lng: { required: true },
    address: { required: true }
  },
  paymentMethod: { 
    required: true, 
    enum: ['cash', 'shamcash', 'card'] 
  }
}
```

### Partner Validation
```javascript
{
  name: { required: true, minLength: 2, maxLength: 100 },
  category: { required: true, enum: ['food', 'grocery', 'pharmacy', 'other'] },
  phone: { required: true, pattern: /^\+?[0-9]{10,15}$/ },
  address: { required: true },
  operatingHours: { required: true }
}
```

---

## Performance Rules

### Indexing
- Composite indexes on: status + createdAt, customerId + status
- Single field indexes on: all query fields
- Geopoint index for location queries

### Caching
- Public data (partners, menu): 5 min cache
- User data: No cache (real-time)
- Order data: 30 sec cache
- Analytics: 1 hr cache

### Rate Limiting
- API calls: 100 per minute per user
- Order creation: 3 per hour per user
- Payment attempts: 5 per hour per user

---

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "ORDER_NOT_FOUND",
    "message": "Order not found",
    "details": {}
  }
}
```

### Error Codes
| Code | Description |
|------|-------------|
| AUTH_REQUIRED | Authentication required |
| INVALID_INPUT | Invalid request data |
| ORDER_NOT_FOUND | Order does not exist |
| ORDER_CANCELLED | Order already cancelled |
| PAYMENT_FAILED | Payment processing failed |
| DRIVER_UNAVAILABLE | No drivers available |
| PARTNER_CLOSED | Partner is currently closed |
| RATE_LIMITED | Too many requests |

---

## Monitoring

### Metrics to Track
- Order completion rate
- Average delivery time
- Payment success rate
- API response times
- Error rates
- User retention

### Alerts
- Delivery time > 45 min
- Payment failure rate > 5%
- API error rate > 1%
- Active driver count < threshold
- Partner downtime > 30 min
