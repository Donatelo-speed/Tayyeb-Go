import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool dark;

  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    this.height = 18,
    this.borderRadius = 10,
    this.dark = false,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();
    _anim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final base =
            widget.dark ? TayyebGoColors.shimmerDarkBase : TayyebGoColors.shimmerBase;
        final highlight = widget.dark
            ? TayyebGoColors.shimmerDarkHighlight
            : TayyebGoColors.shimmerHighlight;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final bool dark;
  final double height;

  const SkeletonCard({super.key, this.dark = false, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final surface =
        dark ? TayyebGoColors.darkCard : TayyebGoColors.surface;
    final border = dark ? TayyebGoColors.darkDivider : TayyebGoColors.divider;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(
            height: height * 0.6,
            borderRadius: 12,
            dark: dark,
          ),
          const SizedBox(height: 14),
          ShimmerBlock(width: double.infinity, height: 16, dark: dark),
          const SizedBox(height: 8),
          ShimmerBlock(width: 140, height: 14, dark: dark),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(width: 70, height: 14, dark: dark),
              ShimmerBlock(width: 50, height: 14, dark: dark),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final bool dark;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.count = 4,
    this.dark = false,
    this.itemHeight = 180,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
        child: SkeletonCard(dark: dark, height: itemHeight),
      ),
    );
  }
}

class SkeletonMetricRow extends StatelessWidget {
  final int count;
  final bool dark;

  const SkeletonMetricRow({super.key, this.count = 3, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 8,
              right: i == count - 1 ? 0 : 8,
            ),
            child: _SkeletonMetricCard(dark: dark),
          ),
        ),
      ),
    );
  }
}

class _SkeletonMetricCard extends StatelessWidget {
  final bool dark;

  const _SkeletonMetricCard({required this.dark});

  @override
  Widget build(BuildContext context) {
    final surface =
        dark ? TayyebGoColors.darkCard : TayyebGoColors.surface;
    final border = dark ? TayyebGoColors.darkDivider : TayyebGoColors.divider;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBlock(width: 36, height: 36, borderRadius: 10, dark: dark),
              ShimmerBlock(width: 48, height: 14, dark: dark),
            ],
          ),
          const SizedBox(height: 14),
          ShimmerBlock(width: 80, height: 28, dark: dark),
          const SizedBox(height: 6),
          ShimmerBlock(width: 100, height: 13, dark: dark),
        ],
      ),
    );
  }
}

class SkeletonPage extends StatelessWidget {
  final bool dark;
  final String? title;

  const SkeletonPage({super.key, this.dark = false, this.title});

  @override
  Widget build(BuildContext context) {
    final bg =
        dark ? TayyebGoColors.darkBg : TayyebGoColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: title != null
          ? AppBar(
              title: ShimmerBlock(width: 140, height: 20, dark: dark),
              backgroundColor: bg,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title == null) ...[
                ShimmerBlock(width: 160, height: 28, borderRadius: 14, dark: dark),
                const SizedBox(height: 20),
              ],
              SkeletonMetricRow(count: 3, dark: dark),
              const SizedBox(height: 24),
              ShimmerBlock(width: 120, height: 20, dark: dark),
              const SizedBox(height: 16),
              Expanded(child: SkeletonList(count: 3, dark: dark)),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashLoadingScreen extends StatefulWidget {
  final String subtitle;

  const SplashLoadingScreen({super.key, this.subtitle = 'Loading...'});

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: TayyebGoGradients.vibrant,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853)
                              .withValues(alpha: 0.3 * _pulse.value),
                          blurRadius: 30 * (1 + _pulse.value),
                          spreadRadius: 4 * _pulse.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _rotate,
                  builder: (_, _) => SizedBox(
                    width: 118,
                    height: 118,
                    child: CircularProgressIndicator(
                      value: _pulse.value,
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.25),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Tayyeb',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w200,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                width: 120,
                height: 2.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C853).withValues(alpha: _pulse.value),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                    stops: [0.0, _pulse.value],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
),
          ],
        ),
      ),
    );
  }
}

class ShimmerLoading extends ShimmerBlock {
  const ShimmerLoading({
    super.key,
    super.width,
    super.height,
    super.borderRadius,
    bool isDark = false,
  }) : super(dark: isDark);
}

class ShimmerList extends SkeletonList {
  const ShimmerList({
    super.key,
    int itemCount = 3,
    bool isDark = false,
  }) : super(count: itemCount, dark: isDark);
}

class ShimmerCard extends SkeletonCard {
  const ShimmerCard({super.key, bool isDark = false})
      : super(dark: isDark);
}

class ShimmerMetricCard extends _SkeletonMetricCard {
  const ShimmerMetricCard({bool isDark = false}) : super(dark: isDark);
}

class AnimatedLoadingScreen extends SplashLoadingScreen {
  const AnimatedLoadingScreen({
    super.key,
    String message = 'Loading...',
  }) : super(subtitle: message);
}