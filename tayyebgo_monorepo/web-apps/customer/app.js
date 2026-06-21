// TayyebGo Customer Web App - Main Entry Point
import { authService } from './shared/auth.js';
import { router } from './shared/router.js';
import { themeManager } from './shared/theme.js';

// ========================================
// Toast Notifications
// ========================================
function showToast(message, type = 'success') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => toast.remove(), 4000);
}

// ========================================
// Page Renderers
// ========================================

// Login Page
function renderLogin() {
  return `
    <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;background:var(--bg)">
      <div class="card" style="width:100%;max-width:420px">
        <div style="text-align:center;margin-bottom:32px">
          <div style="width:48px;height:48px;background:linear-gradient(135deg,var(--primary),var(--accent));border-radius:14px;display:flex;align-items:center;justify-content:center;margin:0 auto 16px">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v10l9 5 9-5V7l-9-5z" fill="white" opacity="0.9"/></svg>
          </div>
          <h1 style="font-family:var(--font-display);font-size:24px;font-weight:800">Welcome back</h1>
          <p style="color:var(--text-secondary);font-size:14px;margin-top:4px">Sign in to TayyebGo</p>
        </div>

        <form id="loginForm">
          <div class="input-group">
            <label>Email</label>
            <input type="email" id="loginEmail" placeholder="you@example.com" required>
          </div>
          <div class="input-group">
            <label>Password</label>
            <input type="password" id="loginPassword" placeholder="••••••••" required>
          </div>
          <div style="text-align:right;margin-bottom:20px">
            <a href="#" onclick="navigate('/forgot-password');return false" style="font-size:13px;color:var(--primary)">Forgot password?</a>
          </div>
          <button type="submit" class="btn btn-primary btn-full btn-lg">Sign In</button>
        </form>

        <div style="text-align:center;margin:20px 0;color:var(--text-tertiary);font-size:13px">or continue with</div>

        <div style="display:flex;gap:10px">
          <button onclick="loginWithGoogle()" class="btn btn-outline" style="flex:1">
            <svg width="18" height="18" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
            Google
          </button>
          <button onclick="loginWithApple()" class="btn btn-outline" style="flex:1">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
            Apple
          </button>
        </div>

        <div style="text-align:center;margin-top:24px;font-size:14px;color:var(--text-secondary)">
          Don't have an account? <a href="/signup" style="color:var(--primary);font-weight:600">Sign up</a>
        </div>
      </div>
    </div>
  `;
}

// Signup Page
function renderSignup() {
  return `
    <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;background:var(--bg)">
      <div class="card" style="width:100%;max-width:420px">
        <div style="text-align:center;margin-bottom:32px">
          <div style="width:48px;height:48px;background:linear-gradient(135deg,var(--primary),var(--accent));border-radius:14px;display:flex;align-items:center;justify-content:center;margin:0 auto 16px">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v10l9 5 9-5V7l-9-5z" fill="white" opacity="0.9"/></svg>
          </div>
          <h1 style="font-family:var(--font-display);font-size:24px;font-weight:800">Create account</h1>
          <p style="color:var(--text-secondary);font-size:14px;margin-top:4px">Join TayyebGo today</p>
        </div>

        <form id="signupForm">
          <div class="input-group">
            <label>Full Name</label>
            <input type="text" id="signupName" placeholder="John Doe" required>
          </div>
          <div class="input-group">
            <label>Email</label>
            <input type="email" id="signupEmail" placeholder="you@example.com" required>
          </div>
          <div class="input-group">
            <label>Phone Number</label>
            <input type="tel" id="signupPhone" placeholder="+963 9XX XXX XXX">
          </div>
          <div class="input-group">
            <label>Password</label>
            <input type="password" id="signupPassword" placeholder="••••••••" required minlength="6">
          </div>
          <button type="submit" class="btn btn-primary btn-full btn-lg" style="margin-top:8px">Create Account</button>
        </form>

        <div style="text-align:center;margin-top:24px;font-size:14px;color:var(--text-secondary)">
          Already have an account? <a href="/login" style="color:var(--primary);font-weight:600">Sign in</a>
        </div>
      </div>
    </div>
  `;
}

