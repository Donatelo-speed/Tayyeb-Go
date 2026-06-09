import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';
import '../../../../core/services/admin_firestore_service.dart';
import '../business_type.dart';
import '../shared.dart';

class StoreHeader extends StatelessWidget {
  final Map<String, dynamic> store;
  final String storeName;
  final String storeId;
  const StoreHeader({required this.store, required this.storeName, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final name = store['name'] as String? ?? storeName;
    final cuisine = store['cuisineType'] as String? ?? '';
    final active = store['isActive'] as bool? ?? true;
    final commission = (store['commissionPercent'] as num?)?.toDouble() ?? 15.0;
    final logoUrl = store['logoUrl'] as String?;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    final status = BusinessStatus.fromValue(store['businessStatus'] as String?);
    final businessTypeId = store['businessType'] as String? ?? store['cuisineType'] as String? ?? '';
    final businessType = BusinessTypes.byId(businessTypeId);
    final package = BusinessPackage.fromValue(store['package'] as String?);
    final category = businessType.category;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoBordered(context),
      child: Row(children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: context.primaryColor.withValues(alpha: 0.1),
          child: hasLogo
              ? ClipOval(child: Image.network(store['logoUrl'] as String, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(businessIcon(businessType.iconKey), color: context.primaryColor)))
              : Icon(businessIcon(businessType.iconKey), size: 32, color: context.primaryColor),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<BusinessStatus>(
          tooltip: 'Update status',
          icon: Icon(Icons.more_vert, color: context.textMutedColor),
          onSelected: (s) async {
            try {
              await AdminFirestoreService.instance.updateStoreStatus(storeId, s);
              if (context.mounted) context.showSuccess('Status updated to ${s.displayName}');
            } catch (e) {
              if (context.mounted) context.showError('Failed to update status');
            }
          },
          itemBuilder: (_) => BusinessStatus.values.map((s) {
            final color = statusColor(s.colorKey, context);
            return PopupMenuItem<BusinessStatus>(
              value: s,
              child: Row(children: [
                Icon(statusIcon(s.iconKey), size: 16, color: color),
                const SizedBox(width: 8),
                Text('Set ${s.displayName}', style: GoogleFonts.inter(color: context.textPrimaryColor)),
              ]),
            );
          }).toList(),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: context.textPrimaryColor))),
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(businessIcon(category.iconKey), size: 14, color: context.textMutedColor),
              const SizedBox(width: 4),
              Text('${category.displayName} • ${businessType.name}', style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            if (cuisine.isNotEmpty) Text(cuisine, style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (active ? context.successColor : context.errorColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(active ? 'Active' : 'Inactive', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: active ? context.successColor : context.errorColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${commission.toStringAsFixed(0)}% Commission', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.primaryColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.warningColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.workspace_premium, size: 12, color: context.warningColor),
                  const SizedBox(width: 3),
                  Text(package.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.warningColor)),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BusinessStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status.colorKey, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          status.displayName.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.4),
        ),
      ]),
    );
  }
}
