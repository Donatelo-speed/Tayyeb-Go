# TayyebGo Design System

## Overview

The TayyebGo design system (`tayyebgo_core/lib/presentation/`) provides a unified visual language across all 4 apps (Customer, Driver, Partner, Admin). It enforces consistency through tokens, components, and animation primitives.

**Import:**
```dart
import 'package:tayyebgo_core/tayyebgo_core.dart';
```

All symbols are exported from a single barrel file. No individual imports needed.

---

## 1. Color System

### Theme-Aware Colors (Context Extensions)

Always use `context.*Color` for layout colors — never `AppColors.*` directly for backgrounds, surfaces, or text.

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| `context.backgroundColor` | `#F7F4EF` (warm off-white) | `#090B10` (near-black) | Page backgrounds |
| `context.surfaceColor` | `#FFFFFF` (white) | `#121722` (dark gray) | Cards, sheets, modals |
| `context.textPrimaryColor` | `#151922` (near-black) | `#F7F9FC` (white) | Headings, body text |
| `context.textMutedColor` | `#93A0AF` (gray) | `#6B7686` (muted) | Captions, labels, hints |
| `context.dividerColor` | `#E8EDF2` (light gray) | `#1E2635` (dark) | Horizontal dividers |
| `context.borderColor` | `#DCE3EA` (border) | `#273043` (border) | Input borders, outlines |

### Brand Colors (Theme-Invariant)

These remain the same in both light and dark mode:

| Token | Value | Usage |
|---|---|---|
| `AppColors.primary` | `#1A73E8` | Primary actions, links, active states |
| `AppColors.primaryLight` | `#E8F0FE` | Primary backgrounds, badges |
| `AppColors.primaryDark` | `#1557B0` | Primary hover/pressed states |
| `AppColors.error` | `#EA4335` | Errors, destructive actions |
| `AppColors.errorLight` | `#FDECEE` | Error backgrounds |
| `AppColors.success` | `#34A853` | Success states, confirmations |
| `AppColors.successLight` | `#E6F4EA` | Success backgrounds |
| `AppColors.warning` | `#FBBC04` | Warnings, caution states |
| `AppColors.warningLight` | `#FEF7E0` | Warning backgrounds |
| `AppColors.premium` | `#FFD700` | Premium features, gold tier |

### Gradient System

```dart
AppGradients.primary    // Primary brand gradient
AppGradients.premium    // Gold/premium gradient
AppGradients.dark       // Dark mode overlay
AppGradients.surface    // Subtle surface gradient
```

---

## 2. Typography Scale

### Headings

| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `AppTypography.displayLarge` | 32px | Bold | 40px | Hero headings, splash |
| `AppTypography.titleLarge` | 22px | Bold | 28px | Screen titles |
| `AppTypography.titleMedium` | 18px | SemiBold | 24px | Section headers |
| `AppTypography.titleSmall` | 16px | SemiBold | 22px | Card titles, list headers |

### Body

| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `AppTypography.bodyLarge` | 16px | Regular | 24px | Primary body text |
| `AppTypography.bodyMedium` | 14px | Regular | 20px | Default body text |
| `AppTypography.bodySmall` | 12px | Regular | 16px | Secondary body text |

### Labels

| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `AppTypography.labelLarge` | 14px | SemiBold | 20px | Button labels, tabs |
| `AppTypography.labelMedium` | 12px | SemiBold | 16px | Chips, small buttons |
| `AppTypography.caption` | 11px | Regular | 14px | Captions, timestamps |

### Special

| Token | Size | Weight | Usage |
|---|---|---|---|
| `AppTypography.price` | 20px | Bold | Order totals, prices |
| `AppTypography.statValue` | 28px | Bold | KPI values, counters |

---

## 3. Spacing Scale (8pt Grid)

All spacing values are multiples of 4px, aligned to an 8pt baseline grid:

| Token | Value | Usage |
|---|---|---|
| `AppSpacing.xxs` | 4px | Tight gaps (icon-text) |
| `AppSpacing.xs` | 8px | Small gaps, inline spacing |
| `AppSpacing.sm` | 12px | Compact lists, chip padding |
| `AppSpacing.md` | 16px | Default padding, card insets |
| `AppSpacing.lg` | 20px | Section spacing |
| `AppSpacing.xl` | 24px | Screen-level padding |
| `AppSpacing.xxl` | 32px | Major section breaks |
| `AppSpacing.xxxl` | 48px | Hero spacing, large gaps |