// Forgot Password Page
function renderForgotPassword() {
  return `
    <div style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;background:var(--bg)">
      <div class="card" style="width:100%;max-width:420px">
        <div style="text-align:center;margin-bottom:32px">
          <h1 style="font-family:var(--font-display);font-size:24px;font-weight:800">Reset password</h1>
          <p style="color:var(--text-secondary);font-size:14px;margin-top:4px">Enter your email and we'll send you a reset link</p>
        </div>
        <form id="forgotForm">
          <div class="input-group">
            <label>Email</label>
            <input type="email" id="forgotEmail" placeholder="you@example.com" required>
          </div>
          <button type="submit" class="btn btn-primary btn-full btn-lg">Send Reset Link</button>
        </form>
        <div style="text-align:center;margin-top:24px;font-size:14px;color:var(--text-secondary)">
          <a href="/login" style="color:var(--primary);font-weight:600">← Back to Sign In</a>
        </div>
      </div>
    </div>
  `;
}

// Home Page
function renderHome() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:32px">
          <div>
            <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800">Good evening 👋</h1>
            <p style="color:var(--text-secondary);font-size:14px">What would you like to order?</p>
          </div>
          <div style="display:flex;gap:10px">
            <button onclick="toggleTheme()" class="btn btn-ghost btn-sm" style="width:40px;height:40px;padding:0">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>
            </button>
            <button onclick="toggleLanguage()" class="btn btn-ghost btn-sm" style="font-size:12px;font-weight:600;width:auto;padding:0 12px">AR</button>
          </div>
        </div>

        <!-- Search -->
        <div style="position:relative;margin-bottom:24px">
          <svg style="position:absolute;left:16px;top:50%;transform:translateY(-50%);color:var(--text-tertiary)" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <input type="text" placeholder="Search restaurants or food..." style="width:100%;padding:14px 16px 14px 44px;border:1.5px solid var(--border);border-radius:var(--radius);font-size:14px;background:var(--surface);color:var(--text)">
        </div>

        <!-- Categories -->
        <div style="display:flex;gap:10px;margin-bottom:32px;overflow-x:auto;padding-bottom:8px">
          <button class="btn btn-primary btn-sm">🍔 Food</button>
          <button class="btn btn-outline btn-sm">🛒 Grocery</button>
          <button class="btn btn-outline btn-sm">💊 Pharmacy</button>
          <button class="btn btn-outline btn-sm">🛍️ Retail</button>
          <button class="btn btn-outline btn-sm">🌸 Specialty</button>
          <button class="btn btn-outline btn-sm">📦 Anything</button>
        </div>

        <!-- Restaurant Grid -->
        <h2 style="font-size:18px;font-weight:700;margin-bottom:16px">Nearby Restaurants</h2>
        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px">
          ${renderRestaurantCard('Pizza House', '🍕', '25-35 min', '4.8', 'Italian')}
          ${renderRestaurantCard('Burger King', '🍔', '15-25 min', '4.6', 'American')}
          ${renderRestaurantCard('Sushi Master', '🍣', '30-40 min', '4.7', 'Japanese')}
          ${renderRestaurantCard('Al-Shifa Pharmacy', '💊', '20-30 min', '4.9', 'Pharmacy')}
          ${renderRestaurantCard('Fresh Market', '🛒', '15-20 min', '4.5', 'Grocery')}
          ${renderRestaurantCard('Sweet Dreams', '🧁', '20-30 min', '4.8', 'Desserts')}
        </div>
      </main>
    </div>
  `;
}

// Restaurant Menu Page
function renderRestaurantMenu(params) {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <button onclick="navigate('/')" class="btn btn-ghost btn-sm" style="margin-bottom:20px">← Back</button>

        <div style="display:flex;gap:24px;margin-bottom:32px">
          <div style="width:120px;height:120px;border-radius:var(--radius-lg);background:linear-gradient(135deg,var(--primary),var(--accent));display:flex;align-items:center;justify-content:center;font-size:48px">🍕</div>
          <div>
            <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800">Pizza House</h1>
            <p style="color:var(--text-secondary);font-size:14px">Italian • 25-35 min • ⭐ 4.8</p>
            <div style="display:flex;gap:8px;margin-top:8px">
              <span class="badge badge-success">Open</span>
              <span class="badge badge-primary">Free delivery over 50,000 SYP</span>
            </div>
          </div>
        </div>

        <!-- Menu Categories -->
        <div style="display:flex;gap:10px;margin-bottom:24px;overflow-x:auto">
          <button class="btn btn-primary btn-sm">All</button>
          <button class="btn btn-outline btn-sm">Pizza</button>
          <button class="btn btn-outline btn-sm">Pasta</button>
          <button class="btn btn-outline btn-sm">Salads</button>
          <button class="btn btn-outline btn-sm">Drinks</button>
        </div>

        <!-- Menu Items -->
        <div style="display:flex;flex-direction:column;gap:12px">
          ${renderMenuItem('Margherita Pizza', 'Classic tomato sauce, mozzarella, basil', '12,000 SYP', '🍕')}
          ${renderMenuItem('Pepperoni Pizza', 'Pepperoni, mozzarella, tomato sauce', '15,000 SYP', '🍕')}
          ${renderMenuItem('Caesar Salad', 'Romaine, croutons, parmesan, caesar dressing', '8,000 SYP', '🥗')}
          ${renderMenuItem('Pasta Carbonara', 'Spaghetti, egg, pancetta, parmesan', '14,000 SYP', '🍝')}
          ${renderMenuItem('Garlic Bread', 'Toasted bread with garlic butter', '5,000 SYP', '🍞')}
          ${renderMenuItem('Cola', 'Cold refreshing cola', '2,000 SYP', '🥤')}
        </div>
      </main>
    </div>
  `;
}

