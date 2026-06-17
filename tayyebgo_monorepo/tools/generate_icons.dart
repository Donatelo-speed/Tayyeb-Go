import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Define app configurations
  final apps = [
    {'name': 'tayyebgo_customer', 'color': Color(0xFF0050CB), 'label': 'TG'},
    {'name': 'tayyebgo_driver', 'color': Color(0xFFF97316), 'label': 'TG'},
    {'name': 'tayyebgo_partner', 'color': Color(0xFFB22C00), 'label': 'TG'},
    {'name': 'tayyebgo_admin', 'color': Color(0xFF8B5CF6), 'label': 'TG'},
  ];
  
  for (final app in apps) {
    await generateAppIcon(
      appName: app['name'] as String,
      primaryColor: app['color'] as Color,
      label: app['label'] as String,
    );
  }
  
  print('All icons generated!');
  exit(0);
}

Future<void> generateAppIcon({
  required String appName,
  required Color primaryColor,
  required String label,
}) async {
  print('Generating icon for $appName...');
  
  // Create icon sizes needed
  final sizes = {
    '48': 48,
    '72': 72,
    '96': 96,
    '144': 144,
    '192': 192,
    '512': 512,
    '1024': 1024,
  };
  
  for (final entry in sizes.entries) {
    final size = entry.value;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw icon background
    final paint = Paint()..color = primaryColor;
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.22));
    canvas.drawRRect(rrect, paint);
    
    // Draw letters
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Save to Android mipmap directories
    final androidDir = Directory('apps/$appName/android/app/src/main/res');
    final mipmapDirs = ['mipmap-mdpi', 'mipmap-hdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi'];
    
    for (final dir in mipmapDirs) {
      final targetSize = _getAndroidIconSize(dir);
      if (targetSize == size) {
        final dirPath = p.join(androidDir.path, dir);
        await Directory(dirPath).create(recursive: true);
        final file = File(p.join(dirPath, 'ic_launcher.png'));
        await file.writeAsBytes(bytes);
        print('  Saved $dir/ic_launcher.png (${size}x${size})');
      }
    }
    
    // Save to iOS
    final iosDir = Directory('apps/$appName/ios/Runner/Assets.xcassets/AppIcon.appiconset');
    if (await iosDir.exists()) {
      final iosSize = _getIOSIconSize(size);
      if (iosSize != null) {
        final file = File(p.join(iosDir.path, 'Icon-App-${iosSize}.png'));
        await file.writeAsBytes(bytes);
        print('  Saved iOS Icon-App-${iosSize}.png');
      }
    }
    
    // Save to web
    final webDir = Directory('apps/$appName/web/icons');
    await webDir.create(recursive: true);
    if (size == 192) {
      final file = File(p.join(webDir.path, 'Icon-192.png'));
      await file.writeAsBytes(bytes);
      final maskableFile = File(p.join(webDir.path, 'Icon-maskable-192.png'));
      await maskableFile.writeAsBytes(bytes);
      print('  Saved web icons');
    }
    if (size == 512) {
      final file = File(p.join(webDir.path, 'Icon-512.png'));
      await file.writeAsBytes(bytes);
      final maskableFile = File(p.join(webDir.path, 'Icon-maskable-512.png'));
      await maskableFile.writeAsBytes(bytes);
    }
    
    image.dispose();
  }
}

int _getAndroidIconSize(String dir) {
  switch (dir) {
    case 'mipmap-mdpi': return 48;
    case 'mipmap-hdpi': return 72;
    case 'mipmap-xhdpi': return 96;
    case 'mipmap-xxhdpi': return 144;
    case 'mipmap-xxxhdpi': return 192;
    default: return 48;
  }
}

String? _getIOSIconSize(int size) {
  switch (size) {
    case 48: return '20x20@1x';
    case 72: return '20x20@2x';
    case 96: return '29x29@2x';
    case 144: return '40x40@2x';
    case 192: return '60x60@2x';
    case 512: return '76x76@2x';
    case 1024: return '1024x1024@1x';
    default: return null;
  }
}