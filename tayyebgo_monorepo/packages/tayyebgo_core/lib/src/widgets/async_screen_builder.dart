import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/tayyebgo_theme.dart';

class AsyncScreenBuilder<T> extends StatefulWidget {
  final Stream<T>? stream;
  final Future<T>? future;
  final T? initialData;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(String message, VoidCallback onRetry)? onError;

  const AsyncScreenBuilder({
    super.key,
    this.stream,
    this.future,
    this.initialData,
    required this.onSuccess,
    this.onLoading,
    this.onError,
  });

  @override
  State<AsyncScreenBuilder<T>> createState() => _AsyncScreenBuilderState<T>();
}

class _AsyncScreenBuilderState<T> extends State<AsyncScreenBuilder<T>> {
  late AsyncSnapshot<T> _snapshot;
  StreamSubscription<T>? _sub;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData != null
        ? AsyncSnapshot<T>.withData(ConnectionState.waiting, widget.initialData as T)
        : AsyncSnapshot<T>.nothing();
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _hasError = false;
    _errorMessage = '';

    if (widget.stream != null) {
      _sub = widget.stream!.listen(
        (data) {
          if (mounted) {
            setState(() {
              _snapshot = AsyncSnapshot.withData(ConnectionState.active, data);
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = err.toString();
              _snapshot = AsyncSnapshot.withError(ConnectionState.done, err);
            });
          }
        },
      );
      if (widget.initialData != null) {
        _snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, widget.initialData as T);
      }
    } else if (widget.future != null) {
      widget.future!.then((data) {
        if (mounted) {
          setState(() {
            _snapshot = AsyncSnapshot.withData(ConnectionState.done, data);
          });
        }
      }).catchError((err) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = err.toString();
            _snapshot = AsyncSnapshot.withError(ConnectionState.done, err);
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(AsyncScreenBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream || widget.future != oldWidget.future) {
      _subscribe();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      final errorWidget = widget.onError;
      if (errorWidget != null) {
        return errorWidget(_errorMessage, _retry);
      }
      return _defaultError(_errorMessage);
    }

    if (_snapshot.connectionState == ConnectionState.waiting && !_snapshot.hasData) {
      return widget.onLoading?.call() ?? _defaultLoading();
    }

    if (_snapshot.hasData) {
      return widget.onSuccess(context, _snapshot.data as T);
    }

    return widget.onLoading?.call() ?? _defaultLoading();
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _snapshot = widget.initialData != null
          ? AsyncSnapshot<T>.withData(ConnectionState.waiting, widget.initialData as T)
          : AsyncSnapshot<T>.nothing();
    });
    _subscribe();
  }

  Widget _defaultLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _defaultError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TayyebGoTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: TayyebGoTheme.errorColor),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TayyebGoTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: TayyebGoTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TayyebGoTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamScreenBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T? initialData;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(String message, VoidCallback onRetry)? onError;

  const StreamScreenBuilder({
    super.key,
    required this.stream,
    this.initialData,
    required this.onSuccess,
    this.onLoading,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncScreenBuilder<T>(
      stream: stream,
      initialData: initialData,
      onSuccess: onSuccess,
      onLoading: onLoading,
      onError: onError,
    );
  }
}

class FutureScreenBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(String message, VoidCallback onRetry)? onError;

  const FutureScreenBuilder({
    super.key,
    required this.future,
    required this.onSuccess,
    this.onLoading,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncScreenBuilder<T>(
      future: future,
      onSuccess: onSuccess,
      onLoading: onLoading,
      onError: onError,
    );
  }
}