// Cart Page
function renderCart() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Your Cart</h1>

        <div style="display:grid;grid-template-columns:1fr 360px;gap:32px">
          <!-- Cart Items -->
          <div>
            <div class="cart-item">
              <div class="cart-item-img">🍕</div>
              <div class="cart-item-info">
                <div class="cart-item-title">Margherita Pizza</div>
                <div class="cart-item-price">12,000 SYP</div>
              </div>
              <div class="quantity-control">
                <button class="quantity-btn">−</button>
                <span style="font-weight:600">1</span>
                <button class="quantity-btn">+</button>
              </div>
            </div>
            <div class="cart-item">
              <div class="cart-item-img">🍕</div>
              <div class="cart-item-info">
                <div class="cart-item-title">Pepperoni Pizza</div>
                <div class="cart-item-price">15,000 SYP</div>
              </div>
              <div class="quantity-control">
                <button class="quantity-btn">−</button>
                <span style="font-weight:600">2</span>
                <button class="quantity-btn">+</button>
              </div>
            </div>
          </div>

          <!-- Order Summary -->
          <div class="card">
            <h3 style="font-size:16px;font-weight:700;margin-bottom:20px">Order Summary</h3>
            <div style="display:flex;justify-content:space-between;margin-bottom:12px;font-size:14px">
              <span style="color:var(--text-secondary)">Subtotal</span>
              <span style="font-weight:600">42,000 SYP</span>
            </div>
            <div style="display:flex;justify-content:space-between;margin-bottom:12px;font-size:14px">
              <span style="color:var(--text-secondary)">Delivery Fee</span>
              <span style="font-weight:600">3,000 SYP</span>
            </div>
            <div style="display:flex;justify-content:space-between;margin-bottom:12px;font-size:14px">
              <span style="color:var(--text-secondary)">Discount</span>
              <span style="font-weight:600;color:var(--success)">-2,100 SYP</span>
            </div>
            <div style="border-top:1px solid var(--border);padding-top:12px;margin-bottom:20px;display:flex;justify-content:space-between">
              <span style="font-weight:700">Total</span>
              <span style="font-weight:800;font-size:18px;color:var(--primary)">42,900 SYP</span>
            </div>
            <button onclick="navigate('/checkout')" class="btn btn-primary btn-full btn-lg">Proceed to Checkout</button>
          </div>
        </div>
      </main>
    </div>
  `;
}

// Checkout Page
function renderCheckout() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <button onclick="navigate('/cart')" class="btn btn-ghost btn-sm" style="margin-bottom:20px">← Back to Cart</button>
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Checkout</h1>

        <div style="display:grid;grid-template-columns:1fr 360px;gap:32px">
          <div>
            <!-- Delivery Address -->
            <div class="card" style="margin-bottom:20px">
              <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">📍 Delivery Address</h3>
              <div style="padding:16px;border:2px solid var(--primary);border-radius:var(--radius);background:rgba(255,90,44,0.05)">
                <div style="font-weight:600">Home</div>
                <div style="font-size:13px;color:var(--text-secondary)">Mezzeh, Damascus, Syria</div>
              </div>
              <button class="btn btn-outline btn-sm" style="margin-top:12px">+ Add new address</button>
            </div>

            <!-- Payment Method -->
            <div class="card" style="margin-bottom:20px">
              <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">💳 Payment Method</h3>
              <div style="display:flex;flex-direction:column;gap:10px">
                <label style="display:flex;align-items:center;gap:12px;padding:14px;border:2px solid var(--primary);border-radius:var(--radius);cursor:pointer;background:rgba(255,90,44,0.05)">
                  <input type="radio" name="payment" checked style="accent-color:var(--primary)">
                  <span>💵 Cash on Delivery</span>
                </label>
                <label style="display:flex;align-items:center;gap:12px;padding:14px;border:1.5px solid var(--border);border-radius:var(--radius);cursor:pointer">
                  <input type="radio" name="payment" style="accent-color:var(--primary)">
                  <span>💰 Wallet Balance: 25,000 SYP</span>
                </label>
                <label style="display:flex;align-items:center;gap:12px;padding:14px;border:1.5px solid var(--border);border-radius:var(--radius);cursor:pointer">
                  <input type="radio" name="payment" style="accent-color:var(--primary)">
                  <span>📱 Sham Cash</span>
                </label>
                <label style="display:flex;align-items:center;gap:12px;padding:14px;border:1.5px solid var(--border);border-radius:var(--radius);cursor:pointer;opacity:0.5">
                  <input type="radio" name="payment" disabled style="accent-color:var(--primary)">
                  <span>💳 Visa/Mastercard <span class="badge badge-warning" style="margin-left:8px">Coming Soon</span></span>
                </label>
              </div>
            </div>

            <!-- Schedule -->
            <div class="card">
              <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">⏰ Schedule Order</h3>
              <label style="display:flex;align-items:center;gap:12px;cursor:pointer">
                <input type="checkbox" style="accent-color:var(--primary)">
                <span style="font-size:14px">Schedule for later</span>
              </label>
            </div>
          </div>

          <!-- Order Summary -->
          <div class="card" style="height:fit-content">
            <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">Order Summary</h3>
            <div style="font-size:14px;color:var(--text-secondary);margin-bottom:20px">
              <div style="margin-bottom:8px">1x Margherita Pizza</div>
              <div>2x Pepperoni Pizza</div>
            </div>
            <div style="border-top:1px solid var(--border);padding-top:12px;margin-bottom:20px">
              <div style="display:flex;justify-content:space-between;font-weight:800;font-size:18px">
                <span>Total</span>
                <span style="color:var(--primary)">42,900 SYP</span>
              </div>
            </div>
            <button onclick="placeOrder()" class="btn btn-primary btn-full btn-lg">Place Order</button>
          </div>
        </div>
      </main>
    </div>
  `;
}