**Rule:** Never use hardcoded spacing values. Always use `AppSpacing.*` tokens.

---

## 4. Border Radius

### Scale

| Token | Value | Usage |
|---|---|---|
| `AppRadius.xs` | 4px | Subtle rounding (badges) |
| `AppRadius.sm` | 8px | Small elements (chips) |
| `AppRadius.md` | 12px | Medium elements (inputs, buttons) |
| `AppRadius.lg` | 16px | Large elements (cards) |
| `AppRadius.xl` | 20px | Very large (dialogs, sheets) |
| `AppRadius.xxl` | 24px | Extra large containers |
| `AppRadius.full` | 999px | Pill shapes, avatars |

### Semantic Aliases

| Alias | Value | Maps To |
|---|---|---|
| `AppRadius.brCard` | 16px | Card containers |
| `AppRadius.brButton` | 12px | Button corners |
| `AppRadius.brInput` | 12px | Text field corners |
| `AppRadius.brChip` | 20px | Chip/tag corners |
| `AppRadius.brAvatar` | 999px | Circular avatars |
| `AppRadius.brDialog` | 20px | Dialog/modal corners |
| `AppRadius.brBottomSheet` | 20px | Bottom sheet corners |
| `AppRadius.brBadge` | 999px | Badge pill shape |

---

## 5. Shadow System

| Token | Elevation | Usage |
|---|---|---|
| `AppShadow.sm` | 1dp | Subtle lift (chips, small cards) |
| `AppShadow.md` | 4dp | Default card shadow |
| `AppShadow.lg` | 8dp | Elevated cards, floating elements |
| `AppShadow.xl` | 16dp | Dialogs, modals |

All shadows adapt to light/dark mode automatically.

---

## 6. Component Library

### Buttons (`TGB`)

```dart
// Primary button (most common)
TGB.primary(label: 'Order Now', onPressed: () {})

// Secondary button
TGB.secondary(label: 'Cancel', onPressed: () {})

// Ghost/text button
TGB.ghost(label: 'Skip', onPressed: () {})

// Destructive button (red)
TGB.destructive(label: 'Delete Account', onPressed: () {})

// Icon-only button
TGB.icon(icon: Icons.add, onPressed: () {})

// Social login button
TGB.social(
  label: 'Continue with Google',
  socialIcon: GoogleLogo(),
  onPressed: () {},
)

// Disabled state
TGB.primary(label: 'Submit', onPressed: null)  // auto-disables
```

**Rules:**
- Use `TGB` for ALL buttons — never raw `ElevatedButton`, `OutlinedButton`, `TextButton`
- Primary = main action per screen (one per view)
- Secondary = cancel/alternative actions
- Ghost = tertiary actions, skip flows
- Destructive = delete, remove, ban

---

### Cards (`TGC`)

```dart
// Default surface card
TGC(child: Text('Content'))

// Elevated card with shadow
TGC(variant: TGCVariant.elevated, child: Text('Featured'))

// Outlined card with border
TGC(variant: TGCVariant.outlined, child: Text('Selectable'))

// Gradient background card
TGCGradient(child: Text('Premium'))

// KPI/stat card
TGCKpi(
  icon: Icons.revenue,
  value: '$1,200',
  label: 'Revenue',
)
```

**Rules:**
- Use `TGC` for ALL cards — never raw `Container` with `BoxDecoration`
- Use `TGCKpi` for dashboard statistics
- Use `TGCGradient` for premium/featured content

---

### Badges (`TGBadge`)

```dart
TGBadge.active()          // Green "Active"
TGBadge.inactive()        // Gray "Inactive"
TGBadge.pending()         // Yellow "Pending"
TGBadge.error()           // Red "Error"
TGBadge.count(count: 5)   // Notification count
TGBadge.role(label: 'Admin')    // Role badge
TGBadge.category(label: 'Food') // Category badge

// Online indicator dot
TGDot(pulse: true)  // Animated green dot
```

---

### Avatar (`TGAvatar`)

```dart
TGAvatar(
  size: TGAvatarSize.lg,     // lg, md, sm
  imageUrl: url,
  name: 'John',              // Fallback initials
  showOnlineDot: true,       // Green dot indicator
)
```

Handles: image loading, error fallback, initials generation, online status.

---

### Text Field (`TGF`)

```dart
TGF(
  label: 'Email',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
)
```

