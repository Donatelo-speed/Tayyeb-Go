import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring for TayyebGo — tracks frame drops, widget rebuilds, and memory.
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._();

  final List<double> _frameTimes = [];
  int _droppedFrames = 0;
  bool _isMonitoring = false;

  bool get isMonitoring => _isMonitoring;
  int get droppedFrames => _droppedFrames;
  double get averageFrameTime =>
      _frameTimes.isEmpty ? 0 : _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
  double get fps => averageFrameTime > 0 ? 1000 / averageFrameTime : 0;

  /// Starts monitoring frame rendering times.
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _droppedFrames = 0;
    _frameTimes.clear();
    SchedulerBinding.instance.addTimingsCallback(_onTimingsCallback);
  }

  /// Stops monitoring.
  void stopMonitoring() {
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimingsCallback);
  }

  void _onTimingsCallback(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration.inMicroseconds;
      final rasterDuration = timing.rasterDuration.inMicroseconds;
      final totalDuration = (buildDuration + rasterDuration) / 1000.0; // Convert to ms
      _frameTimes.add(totalDuration);

      // Keep last 120 frames for rolling average
      if (_frameTimes.length > 120) {
        _frameTimes.removeAt(0);
      }

      // Frame is considered "dropped" if it takes > 16.67ms (60fps target)
      if (totalDuration > 16.67) {
        _droppedFrames++;
      }
    }
  }

  /// Returns a performance summary.
  Map<String, dynamic> getSummary() {
    return {
      'averageFrameTime': averageFrameTime.toStringAsFixed(2),
      'fps': fps.toStringAsFixed(1),
      'droppedFrames': _droppedFrames,
      'totalFramesTracked': _frameTimes.length,
    };
  }

  /// Logs a performance metric for debugging.
  void logMetric(String name, Duration duration) {
    debugPrint('[PERF] $name: ${duration.inMilliseconds}ms');
  }
}
