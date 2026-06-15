import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class TayyebGoPicksScreen extends StatelessWidget {
  const TayyebGoPicksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Row(
              children: [
                AnimatedPressScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_rounded, color: context.textPrimaryColor, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Text('TayyebGo Picks', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 28, color: context.textPrimaryColor, letterSpacing: 0)),
              ],
            ),
            const SizedBox(height: 24),
            _pickSection(context, 'Best Burgers', Icons.lunch_dining_rounded, const Color(0xFFF97316), ['Smash Bros', 'Burger Factory', 'The Patty Club']),
            const SizedBox(height: 20),
            _pickSection(context, 'Best Coffee', Icons.coffee_rounded, const Color(0xFF8B5CF6), ['Café Latte', 'Bean House', 'Morning Brew']),
            const SizedBox(height: 20),
            _pickSection(context, 'Local Favorites', Icons.favorite_rounded, const Color(0xFFEF4444), ['Damascus Kitchen', 'Al Sham', 'Home Taste']),
            const SizedBox(height: 20),
            _pickSection(context, 'Late Night Cravings', Icons.nightlight_round, const Color(0xFF3B82F6), ['Night Owl Pizza', 'Midnight Shawarma', '24/7 Grill']),
          ],
        ),
      ),
    );
  }

  Widget _pickSection(BuildContext context, String title, IconData icon, Color color, List<String> stores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: 0.5)]), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: context.textPrimaryColor, letterSpacing: 0)),
        ]),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: stores.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => AnimatedPressScale(
            onTap: () {},
            child: Container(
              width: 160, decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 80, width: double.infinity,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                  child: Center(child: Icon(icon, color: color, size: 32))),
                Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stores[i], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('4.${5 + i}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
                  ]),
                ])),
              ]),
            ),
          ),
        )),
      ],
    );
  }
}
