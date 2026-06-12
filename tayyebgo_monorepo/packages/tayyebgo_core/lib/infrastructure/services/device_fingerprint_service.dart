import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DeviceFingerprint {
  final String deviceId;
  final String platform;
  final String? model;
  final String? os;
  final String? appVersion;
  final String? ipAddress;
  final Map<String, dynamic> extra;

  const DeviceFingerprint({
    required this.deviceId,
    required this.platform,
    this.model,
    this.os,
    this.appVersion,
    this.ipAddress,
    this.extra = const {},
  });

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'platform': platform,
        if (model != null) 'model': model,
        if (os != null) 'os': os,
        if (appVersion != null) 'appVersion': appVersion,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (extra.isNotEmpty) 'extra': extra,
      };
}

class DeviceFingerprintService {
  static final DeviceFingerprintService instance = DeviceFingerprintService._();
  DeviceFingerprintService._();

  String? _cachedDeviceId;

  Future<DeviceFingerprint> collectFingerprint() async {
    final deviceId = await _getOrCreateDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();
    final info = _getPlatformInfo();

    return DeviceFingerprint(
      deviceId: deviceId,
      platform: Platform.operatingSystem,
      model: info['model'],
      os: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      appVersion: packageInfo.version,
      extra: {
        'packageName': packageInfo.packageName,
        'buildNumber': packageInfo.buildNumber,
      },
    );
  }

  Future<void> registerDevice({
    required String userId,
    required DeviceFingerprint fingerprint,
  }) async {
    try {
      final docId = '${userId}_${fingerprint.deviceId}';
      final docRef =
          FirebaseFirestore.instance.collection('user_devices').doc(docId);

      final existing = await docRef.get();
      if (existing.exists) {
        await docRef.update({
          'lastSeen': FieldValue.serverTimestamp(),
          'appVersion': fingerprint.appVersion,
        });
      } else {
        await docRef.set({
          'userId': userId,
          'deviceId': fingerprint.deviceId,
          'platform': fingerprint.platform,
          'model': fingerprint.model,
          'os': fingerprint.os,
          'appVersion': fingerprint.appVersion,
          'firstSeen': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'trustScore': 50,
          'flags': [],
        });
      }
    } catch (e) {
      debugPrint('[DeviceFingerprint] registerDevice error: $e');
    }
  }

  Future<bool> isKnownDevice({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final docId = '${userId}_$deviceId';
      final doc = await FirebaseFirestore.instance
          .collection('user_devices')
          .doc(docId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('[DeviceFingerprint] isKnownDevice error: $e');
      return false;
    }
  }

  Future<int> getDeviceTrustScore({
    required String userId,
    required String deviceId,
  }) async {
    try {
      final docId = '${userId}_$deviceId';
      final doc = await FirebaseFirestore.instance
          .collection('user_devices')
          .doc(docId)
          .get();
      if (!doc.exists) return 50;
      return (doc.data()?['trustScore'] as int?) ?? 50;
    } catch (e) {
      debugPrint('[DeviceFingerprint] getDeviceTrustScore error: $e');
      return 50;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = _generateId();
      await prefs.setString('device_id', id);
    }
    _cachedDeviceId = id;
    return id;
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final platform = Platform.operatingSystem;
    final random = now.hashCode.toRadixString(36);
    return '${platform}_$random';
  }

  Map<String, String> _getPlatformInfo() {
    return {
      'model': Platform.operatingSystem,
    };
  }
}
