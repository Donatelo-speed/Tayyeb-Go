# AI Agent Deployment Guide: Tayyeb Go Ecosystem

## Project Overview
Tayyeb Go is a multi-platform delivery ecosystem. This project contains 4 distinct applications and a marketing landing page. All screens are responsive (Tailwind-based) and include entrance animations.

## Application Structure & Routing

### 1. Customer App (Consumer-Facing)
- **Home:** `{{DATA:SCREEN:SCREEN_152}}` (Vibrant entry point)
- **Menu:** `{{DATA:SCREEN:SCREEN_6}}` (Store inventory)
- **Checkout:** `{{DATA:SCREEN:SCREEN_10}}` (Payment & delivery details)
- **Tracking:** `{{DATA:SCREEN:SCREEN_37}}` (Live status)
- **History:** `{{DATA:SCREEN:SCREEN_20}}` (Past orders)
- **Profile:** `{{DATA:SCREEN:SCREEN_24}}` (User settings)

### 2. Partner App (Merchant Tools)
- **Owner Dashboard:** `{{DATA:SCREEN:SCREEN_149}}` (Revenue & goals)
- **Cashier Dashboard:** `{{DATA:SCREEN:SCREEN_35}}` (Active queue)
- **Menu Management:** `{{DATA:SCREEN:SCREEN_34}}` (Inventory control)
- **Live Orders:** `{{DATA:SCREEN:SCREEN_3}}` (Operational lifecycle)

### 3. Driver App (Logistics Workforce)
- **Available Jobs:** `{{DATA:SCREEN:SCREEN_147}}` (Map & discovery)
- **Active Delivery:** `{{DATA:SCREEN:SCREEN_5}}` (Navigation & status)
- **Earnings:** `{{DATA:SCREEN:SCREEN_23}}` (Payout tracking)

### 4. Admin App (System Oversight)
- **Command Center:** `{{DATA:SCREEN:SCREEN_127}}` (Fleet metrics & alerts)
- **User Directory:** `{{DATA:SCREEN:SCREEN_12}}` (Account management)
- **User Details:** `{{DATA:SCREEN:SCREEN_30}}` (Admin actions)
- **Fleet Monitor:** `{{DATA:SCREEN:SCREEN_17}}` (Live tracking)
- **System Logs:** `{{DATA:SCREEN:SCREEN_29}}` (Technical monitoring)

### 5. Marketing
- **Landing Page:** `{{DATA:SCREEN:SCREEN_19}}` (Onboarding stakeholders)

## Technical Implementation Notes
- **Design System:** Uses `{{DATA:DESIGN_SYSTEM:DESIGN_SYSTEM_1}}` (Inter font, #ff5a2c accent).
- **Responsive:** All screens use Tailwind breakpoints (`sm`, `md`, `lg`, `xl`).
- **Animations:** Standardized `animate-fade-in-up` and `animate-pulse` classes are applied for smooth entrance.
- **Assets:** User icons and logos are linked via `{{DATA:IMAGE:IMAGE_7}}`.