Wraps `TextFormField` with consistent styling, validation, and theming.

---

### Chips (`TGChip`)

```dart
TGChip.filter(label: 'Food', selected: true, onTap: () {})
TGChip.action(label: 'Add to cart', icon: Icons.add, onTap: () {})
TGChip.input(label: 'Chicken', onDelete: () {})
TGCategoryChip(label: 'Pizza', icon: Icons.local_pizza, selected: false, onTap: () {})
```

---

### Switch (`TGSwitch`)

```dart
TGSwitch(
  value: isOnline,
  onChanged: (v) => setState(() => isOnline = v),
)

// With label
TGSwitch(
  value: enabled,
  label: 'Notifications',
  subtitle: 'Receive push alerts',
  onChanged: (v) {},
)
```

---

### Progress Indicators

```dart
// Circular spinner
TGCircularProgress()
TGCircularProgress(size: 48, label: 'Uploading...')

// Linear progress bar
TGLinearProgress(value: 0.7, label: 'Upload', valueLabel: '70%')
```

---

### Search Bar (`TGSearchBar`)

```dart
TGSearchBar(
  hintText: 'What do you need?',
  onChanged: (q) => _search(q),
)
```

---

### Rating (`TGRating`, `TGRatingBar`)

```dart
// Display rating
TGRating(rating: 4.5, showValue: true, label: '(120)')

// Interactive rating input
TGRatingBar(rating: rating, onRatingChanged: (r) => _rate(r))
```

---

### Banner (`TGBanner`)

```dart
TGBanner.info(message: 'New feature available')
TGBanner.success(message: 'Order placed!')
TGBanner.warning(message: 'Low balance')
TGBanner.error(message: 'Payment failed', onDismiss: () {})
```

---

### Dialog (`TGDialog`)

```dart
TGDialog.show(
  context: context,
  title: 'Confirm',
  content: 'Are you sure you want to delete this item?',
  primaryLabel: 'Yes',
  primaryOnPressed: () => Navigator.pop(context),
  secondaryLabel: 'Cancel',
  secondaryOnPressed: () => Navigator.pop(context),
)
```

---

### Bottom Sheet (`TGBottomSheet`, `TGConfirmSheet`)

```dart
// Standard bottom sheet
TGBottomSheet.show(
  context: context,
  title: 'Options',
  child: Column(children: [...]),
)

// Confirmation sheet
TGConfirmSheet.show(
  context: context,
  title: 'Delete order?',
  confirmLabel: 'Delete',
  onConfirm: () => _delete(),
)
```

---

### Empty State (`TGEmptyState`)

```dart
TGEmptyState(
  icon: Icons.shopping_cart_outlined,
  title: 'Your cart is empty',
  description: 'Add items to get started',
  actionLabel: 'Browse Stores',
  onAction: () {},
)
```

Use for: empty order history, no results, empty cart, no notifications.

---

### Error Widget (`TGErrorWidget`)

```dart
TGErrorWidget(
  title: 'Something went wrong',
  message: 'Please try again',
  onRetry: () => _reload(),
)
```

Includes shake animation for visual feedback.

---

### Loader (`AppLoader`)

```dart
AppLoader()                          // Centered spinner
AppLoader(message: 'Loading...')     // Spinner with text
```

---

### Skeleton Loading (`TGS`)

```dart
TGS.text()                           // Single line placeholder
TGS.textMulti(lines: 3)              // Multi-line placeholder
TGS.avatar()                         // Circle placeholder
TGS.card()                           // Rectangle placeholder
TGS.image()                          // Image placeholder
TGSGroup(count: 3, builder: (_) => TGS.card())  // Group of skeletons
```

**Rule:** Use `TGS` for ALL loading states — never plain `Container` placeholders.

---

### Utility Components

```dart
TGDivider()                          // Horizontal divider line
TGSpacer.heightLg                    // 20px vertical space (use .xs, .sm, .md, .lg, .xl, .xxl)
TGText('Hello')                      // Themed text widget
TGContainer(child: ...)              // Surface-colored container
```

---

## 7. Animation System

### Page Transitions

```dart
HeroSlideRoute(page: NextScreen())   // Slide from right
HeroFadeRoute(page: NextScreen())    // Crossfade
HeroScaleRoute(page: NextScreen())   // Scale in
```

### Widget Animations

