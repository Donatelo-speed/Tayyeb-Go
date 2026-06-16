# TayyebGo Design System

## Import

```dart
import 'package:tayyebgo_core/tayyebgo_core.dart';
```

Everything is exported from one barrel file. No need to import individual files.

---

## Colors (Theme-Aware)

Always use `context.*Color` extensions — never `AppColors.*` directly for layout colors.

| Light Mode | Dark Mode | Extension |
|-----------|-----------|-----------|
| `#F7F4EF` (warm off-white) | `#090B10` (near-black) | `context.backgroundColor` |
| `#FFFFFF` (white) | `#121722` (dark gray) | `context.surfaceColor` |
| `#151922` (near-black) | `#F7F9FC` (white) | `context.textPrimaryColor` |
| `#93A0AF` (gray) | `#6B7686` (muted) | `context.textMutedColor` |
| `#E8EDF2` (light gray) | `#1E2635` (dark) | `context.dividerColor` |
| `#DCE3EA` (border) | `#273043` (border) | `context.borderColor` |

**Brand colors** (same in both themes): `AppColors.primary`, `.error`, `.success`, `.warning`, `.premium`

---

## Typography

```dart
// Headings
AppTypography.displayLarge   // 32px bold
AppTypography.titleLarge     // 22px bold
AppTypography.titleMedium    // 18px semi-bold
AppTypography.titleSmall     // 16px semi-bold

// Body
AppTypography.bodyLarge      // 16px
AppTypography.bodyMedium     // 14px (default)
AppTypography.bodySmall      // 12px

// Labels
AppTypography.labelLarge     // 14px semi-bold
AppTypography.labelMedium    // 12px semi-bold
AppTypography.caption        // 11px

// Special
AppTypography.price          // 20px bold
AppTypography.statValue      // 28px bold
```

---

## Spacing (8-point grid)

```dart
AppSpacing.xxs   // 4
AppSpacing.xs    // 8
AppSpacing.sm    // 12
AppSpacing.md    // 16
AppSpacing.lg    // 20
AppSpacing.xl    // 24
AppSpacing.xxl   // 32
AppSpacing.xxxl  // 48
```

---

## Radius

```dart
AppRadius.xs     // 4
AppRadius.sm     // 8
AppRadius.md     // 12
AppRadius.lg     // 16
AppRadius.xl     // 20
AppRadius.xxl    // 24
AppRadius.full   // 999

// Semantic
AppRadius.brCard        // 16
AppRadius.brButton      // 12
AppRadius.brInput       // 12
AppRadius.brChip        // 20
AppRadius.brAvatar      // 999
AppRadius.brDialog      // 20
AppRadius.brBottomSheet // 20
AppRadius.brBadge       // 999
```

---

## Components

### Buttons (`TGB`)

```dart
TGB.primary(label: 'Order Now', onPressed: () {})
TGB.secondary(label: 'Cancel', onPressed: () {})
TGB.ghost(label: 'Skip', onPressed: () {})
TGB.destructive(label: 'Delete', onPressed: () {})
TGB.icon(icon: Icons.add, onPressed: () {})
TGB.social(label: 'Continue with Google', socialIcon: GoogleLogo(), onPressed: () {})
```

### Cards (`TGC`)

```dart
TGC(child: Text('Content'))                          // surface
TGC(variant: TGCVariant.elevated, child: ...)        // shadow
TGC(variant: TGCVariant.outlined, child: ...)        // border
TGCGradient(child: ...)                               // gradient bg
TGCKpi(icon: Icons.revenue, value: '$1,200', label: 'Revenue')  // stat card
```

### Badges (`TGBadge`)

```dart
TGBadge.active()
TGBadge.inactive()
TGBadge.pending()
TGBadge.error()
TGBadge.count(count: 5)
TGBadge.role(label: 'Admin')
TGBadge.category(label: 'Food')
TGDot(pulse: true)  // online indicator
```

### Avatar (`TGAvatar`)

```dart
TGAvatar(size: TGAvatarSize.lg, imageUrl: url, name: 'John')
TGAvatar(size: TGAvatarSize.md, imageUrl: url, showOnlineDot: true)
```

### Text Field (`TGF`)

```dart
TGF(
  label: 'Email',
  prefixIcon: Icons.email_outlined,
  keyboardType: TextInputType.emailAddress,
)
```

### Chip (`TGChip`) — NEW

```dart
TGChip.filter(label: 'Food', selected: true, onTap: () {})
TGChip.action(label: 'Add to cart', icon: Icons.add, onTap: () {})
TGChip.input(label: 'Chicken', onDelete: () {})
TGCategoryChip(label: 'Pizza', icon: Icons.local_pizza, selected: false, onTap: () {})
```

