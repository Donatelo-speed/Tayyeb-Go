---
name: Tayyeb Go Utility
colors:
  surface: '#f7faf5'
  surface-dim: '#d8dbd6'
  surface-bright: '#f7faf5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4ef'
  surface-container: '#ecefea'
  surface-container-high: '#e6e9e4'
  surface-container-highest: '#e0e3de'
  on-surface: '#191c1a'
  on-surface-variant: '#424656'
  inverse-surface: '#2d312e'
  inverse-on-surface: '#eff2ec'
  outline: '#727687'
  outline-variant: '#c2c6d8'
  surface-tint: '#0054d6'
  primary: '#0050cb'
  on-primary: '#ffffff'
  primary-container: '#0066ff'
  on-primary-container: '#f8f7ff'
  inverse-primary: '#b3c5ff'
  secondary: '#ab3500'
  on-secondary: '#ffffff'
  secondary-container: '#fe6a34'
  on-secondary-container: '#5d1900'
  tertiary: '#515c55'
  on-tertiary: '#ffffff'
  tertiary-container: '#69746d'
  on-tertiary-container: '#effaf2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae1ff'
  primary-fixed-dim: '#b3c5ff'
  on-primary-fixed: '#001849'
  on-primary-fixed-variant: '#003fa4'
  secondary-fixed: '#ffdbd0'
  secondary-fixed-dim: '#ffb59d'
  on-secondary-fixed: '#390c00'
  on-secondary-fixed-variant: '#832600'
  tertiary-fixed: '#dae5dd'
  tertiary-fixed-dim: '#bec9c1'
  on-tertiary-fixed: '#141e19'
  on-tertiary-fixed-variant: '#3f4943'
  background: '#f7faf5'
  on-background: '#191c1a'
  surface-variant: '#e0e3de'
  status-active: '#0066FF'
  status-pending: '#FFB800'
  status-completed: '#22C55E'
  status-error: '#EF4444'
  surface-dark: '#141E19'
  surface-light: '#FFFFFF'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 32px
  gutter: 16px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for a high-velocity delivery ecosystem, balancing the logistical precision of a business dashboard with the rapid accessibility required for users on the move. The brand personality is dependable, energetic, and efficient.

The visual style follows a **Corporate / Modern** aesthetic with subtle **Minimalist** influences. It prioritizes clarity and functional hierarchy to reduce cognitive load during time-sensitive tasks. The interface utilizes high-contrast interactive elements, purposeful whitespace to separate data-heavy modules, and a refined tonal palette to distinguish between system feedback and user content. The goal is to evoke a sense of reliability and seamless orchestration.

## Colors

The palette is anchored by a vibrant **Utility Blue** (derived from the brand's core identity), used for primary actions and "Active" state indicators. The **Secondary Orange** (#FF6B35) is reserved for high-visibility highlights, such as promotional banners or urgent notifications.

A deep **Onyx** (#141E19) provides the foundation for text and high-contrast UI elements, while the **Soft Gray** (#E6E9E4) serves as the primary background and border color to keep the interface feeling open and light. 

**Status Indicators:**
- **Active:** Primary Blue. Represents "In Transit" or "Currently Processing."
- **Pending:** Warm Amber. Represents "Waiting for Courier" or "Order Received."
- **Completed:** Emerald Green. Represents successful delivery or finalized transaction.

## Typography

Typography is optimized for legibility across varying light conditions and device types. 

**Hanken Grotesk** is used for headlines to provide a sharp, modern, and professional edge. **Inter** is the workhorse for all body copy and input fields, chosen for its exceptional readability in data-heavy environments. **JetBrains Mono** is utilized for functional labels, such as order IDs, timestamps, and tracking numbers, giving technical data a distinct visual signature that separates it from narrative text.

For mobile interfaces, headlines scale down to ensure information density remains high without sacrificing clarity. All uppercase styling should be reserved for `label-sm` to ensure hierarchy in metadata.

## Layout & Spacing

This design system employs a **Fluid Grid** model based on an 8px square baseline. 

- **Mobile:** 4-column grid with 16px side margins and 16px gutters.
- **Desktop/Dashboard:** 12-column grid with 32px side margins. Content modules should be grouped into logical "cards" that span defined column counts (e.g., 3-column stats widgets, 9-column map view).

Vertical rhythm is maintained using "stack" tokens. Use `stack-sm` for internal component spacing (e.g., label to input), `stack-md` for content within a card, and `stack-lg` for spacing between distinct sections or modules.

## Elevation & Depth

Hierarchy is conveyed through **Tonal Layers** and **Ambient Shadows**.

1.  **Level 0 (Floor):** The main background uses `#E6E9E4`.
2.  **Level 1 (Cards/Sheets):** Pure white surfaces (`#FFFFFF`) with a 1px border of the neutral color. For mobile, use a very soft, diffused shadow (10% opacity, 4px blur) to lift cards off the background.
3.  **Level 2 (Popovers/Modals):** Pure white surfaces with a more pronounced shadow (15% opacity, 12px blur) to indicate immediate interaction priority.

**Map Interfaces:** Use semi-transparent "Glassmorphic" overlays (White @ 80% with backdrop-blur) for floating controls to ensure the map remains visible beneath navigation elements.

## Shapes

The shape language is **Rounded**, strike a balance between friendly consumer apps and rigid enterprise software. 

- **Standard Elements:** Buttons, input fields, and small cards use a 0.5rem (8px) radius.
- **Large Containers:** Dashboard modules and main content cards use a 1rem (16px) radius.
- **Status Pills:** Tags and indicators use a full pill-shape (circular ends) to distinguish them from interactive buttons.

## Components

### Buttons
- **Primary:** Solid Primary Blue with white text. 0.5rem radius.
- **Secondary:** Outline Primary Blue with 1px border.
- **Urgent:** Solid Secondary Orange for "Cancel" or "Report Issue" actions.

### Status Indicators
- **Chips:** Small, pill-shaped badges using a light tint of the status color for the background (15% opacity) and the full-saturation status color for the text and a 1px border.

### Map Interface
- **Floating Action Buttons (FAB):** Circular, white background, high elevation.
- **Route Lines:** Solid Primary Blue with a subtle outer glow for clarity against complex map textures.

### Input Fields
- **Default:** White background, 1px neutral border. Focus state uses a 2px Primary Blue border.
- **Search:** Includes a leading icon and a "Clear" trailing button.

### Business Dashboards
- **Stat Cards:** Large `headline-md` value with a `label-sm` title above it. 
- **Data Tables:** High-density rows with 1px horizontal dividers. Use `jetbrainsMono` for numeric data to ensure tabular alignment.

### Checkboxes & Radio Buttons
- Use the Primary Blue for active states. Checkboxes should have a 4px corner radius; radio buttons remain perfectly circular.