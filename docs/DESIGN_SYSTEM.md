# TayyebGo Design System

## Overview

A unified design system shared across all TayyebGo products — apps, website, and admin dashboard.

---

## Color Palette

### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| Primary | #FF5A2C | CTAs, brand highlights |
| Primary Dark | #E84A1E | Hover states |
| Primary Light | #FF7A52 | Secondary actions |

### Secondary Colors
| Name | Hex | Usage |
|------|-----|-------|
| Accent | #8B5CF6 | Gradients, badges |
| Accent Dark | #7C3AED | Hover states |

### Semantic Colors
| Name | Hex | Usage |
|------|-----|-------|
| Success | #22C55E | Positive actions, ratings |
| Warning | #F59E0B | Alerts, stars |
| Error | #EF4444 | Errors, destructive actions |
| Info | #06B6D4 | Informational |

### Neutral Colors
| Name | Light | Dark | Usage |
|------|-------|------|-------|
| Background | #FAFBFA | #090B10 | Page background |
| Surface | #FFFFFF | #141C18 | Cards, modals |
| Text | #0A0F0D | #F0F5F2 | Primary text |
| Text Secondary | #5A6B63 | #8A9A92 | Secondary text |
| Border | #E5E9E7 | #2A3B33 | Dividers |

---

## Typography

### Font Families
- **Display**: Plus Jakarta Sans (headings, hero)
- **Body**: Inter (text, UI elements)

### Type Scale
| Name | Size | Weight | Line Height | Usage |
|------|------|--------|-------------|-------|
| Hero | clamp(52px, 7vw, 84px) | 800 | 1.02 | Hero title |
| H1 | clamp(32px, 5vw, 48px) | 800 | 1.1 | Section titles |
| H2 | clamp(32px, 4vw, 48px) | 800 | 1.1 | Split titles |
| H3 | 18px | 700 | 1.3 | Card titles |
| H4 | 16px | 700 | 1.4 | Small headings |
| Body | 16px | 400 | 1.6 | Paragraphs |
| Body Small | 15px | 400 | 1.7 | Feature lists |
| Caption | 14px | 500 | 1.5 | Labels, links |
| Small | 13px | 600 | 1.4 | Tags, badges |
| Tiny | 12px | 500 | 1.4 | Meta info |
| Micro | 10px | 500 | 1.4 | Status labels |

---

## Spacing

### 8pt Grid System
| Token | Value |
|-------|-------|
| space-1 | 4px |
| space-2 | 8px |
| space-3 | 12px |
| space-4 | 16px |
| space-5 | 20px |
| space-6 | 24px |
| space-8 | 32px |
| space-10 | 40px |
| space-12 | 48px |
| space-16 | 64px |
| space-20 | 80px |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| radius-sm | 8px | Small elements |
| radius | 12px | Cards, buttons |
| radius-lg | 20px | Large cards |
| radius-xl | 28px | Modals, phone mockups |
| radius-full | 100px | Badges, pills |

---

## Shadows

| Token | Value |
|-------|-------|
| shadow-xs | 0 1px 2px rgba(0,0,0,0.04) |
| shadow-sm | 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04) |
| shadow-md | 0 4px 16px rgba(0,0,0,0.08) |
| shadow-lg | 0 12px 40px rgba(0,0,0,0.1) |
| shadow-xl | 0 24px 64px rgba(0,0,0,0.12) |

---

## Glassmorphism

### Light Mode
```css
background: rgba(255,255,255,0.72);
backdrop-filter: blur(20px);
border: 1px solid rgba(255,255,255,0.25);
```

### Dark Mode
```css
background: rgba(20,28,24,0.72);
backdrop-filter: blur(20px);
border: 1px solid rgba(255,255,255,0.08);
```

---

## Animations

### Transition Tokens
| Token | Value | Usage |
|-------|-------|-------|
| transition-fast | 0.15s ease | Hover states |
| transition-base | 0.25s ease | Standard transitions |
| transition-smooth | 0.4s cubic-bezier(0.16, 1, 0.3, 1) | Page transitions |
| transition-spring | 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) | Bouncy effects |

### Key Animations
- **fadeInUp**: Content reveal on scroll
- **orbFloat**: Hero background orbs
- **phoneFloat**: Phone mockup floating
- **pulse**: Live indicator dots
- **scrollBounce**: Scroll indicator
- **ripple**: Button click effect
- **wave**: Hand wave emoji

---

## Components

### Buttons
- `.btn-primary` — Main CTA
- `.btn-outline` — Secondary action
- `.btn-ghost` — Tertiary action
- `.btn-glass` — Glassmorphism variant
- `.btn-white` — On dark backgrounds
- `.btn-glow` — Glowing effect

### Cards
- `.glass-card` — Base glassmorphism card
- `.feature-card` — Feature highlight
- `.testimonial-card` — Social proof
- `.pricing-card` — Pricing tiers
- `.blog-card` — Blog post preview

### Forms
- `.form-group` — Input wrapper
- `.form-row` — Side-by-side inputs
- Input states: default, focus, error

---

## Responsive Breakpoints

| Name | Max Width | Layout |
|------|-----------|--------|
| Mobile | 480px | Single column, stacked |
| Tablet | 768px | 2 columns, bottom nav |
| Desktop | 1024px | 2-3 columns, sidebar |
| Wide | 1200px+ | Full layout |

---

## Accessibility

- WCAG AA contrast ratios
- Skip navigation link
- Keyboard navigation support
- ARIA labels on interactive elements
- Reduced motion support
- Focus visible states
- Semantic HTML structure

---

## Dark Mode

- Toggle via theme button
- Persisted in localStorage
- Respects system preference
- All components support both modes
- Smooth transition between modes