// Order Tracking Page
function renderOrderTracking() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Order Tracking</h1>

        <div style="display:grid;grid-template-columns:1fr 360px;gap:32px">
          <!-- Map -->
          <div class="card" style="height:400px;display:flex;align-items:center;justify-content:center;background:linear-gradient(135deg,rgba(255,90,44,0.1),rgba(139,92,246,0.1))">
            <div style="text-align:center">
              <div style="font-size:48px;margin-bottom:12px">🗺️</div>
              <p style="color:var(--text-secondary)">Live map will appear here</p>
            </div>
          </div>

          <!-- Order Details -->
          <div>
            <div class="card" style="margin-bottom:20px">
              <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px">
                <div style="width:48px;height:48px;border-radius:50%;background:linear-gradient(135deg,var(--primary),var(--accent));display:flex;align-items:center;justify-content:center;color:white;font-weight:700">A</div>
                <div>
                  <div style="font-weight:600">Ahmed K.</div>
                  <div style="font-size:13px;color:var(--text-secondary)">Your driver • ⭐ 4.9</div>
                </div>
              </div>
              <div style="display:flex;gap:10px">
                <button class="btn btn-outline btn-sm" style="flex:1">📞 Call</button>
                <button class="btn btn-primary btn-sm" style="flex:1">💬 Chat</button>
              </div>
            </div>

            <div class="card">
              <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">Order Status</h3>
              <div style="display:flex;flex-direction:column;gap:16px">
                <div style="display:flex;gap:12px">
                  <div style="width:24px;height:24px;border-radius:50%;background:var(--success);display:flex;align-items:center;justify-content:center;color:white;font-size:12px">✓</div>
                  <div>
                    <div style="font-weight:600;font-size:14px">Order Confirmed</div>
                    <div style="font-size:12px;color:var(--text-secondary)">2 min ago</div>
                  </div>
                </div>
                <div style="display:flex;gap:12px">
                  <div style="width:24px;height:24px;border-radius:50%;background:var(--success);display:flex;align-items:center;justify-content:center;color:white;font-size:12px">✓</div>
                  <div>
                    <div style="font-weight:600;font-size:14px">Preparing</div>
                    <div style="font-size:12px;color:var(--text-secondary)">5 min ago</div>
                  </div>
                </div>
                <div style="display:flex;gap:12px">
                  <div style="width:24px;height:24px;border-radius:50%;background:var(--primary);display:flex;align-items:center;justify-content:center;color:white;font-size:12px">●</div>
                  <div>
                    <div style="font-weight:600;font-size:14px;color:var(--primary)">On the way</div>
                    <div style="font-size:12px;color:var(--text-secondary)">1.2 km away</div>
                  </div>
                </div>
                <div style="display:flex;gap:12px">
                  <div style="width:24px;height:24px;border-radius:50%;background:var(--border);display:flex;align-items:center;justify-content:center;color:var(--text-tertiary);font-size:12px">4</div>
                  <div>
                    <div style="font-weight:600;font-size:14px;color:var(--text-tertiary)">Delivered</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  `;
}

// Order History Page
function renderOrderHistory() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Order History</h1>
        <div style="display:flex;flex-direction:column;gap:16px">
          ${renderOrderCard('#4521', 'Pizza House', '42,900 SYP', 'delivered', '2 hours ago')}
          ${renderOrderCard('#4520', 'Burger King', '18,500 SYP', 'delivered', 'Yesterday')}
          ${renderOrderCard('#4519', 'Al-Shifa Pharmacy', '12,000 SYP', 'delivered', '2 days ago')}
        </div>
      </main>
    </div>
  `;
}