| Animation | Usage |
|---|---|
| `AnimatedFadeSlide(child: ...)` | Fade + slide in (list items, cards) |
| `AnimatedStagger(children: [...])` | Staggered list appearance |
| `AnimatedScaleIn(child: ...)` | Scale pop-in (notifications, badges) |
| `AnimatedPulse(child: ...)` | Pulsing opacity (loading states) |
| `ShimmerWrapper(isLoading: true, child: ...)` | Shimmer loading effect |
| `TGPressScale(onTap: () {}, child: ...)` | Press feedback (buttons, cards) |
| `PulseAnimation(child: ...)` | Breathing pulse (online dots) |
| `AnimatedCounter(value: 42)` | Number counting animation (KPIs) |

### Usage Rules

- Use `AnimatedFadeSlide` for list items entering the viewport
- Use `TGPressScale` for all tappable elements that need tactile feedback
- Use `ShimmerWrapper` instead of `TGS` when you have existing content to shimmer
- Use `AnimatedCounter` for dashboard statistics that change

---

## 8. Dark/Light Mode

### Theme Provider

```dart
// Toggle between light and dark
context.read<ThemeProvider>().toggle();

// Check current mode
context.isDark  // bool

// Set specific mode
ThemeProvider().setMode(ThemeMode.system)

// Set to dark only
ThemeProvider().setMode(ThemeMode.dark)
```

### Implementation

- Theme is managed via `ThemeProvider` (ChangeNotifier)
- Persisted to SharedPreferences
- All `context.*Color` extensions auto-resolve based on current theme
- Brand colors (`AppColors.*`) remain constant across themes
- Component library (`TGB`, `TGC`, etc.) auto-adapts to theme

### Dark Mode Color Mapping

| Element | Light | Dark |
|---|---|---|
| Background | `#F7F4EF` | `#090B10` |
| Surface | `#FFFFFF` | `#121722` |
| Primary text | `#151922` | `#F7F9FC` |
| Muted text | `#93A0AF` | `#6B7686` |
| Divider | `#E8EDF2` | `#1E2635` |
| Border | `#DCE3EA` | `#273043` |

---

## 9. Design Rules

1. **Always use `context.*Color`** for backgrounds, surfaces, text — never `AppColors.*`
2. **Use `AppColors.*`** only for brand colors (primary, error, success, warning, premium)
3. **Use `TGB`** for all buttons — no custom ElevatedButton/OutlinedButton/TextButton
4. **Use `TGC`** for all cards — no custom Container with BoxDecoration
5. **Use `TGAvatar`** for all user images — handles fallback, online dot, roles
6. **Use `TGEmptyState`** for empty screens — consistent icon + message + action
7. **Use `TGErrorWidget`** for error states — shake animation + retry
8. **Use `TGS`** for loading skeletons — never plain Container placeholders
9. **Use `AppSpacing`** for margins/padding — no magic numbers
10. **Use `AppRadius`** for border radius — no hardcoded values
11. **Use `TGPressScale`** for all tappable elements
12. **Use `AnimatedFadeSlide`** for list item entry animations
13. **One primary button per screen** — secondary actions use secondary/ghost style
14. **Dark mode is required** — test every screen in both themes before shipping
15. **RTL support** — layout must work in both LTR and RTL directions

---

## 10. File Locations

| Module | Path |
|---|---|
| Colors | `packages/tayyebgo_core/lib/presentation/theme/app_colors.dart` |
| Gradients | `packages/tayyebgo_core/lib/presentation/theme/app_gradients.dart` |
| Typography | `packages/tayyebgo_core/lib/presentation/theme/app_typography.dart` |
| Spacing | `packages/tayyebgo_core/lib/presentation/theme/app_spacing.dart` |
| Theme Provider | `packages/tayyebgo_core/lib/presentation/theme/theme_provider.dart` |
| Buttons | `packages/tayyebgo_core/lib/ui/tg_button.dart` |
| Cards | `packages/tayyebgo_core/lib/ui/tg_card.dart` |
| Badges | `packages/tayyebgo_core/lib/ui/tg_badge.dart` |
| Avatar | `packages/tayyebgo_core/lib/ui/tg_avatar.dart` |
| Text Field | `packages/tayyebgo_core/lib/ui/tg_text_field.dart` |
| Chips | `packages/tayyebgo_core/lib/ui/tg_chip.dart` |
| Animations | `packages/tayyebgo_core/lib/presentation/shared_widgets/` |
| Router | `packages/tayyebgo_core/lib/presentation/router/` |
