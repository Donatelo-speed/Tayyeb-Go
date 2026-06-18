import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tayyebgo_core/tayyebgo_core.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final _picker = ImagePicker();

  bool _licenseUploaded = false;
  bool _registrationUploaded = false;
  bool _insuranceUploaded = false;

  String? _licenseUrl;
  String? _registrationUrl;
  String? _insuranceUrl;

  bool _uploadingLicense = false;
  bool _uploadingRegistration = false;
  bool _uploadingInsurance = false;

  double _licenseProgress = 0;
  double _registrationProgress = 0;
  double _insuranceProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _loadExistingDocuments() async {
    if (_uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (!doc.exists || !mounted) return;
      final data = doc.data();
      final docs = data?['documents'] as Map<String, dynamic>?;
      if (docs != null) {
        setState(() {
          _licenseUrl = docs['licenseUrl'] as String?;
          _registrationUrl = docs['registrationUrl'] as String?;
          _insuranceUrl = docs['insuranceUrl'] as String?;
          _licenseUploaded = _licenseUrl != null && _licenseUrl!.isNotEmpty;
          _registrationUploaded = _registrationUrl != null && _registrationUrl!.isNotEmpty;
          _insuranceUploaded = _insuranceUrl != null && _insuranceUrl!.isNotEmpty;
        });
      }
    } catch (e) { debugPrint('[Documents] load error: $e'); }
  }

  Future<void> _uploadDocument({
    required String docType,
    required String storageFileName,
    required String firestoreField,
    required bool Function() isUploaded,
    required void Function(bool, {double? progress, String? url}) setStateFn,
  }) async {
    if (isUploaded()) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;

      setStateFn(true, progress: 0);

      final ref = FirebaseStorage.instance.ref().child('drivers/$_uid/$storageFileName');
      final uploadTask = ref.putFile(File(picked.path));

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        setStateFn(true, progress: progress);
      });

      await uploadTask;
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'documents.$firestoreField': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setStateFn(true, url: url);
    } catch (e) {
      setStateFn(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload $docType: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _uploadLicense() => _uploadDocument(
        docType: 'Driving License',
        storageFileName: 'license.jpg',
        firestoreField: 'licenseUrl',
        isUploaded: () => _licenseUploaded,
        setStateFn: (uploaded, {progress, url}) {
          if (!mounted) return;
          setState(() {
            _uploadingLicense = !uploaded && progress != null;
            _licenseProgress = progress ?? 0;
            if (url != null) {
              _licenseUploaded = true;
              _licenseUrl = url;
              _uploadingLicense = false;
            }
            if (!uploaded && progress == null) {
              _uploadingLicense = false;
            }
          });
        },
      );

  Future<void> _uploadRegistration() => _uploadDocument(
        docType: 'Vehicle Registration',
        storageFileName: 'registration.jpg',
        firestoreField: 'registrationUrl',
        isUploaded: () => _registrationUploaded,
        setStateFn: (uploaded, {progress, url}) {
          if (!mounted) return;
          setState(() {
            _uploadingRegistration = !uploaded && progress != null;
            _registrationProgress = progress ?? 0;
            if (url != null) {
              _registrationUploaded = true;
              _registrationUrl = url;
              _uploadingRegistration = false;
            }
            if (!uploaded && progress == null) {
              _uploadingRegistration = false;
            }
          });
        },
      );

  Future<void> _uploadInsurance() => _uploadDocument(
        docType: 'Insurance',
        storageFileName: 'insurance.jpg',
        firestoreField: 'insuranceUrl',
        isUploaded: () => _insuranceUploaded,
        setStateFn: (uploaded, {progress, url}) {
          if (!mounted) return;
          setState(() {
            _uploadingInsurance = !uploaded && progress != null;
            _insuranceProgress = progress ?? 0;
            if (url != null) {
              _insuranceUploaded = true;
              _insuranceUrl = url;
              _uploadingInsurance = false;
            }
            if (!uploaded && progress == null) {
              _uploadingInsurance = false;
            }
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: context.textMutedColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Documents',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimaryColor),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Upload your required documents to start delivering.',
            style: GoogleFonts.inter(color: context.textMutedColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _documentCard(
            label: 'Driving License',
            subtitle: 'Photo of your valid driving license',
            icon: Icons.badge_rounded,
            isUploaded: _licenseUploaded,
            isUploading: _uploadingLicense,
            progress: _licenseProgress,
            onTap: _uploadLicense,
            url: _licenseUrl,
          ),
          const SizedBox(height: 12),
          _documentCard(
            label: 'Vehicle Registration',
            subtitle: 'Photo of your vehicle registration document',
            icon: Icons.description_rounded,
            isUploaded: _registrationUploaded,
            isUploading: _uploadingRegistration,
            progress: _registrationProgress,
            onTap: _uploadRegistration,
            url: _registrationUrl,
          ),
          const SizedBox(height: 12),
          _documentCard(
            label: 'Insurance',
            subtitle: 'Photo of your insurance certificate',
            icon: Icons.security_rounded,
            isUploaded: _insuranceUploaded,
            isUploading: _uploadingInsurance,
            progress: _insuranceProgress,
            onTap: _uploadInsurance,
            url: _insuranceUrl,
          ),
        ],
      ),
    );
  }

  Widget _documentCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    required bool isUploading,
    required double progress,
    required VoidCallback onTap,
    String? url,
  }) {
    return GestureDetector(
      onTap: isUploaded || isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: isUploaded ? context.successColor : context.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? context.successColor.withValues(alpha: 0.1)
                        : context.surfaceAltColor,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(
                    icon,
                    color: isUploaded ? context.successColor : context.textMutedColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: context.textMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUploaded)
                  Icon(Icons.check_circle_rounded, color: context.successColor, size: 24)
                else if (isUploading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      value: progress,
                      color: context.successColor,
                      backgroundColor: context.borderColor,
                    ),
                  )
                else
                  Icon(Icons.cloud_upload_rounded, color: context.textMutedColor, size: 24),
              ],
            ),
            if (isUploading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: AppRadius.brSm,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(context.successColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 11,
                ),
              ),
            ],
            if (isUploaded && url != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.successColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: context.successColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Uploaded successfully',
                      style: GoogleFonts.inter(
                        color: context.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