// Profile Page
function renderProfile() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Profile</h1>
        <div class="card" style="max-width:600px">
          <div style="display:flex;align-items:center;gap:16px;margin-bottom:24px">
            <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,var(--primary),var(--accent));display:flex;align-items:center;justify-content:center;color:white;font-size:28px;font-weight:700">J</div>
            <div>
              <div style="font-size:20px;font-weight:700">John Doe</div>
              <div style="color:var(--text-secondary);font-size:14px">john@example.com</div>
            </div>
          </div>
          <div class="input-group">
            <label>Full Name</label>
            <input type="text" value="John Doe">
          </div>
          <div class="input-group">
            <label>Email</label>
            <input type="email" value="john@example.com">
          </div>
          <div class="input-group">
            <label>Phone</label>
            <input type="tel" value="+963 912 345 678">
          </div>
          <button class="btn btn-primary">Save Changes</button>
        </div>
      </main>
    </div>
  `;
}

// Wallet Page
function renderWallet() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Wallet</h1>
        <div class="card" style="background:linear-gradient(135deg,var(--primary),var(--accent));color:white;margin-bottom:24px">
          <div style="font-size:14px;opacity:0.8;margin-bottom:8px">Available Balance</div>
          <div style="font-size:40px;font-weight:800">25,000 SYP</div>
          <button class="btn btn-white" style="margin-top:16px">Top Up</button>
        </div>
        <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">Recent Transactions</h3>
        <div style="display:flex;flex-direction:column;gap:12px">
          <div style="display:flex;justify-content:space-between;padding:16px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius)">
            <div>
              <div style="font-weight:600">Top Up</div>
              <div style="font-size:13px;color:var(--text-secondary)">Yesterday</div>
            </div>
            <div style="font-weight:700;color:var(--success)">+30,000 SYP</div>
          </div>
          <div style="display:flex;justify-content:space-between;padding:16px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius)">
            <div>
              <div style="font-weight:600">Order #4520</div>
              <div style="font-size:13px;color:var(--text-secondary)">2 days ago</div>
            </div>
            <div style="font-weight:700;color:var(--error)">-5,000 SYP</div>
          </div>
        </div>
      </main>
    </div>
  `;
}