### Switch (`TGSwitch`) — NEW

```dart
TGSwitch(value: isOnline, onChanged: (v) => setState(() => isOnline = v))
TGSwitch(value: enabled, label: 'Notifications', subtitle: 'Receive push alerts', onChanged: ...)
```

### Progress (`TGCircularProgress`, `TGLinearProgress`) — NEW

```dart
TGCircularProgress()                    // spinner
TGCircularProgress(size: 48, label: 'Uploading...')
TGLinearProgress(value: 0.7, label: 'Upload', valueLabel: '70%')
```

### Search Bar (`TGSearchBar`) — NEW

```dart
TGSearchBar(
  hintText: 'What do you need?',
  onChanged: (q) => _search(q),
)
```

### Rating (`TGRating`, `TGRatingBar`) — NEW

```dart
TGRating(rating: 4.5, showValue: true, label: '(120)')
TGRatingBar(rating: rating, onRatingChanged: (r) => _rate(r))
```

### Banner (`TGBanner`) — NEW

```dart
TGBanner.info(message: 'New feature available')
TGBanner.success(message: 'Order placed!')
TGBanner.warning(message: 'Low balance')
TGBanner.error(message: 'Payment failed', onDismiss: () {})
```

### Dialog (`TGDialog`)

```dart
TGDialog.show(
  context: context,
  title: 'Confirm',
  content: 'Are you sure?',
  primaryLabel: 'Yes',
  primaryOnPressed: () => Navigator.pop(context),
  secondaryLabel: 'Cancel',
  secondaryOnPressed: () => Navigator.pop(context),
)
```

### Bottom Sheet (`TGBottomSheet`, `TGConfirmSheet`)

```dart
TGBottomSheet.show(context: context, title: 'Options', child: ...)
TGConfirmSheet.show(context: context, title: 'Delete?', confirmLabel: 'Delete', onConfirm: ...)
```

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

### Error Widget (`TGErrorWidget`)

```dart
TGErrorWidget(
  title: 'Something went wrong',
  message: 'Please try again',
  onRetry: () => _reload(),
)
```

### Loader (`AppLoader`)

```dart
AppLoader()                    // centered spinner
AppLoader(message: 'Loading...')  // with text
```

### Skeleton (`TGS`)

```dart
TGS.text()                    // single line
TGS.textMulti(lines: 3)       // multi-line
TGS.avatar()                  // circle
TGS.card()                    // rectangle
TGS.image()                   // image placeholder
TGSGroup(count: 3, builder: (_) => TGS.card())  // group
```

### Utility

```dart
TGDivider()                    // horizontal line
TGSpacer.heightLg              // 20px vertical space
TGText('Hello')                // themed text
TGContainer(child: ...)        // surface bg container
```

---

## Animations

```dart
// Page transitions
HeroSlideRoute(page: NextScreen())
HeroFadeRoute(page: NextScreen())
HeroScaleRoute(page: NextScreen())

// Widgets
AnimatedFadeSlide(child: ...)       // fade + slide in
AnimatedStagger(children: [...])    // staggered list
AnimatedScaleIn(child: ...)         // scale pop-in
AnimatedPulse(child: ...)           // pulse opacity
ShimmerWrapper(isLoading: true, child: ...)  // shimmer loading
TGPressScale(onTap: () {}, child: ...)       // press feedback
PulseAnimation(child: ...)          // breathing pulse
AnimatedCounter(value: 42)          // number animation
```

---

## Theming

```dart
// Toggle theme
context.read<ThemeProvider>().toggle();

// Check mode
context.isDark  // bool

// System theme
ThemeProvider().setMode(ThemeMode.system)
```

---

## Design Rules

1. **Always use `context.*Color`** for backgrounds, surfaces, text — never `AppColors.*`
2. **Use `AppColors.*`** only for brand colors (primary, error, success, warning, premium)
3. **Use `TGB`** for all buttons — no custom ElevatedButton/OutlinedButton
4. **Use `TGC`** for all cards — no custom Container with BoxDecoration
5. **Use `TGAvatar`** for all user images — handles fallback, online dot, roles
6. **Use `TGEmptyState`** for empty screens — consistent icon + message + action
7. **Use `TGErrorWidget`** for error states — shake animation + retry
8. **Use `TGS`** for loading skeletons — never plain Container placeholders
9. **Use `AppSpacing`** for margins/padding — no magic numbers
10. **Use `AppRadius`** for border radius — no hardcoded values
