import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class LoyaltyRewardsScreen extends StatelessWidget {
  const LoyaltyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthProvider.instance?.user?.id ?? '';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('ShamCash Rewards', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPointsCard(context, userId),
          const SizedBox(height: 24),
          Text('How to Earn', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _buildEarnTile(context, Icons.shopping_bag_rounded, 'Place Orders', 'Earn 1 coin per \$1 spent', const Color(0xFF6366F1)),
          _buildEarnTile(context, Icons.group_add_rounded, 'Refer Friends', 'Earn 50 coins per referral', const Color(0xFF10B981)),
          _buildEarnTile(context, Icons.local_fire_department_rounded, 'Daily Streak', 'Up to 20 bonus coins/day', const Color(0xFFF59E0B)),
          _buildEarnTile(context, Icons.star_rounded, '5-Star Reviews', 'Earn 10 coins per review', const Color(0xFFEC4899)),
          const SizedBox(height: 24),
          Text('Rewards Store', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _buildRewardTile(context, 'Free Delivery', '100 coins', Icons.local_shipping_rounded, const Color(0xFF10B981)),
          _buildRewardTile(context, '\$2 Off Next Order', '200 coins', Icons.discount_rounded, const Color(0xFF6366F1)),
          _buildRewardTile(context, '\$5 Off Next Order', '450 coins', Icons.savings_rounded, const Color(0xFFF59E0B)),
          _buildRewardTile(context, 'Free Dessert', '300 coins', Icons.cake_rounded, const Color(0xFFEC4899)),
          const SizedBox(height: 24),
          Text('Recent Activity', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: context.textPrimaryColor)),
          const SizedBox(height: 12),
          _buildTransactionsList(context, userId),
        ],
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final points = (data?['loyaltyCoins'] as num?)?.toInt() ?? (data?['loyaltyPoints'] as num?)?.toInt() ?? 0;

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '$points',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 48, color: Colors.white),
              ),
              Text(
                'ShamCash Coins',
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _tierFromPoints(points),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _tierFromPoints(int points) {
    if (points >= 2000) return 'Platinum Member';
    if (points >= 1000) return 'Gold Member';
    if (points >= 500) return 'Silver Member';
    return 'Bronze Member';
  }

  Widget _buildEarnTile(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: context.textMutedColor)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.textMutedColor),
        ],
      ),
    );
  }

  Widget _buildRewardTile(BuildContext context, String title, String cost, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimaryColor)),
                Text(cost, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Redeem', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('loyalty_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: context.primaryColor));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('No transactions yet', style: GoogleFonts.inter(color: context.textMutedColor)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final points = (data['points'] as num?)?.toInt() ?? 0;
            final description = data['description'] as String? ?? '';
            final type = data['type'] as String? ?? 'earned';
            final isEarned = type == 'earned' || type == 'bonus' || type == 'referral' || type == 'streak';
            final color = isEarned ? const Color(0xFF10B981) : const Color(0xFFEF4444);
            final sign = isEarned ? '+' : '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isEarned ? Icons.add_rounded : Icons.remove_rounded, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description.isNotEmpty ? description : (isEarned ? 'Earned' : 'Redeemed'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: context.textPrimaryColor),
                    ),
                  ),
                  Text(
                    '$sign$points coins',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