// Subscription Page
function renderSubscription() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Subscription</h1>
        <div class="card" style="max-width:500px;text-align:center;padding:40px">
          <div style="font-size:48px;margin-bottom:16px">⭐</div>
          <h2 style="font-size:24px;font-weight:800;margin-bottom:8px">TayyebGo Plus</h2>
          <div style="font-size:40px;font-weight:800;color:var(--primary);margin:16px 0">4,999 <span style="font-size:16px;font-weight:500;color:var(--text-secondary)">SYP/mo</span></div>
          <ul style="text-align:left;margin:24px 0;list-style:none">
            <li style="padding:8px 0;border-bottom:1px solid var(--border)">✓ Free delivery on all orders</li>
            <li style="padding:8px 0;border-bottom:1px solid var(--border)">✓ 3-15% discount on orders</li>
            <li style="padding:8px 0;border-bottom:1px solid var(--border)">✓ Priority support</li>
            <li style="padding:8px 0">✓ Exclusive deals</li>
          </ul>
          <button class="btn btn-primary btn-full btn-lg">Subscribe Now</button>
          <p style="font-size:12px;color:var(--text-secondary);margin-top:12px">Pay with Sham Cash. Admin will verify and activate.</p>
        </div>
      </main>
    </div>
  `;
}

// Loyalty Page
function renderLoyalty() {
  return `
    <div class="app-layout">
      ${renderSidebar()}
      <main class="main-content">
        <h1 style="font-family:var(--font-display);font-size:28px;font-weight:800;margin-bottom:24px">Points & Rewards</h1>
        <div class="card" style="text-align:center;margin-bottom:24px">
          <div style="font-size:14px;color:var(--text-secondary)">Your Points</div>
          <div style="font-size:48px;font-weight:800;color:var(--primary)">1,250</div>
          <div style="font-size:14px;color:var(--text-secondary)">Bronze Tier • 750 points to Silver</div>
          <div style="height:8px;background:var(--border);border-radius:4px;margin-top:12px;overflow:hidden">
            <div style="width:60%;height:100%;background:linear-gradient(90deg,var(--primary),var(--accent));border-radius:4px"></div>
          </div>
        </div>
        <h3 style="font-size:16px;font-weight:700;margin-bottom:16px">Redeem Points</h3>
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:16px">
          <div class="card" style="text-align:center;cursor:pointer">
            <div style="font-size:32px;margin-bottom:8px">🎁</div>
            <div style="font-weight:600">500 Points</div>
            <div style="font-size:13px;color:var(--text-secondary)">5,000 SYP Discount</div>
          </div>
          <div class="card" style="text-align:center;cursor:pointer">
            <div style="font-size:32px;margin-bottom:8px">🚀</div>
            <div style="font-weight:600">300 Points</div>
            <div style="font-size:13px;color:var(--text-secondary)">Free Delivery</div>
          </div>
        </div>
      </main>
    </div>
  `;
}

// ========================================
// Helper Renderers
// ========================================

function renderSidebar() {
  return `
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="logo" style="display:flex;align-items:center;gap:10px">
          <div style="width:36px;height:36px;background:linear-gradient(135deg,var(--primary),var(--accent));border-radius:10px;display:flex;align-items:center;justify-content:center">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7v10l9 5 9-5V7l-9-5z" fill="white" opacity="0.9"/></svg>
          </div>
          <span style="font-weight:800;font-size:18px">TayyebGo</span>
        </div>
      </div>
      <nav class="sidebar-nav">
        <a href="/" class="nav-item active">🏠 Home</a>
        <a href="/orders" class="nav-item">📦 Orders</a>
        <a href="/wallet" class="nav-item">💰 Wallet</a>
        <a href="/loyalty" class="nav-item">⭐ Points</a>
        <a href="/subscription" class="nav-item">🎫 Subscription</a>
        <a href="/anything" class="nav-item">📦 Anything</a>
        <a href="/profile" class="nav-item">👤 Profile</a>
        <a href="/settings" class="nav-item">⚙️ Settings</a>
        <a href="/help" class="nav-item">❓ Help</a>
      </nav>
      <div class="sidebar-footer">
        <button onclick="logout()" class="btn btn-ghost btn-full" style="color:var(--error)">🚪 Sign Out</button>
      </div>
    </aside>
  `;
}

function renderRestaurantCard(name, emoji, time, rating, category) {
  return `
    <div class="restaurant-card" onclick="navigate('/restaurant/1')">
      <div class="restaurant-card-img">${emoji}</div>
      <div class="restaurant-card-body">
        <div class="restaurant-card-title">${name}</div>
        <div class="restaurant-card-meta">
          <span>${category}</span>
          <span>•</span>
          <span>${time}</span>
          <span>•</span>
          <span>⭐ ${rating}</span>
        </div>
      </div>
    </div>
  `;
}

function renderMenuItem(name, desc, price, emoji) {
  return `
    <div class="menu-item" onclick="addToCart('${name}', '${price}')">
      <div class="menu-item-img">${emoji}</div>
      <div class="menu-item-info">
        <div class="menu-item-title">${name}</div>
        <div class="menu-item-desc">${desc}</div>
        <div class="menu-item-price">${price}</div>
      </div>
    </div>
  `;
}

function renderOrderCard(id, restaurant, total, status, time) {
  return `
    <div class="card" style="cursor:pointer" onclick="navigate('/tracking/1')">
      <div style="display:flex;justify-content:space-between;align-items:start">
        <div>
          <div style="font-weight:700">${restaurant}</div>
          <div style="font-size:13px;color:var(--text-secondary)">${id} • ${time}</div>
        </div>
        <span class="order-status status-${status}">${status}</span>
      </div>
      <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center">
        <span style="font-weight:700;color:var(--primary)">${total}</span>
        <button class="btn btn-outline btn-sm">Reorder</button>
      </div>
    </div>
  `;
}

// ========================================
// Global Functions
// ========================================

window.navigate = (path) => router.navigate(path);
window.toggleTheme = () => themeManager.toggleTheme();
window.toggleLanguage = () => themeManager.toggleLanguage();
window.showToast = showToast;

window.loginWithGoogle = async () => {
  const result = await authService.loginWithGoogle();
  if (result.success) {
    showToast('Signed in with Google!');
    navigate('/');
  } else {
    showToast(result.error, 'error');
  }
};

window.loginWithApple = async () => {
  const result = await authService.loginWithApple();
  if (result.success) {
    showToast('Signed in with Apple!');
    navigate('/');
  } else {
    showToast(result.error, 'error');
  }
};

window.logout = async () => {
  await authService.logout();
  showToast('Signed out');
  navigate('/login');
};

window.placeOrder = () => {
  showToast('Order placed successfully!');
  navigate('/tracking/1');
};

window.addToCart = (name, price) => {
  showToast(`${name} added to cart!`);
};

// ========================================
// Initialize App
// ========================================

function initApp() {
  // Remove loading screen
  setTimeout(() => {
    const loading = document.getElementById('loadingScreen');
    if (loading) loading.remove();
  }, 500);

  // Setup routes
  router
    .route('/login', () => { document.getElementById('app').innerHTML = renderLogin(); })
    .route('/signup', () => { document.getElementById('app').innerHTML = renderSignup(); })
    .route('/forgot-password', () => { document.getElementById('app').innerHTML = renderForgotPassword(); })
    .route('/', () => { document.getElementById('app').innerHTML = renderHome(); })
    .route('/restaurant/:id', () => { document.getElementById('app').innerHTML = renderRestaurantMenu(); })
    .route('/cart', () => { document.getElementById('app').innerHTML = renderCart(); })
    .route('/checkout', () => { document.getElementById('app').innerHTML = renderCheckout(); })
    .route('/tracking/:id', () => { document.getElementById('app').innerHTML = renderOrderTracking(); })
    .route('/orders', () => { document.getElementById('app').innerHTML = renderOrderHistory(); })
    .route('/profile', () => { document.getElementById('app').innerHTML = renderProfile(); })
    .route('/wallet', () => { document.getElementById('app').innerHTML = renderWallet(); })
    .route('/subscription', () => { document.getElementById('app').innerHTML = renderSubscription(); })
    .route('/loyalty', () => { document.getElementById('app').innerHTML = renderLoyalty(); });

  // Auth guard
  router.guard(async (to, from) => {
    const publicRoutes = ['/login', '/signup', '/forgot-password'];
    if (!publicRoutes.includes(to) && !authService.currentUser) {
      navigate('/login');
      return false;
    }
    if (publicRoutes.includes(to) && authService.currentUser) {
      navigate('/');
      return false;
    }
    return true;
  });

  // Start router
  router.init();

  // Listen for auth changes
  authService.onAuthChange((user) => {
    if (user && window.location.pathname === '/login') {
      navigate('/');
    }
  });
}

// Form handlers
document.addEventListener('submit', async (e) => {
  e.preventDefault();

  if (e.target.id === 'loginForm') {
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const result = await authService.loginWithEmail(email, password);
    if (result.success) {
      showToast('Signed in successfully!');
      navigate('/');
    } else {
      showToast(result.error, 'error');
    }
  }

  if (e.target.id === 'signupForm') {
    const name = document.getElementById('signupName').value;
    const email = document.getElementById('signupEmail').value;
    const password = document.getElementById('signupPassword').value;
    const result = await authService.signupWithEmail(email, password, name);
    if (result.success) {
      showToast('Account created!');
      navigate('/');
    } else {
      showToast(result.error, 'error');
    }
  }

  if (e.target.id === 'forgotForm') {
    const email = document.getElementById('forgotEmail').value;
    const result = await authService.resetPassword(email);
    if (result.success) {
      showToast('Reset link sent! Check your email.');
    } else {
      showToast(result.error, 'error');
    }
  }
});

// Initialize
initApp();
