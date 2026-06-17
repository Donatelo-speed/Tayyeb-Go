---
name: TayyebGo
colors:
  surface: '#f9f9ff'
  surface-dim: '#d7d9e6'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#ebedfa'
  surface-container-high: '#e5e8f5'
  surface-container-highest: '#dfe2ef'
  on-surface: '#181c25'
  on-surface-variant: '#5b403a'
  inverse-surface: '#2c303a'
  inverse-on-surface: '#eef0fd'
  outline: '#8f7068'
  outline-variant: '#e4beb5'
  surface-tint: '#b22c00'
  primary: '#b22c00'
  on-primary: '#ffffff'
  primary-container: '#ff5a2c'
  on-primary-container: '#571100'
  inverse-primary: '#ffb5a1'
  secondary: '#006c45'
  on-secondary: '#ffffff'
  secondary-container: '#70fcb7'
  on-secondary-container: '#00734a'
  tertiary: '#825500'
  on-tertiary: '#ffffff'
  tertiary-container: '#c88400'
  on-tertiary-container: '#3e2600'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd1'
  primary-fixed-dim: '#ffb5a1'
  on-primary-fixed: '#3b0800'
  on-primary-fixed-variant: '#881f00'
  secondary-fixed: '#70fcb7'
  secondary-fixed-dim: '#50df9d'
  on-secondary-fixed: '#002112'
  on-secondary-fixed-variant: '#005233'
  tertiary-fixed: '#ffddb4'
  tertiary-fixed-dim: '#ffb953'
  on-tertiary-fixed: '#291800'
  on-tertiary-fixed-variant: '#633f00'
  background: '#f9f9ff'
  on-background: '#181c25'
  surface-variant: '#dfe2ef'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 42px
    fontWeight: '700'
    lineHeight: 44.5px
    letterSpacing: -0.02em
  display-md:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 37.4px
    letterSpacing: -0.01em
  stat-value:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 33.6px
  title-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28.3px
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 23px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24.8px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 21px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16.8px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18.9px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 15.6px
  price:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 19.2px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  max-width-desktop: 1200px
---

## Brand & Style

The design system is built on a narrative of **freshness, reliability, and modern efficiency**. It creates a "food-forward" atmosphere that balances the organic warmth of a marketplace with the high-performance precision of a logistics platform. The brand identifies its diverse user roles (Consumer, Driver, Partner, Admin) through specific color accents while maintaining a unified structural language.

The visual style is **Corporate / Modern** with a lean toward **Minimalism**, characterized by:
- **Warm Organics:** A parchment-cream light mode that feels wholesome rather than sterile.
- **High-Contrast Utility:** Deep slate dark modes designed for operational clarity in varying light conditions.
- **Subtle Depth:** A reliance on soft, color-tuned shadows and "glow-enhanced" boundaries rather than heavy black shadows.
- **Role-Based Signaling:** Immediate context recognition through consistent use of dedicated accent colors for different apps.

## Colors

The palette is organized into role-specific accents and a tiered neutral foundation. 

### Core Palette
- **Primary (Customer):** A vibrant orange used for core brand CTAs and shopping paths.
- **Secondary (Driver):** An emerald green signaling movement and delivery success.
- **Tertiary (Partner):** An amber tone representing merchants and store management.
- **Neutral:** High-readability slates that transition from deep charcoal in light mode to off-white in dark mode.

### Operational Accents
- **Route Tracking:** Reserved teal-cyan solely for navigation and transit vectors.
- **Admin:** A royal blue used for technical pipelines and data-heavy dashboards.
- **Status Tones:** Standardized success, warning, and error colors that include "glow" profiles—soft, alpha-tuned drop shadows that match the state color to provide clear visual feedback without clutter.

## Typography

The design system exclusively uses **Inter** to ensure maximum legibility and character spacing in data-dense operational environments.

- **Display & Headlines:** Large titles use tight line-heights and negative letter-spacing to create a compact, authoritative look for marketing and splash screens.
- **Data & Stats:** "Stat Value" and "Price" roles use heavy weights (800 and 700) to ensure that numerical figures—critical for drivers and merchants—are the most prominent elements in the hierarchy.
- **Body & Captions:** Standard copy uses relaxed line-heights (1.4x to 1.55x) to support rapid scanning of multi-line addresses and receipt details.
- **Accessibility:** Avoid using gray text lighter than `#737F90` on light backgrounds to ensure WCAG compliance.

## Layout & Spacing

The layout is governed by a strict **8-point structural rhythm** ensuring consistency across mobile and web platforms.

- **Grid Strategy:**
    - **Desktop:** A fixed-grid approach for landing pages with a maximum width of 1200px and 24px side margins.
    - **Mobile:** Fluid 1-column layouts where touch targets expand to full-width.
- **Responsive Breakpoints:**
    - **Mobile (< 640px):** Single column lists, 16px horizontal padding.
    - **Tablet (640px - 1280px):** 2-column grid transitions.
    - **Desktop (>= 1280px):** Persistent sidebars (280px width) and 3-4 column content grids.
- **Whitespace:** Use `md` (16px) as the default padding for cards and vertical list gaps. Use `xxs` (4px) or `xs` (8px) for micro-relationships, such as between a label and its corresponding input or price.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Ambient Shadows** that vary by mode:

- **Surface Tiers:** In light mode, use a warm cream background (`#F7F4EF`) with pure white elevated surfaces. In dark mode, the canvas is slate-black (`#090B10`) with slate-gray surfaces (`#121722`).
- **Soft Elevation:** Elevated cards use high-blur, low-opacity shadows (`16px` blur, `8%` opacity in light, `20%` in dark).
- **Glassmorphism:** Reserved for specific high-end contexts (like web navbars) using 20px backdrop blurs and semi-transparent surface fills (70% opacity) with 1px semi-transparent borders.
- **Glow Profiling:** Interactive elements like focused inputs or primary buttons project a tinted glow based on their role color (e.g., a 12px primary orange blur) rather than a neutral gray shadow.

## Shapes

The design system utilizes a "Soft-Rounded" language to balance friendliness with a structured, professional feel.

- **Standard Elements:** Buttons and cards use a consistent **8px (md)** radius.
- **Small Elements:** Form inputs and small chips use a tighter **6px (sm)** radius to maintain visual density.
- **Avatars & Badges:** Use **999px (full)** for circular avatars and status pills.
- **Containers:** Large section containers or feature cards on web may scale up to **12px or 16px** to emphasize their boundaries.

## Components

### Buttons
- **Primary:** 52px height, orange-to-amber horizontal gradient, with a primary glow shadow. 
- **Secondary:** 52px height, light peach fill (`#FFEFE8`) with orange text.
- **Interactive State:** All buttons must trigger a 120ms elastic scale-down to `0.97` on press.

### Inputs & Forms
- **Field Style:** Solid `surface-alt` background with a 1px border. 
- **Focus State:** 1.5px brand orange border and a soft glowing orange shadow.
- **Accessibility:** Minimum touch target of 48px for all input triggers.

### Cards
- **KPI Cards:** Feature a 36px icon container with a 10% opacity tint of the role color, a 32px stat value, and a trend indicator.
- **Interactive Cards:** Subtle elevation shadow that increases on hover.

### Feedback & Status
- **Badges:** Pill-shaped with soft fill (10% opacity) and dark text of the same hue (e.g., Emerald text on Light Green background for "Success").
- **Order Timeline:** Uber-style vertical progress path. Completed steps are solid orange circles; active steps are orange rings with a glow.