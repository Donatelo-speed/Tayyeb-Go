import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const BrandLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: TayyebGoTheme.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.25),
          boxShadow: [
            BoxShadow(
              color: TayyebGoTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.08),
            ),
          ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: iconSize * 0.75,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Icon(
                Icons.delivery_dining,
                size: iconSize,
                color: Colors.white,
              ),
              Positioned(
                bottom: size * 0.08,
                right: size * 0.08,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: size * 0.14,
                    color: TayyebGoTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'Tayyeb-Go',
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Order • Eat • Enjoy',
            style: TextStyle(
              fontSize: size * 0.16,
              color: (color ?? Colors.white).withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class BrandLogoBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool centerLogo;

  const BrandLogoBar({
    super.key,
    this.height = 56,
    this.centerLogo = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: TayyebGoTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.delivery_dining, size: 18, color: Colors.white),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on,
                        size: 6, color: TayyebGoTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Tayyeb-Go',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      centerTitle: centerLogo,
    );
  }
}
