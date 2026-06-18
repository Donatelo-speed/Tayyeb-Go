import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

enum DeepLinkType {
  order,
  restaurant,
  unknown,
}

class DeepLinkRoute {
  final DeepLinkType type;
  final String id;

  const DeepLinkRoute({required this.type, required this.id});
}

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  final StreamController<DeepLinkRoute> _routeController =
      StreamController<DeepLinkRoute>.broadcast();

  Stream<DeepLinkRoute> get onRoute => _routeController.stream;

  Future<void> initialize() async {
    final initialLink = await _appLinks.getInitialAppLinkString();
    if (initialLink != null) {
      final route = handleIncomingLink(Uri.parse(initialLink));
      if (route != null) {
        _routeController.add(route);
      }
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final route = handleIncomingLink(uri);
        if (route != null) {
          _routeController.add(route);
        }
      },
      onError: (err) {
        debugPrint('DeepLinkService error: $err');
      },
    );
  }

  DeepLinkRoute? handleIncomingLink(Uri link) {
    final route = _parseLink(link);
    if (route != null) {
      debugPrint('Deep link handled: ${route.type.name} -> ${route.id}');
    }
    return route;
  }

  DeepLinkRoute? _parseLink(Uri uri) {
    final path = uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return null;

    final type = segments[0];
    if (segments.length < 2) return null;

    final id = segments[1];
    if (id.isEmpty) return null;

    switch (type) {
      case 'order':
        return DeepLinkRoute(type: DeepLinkType.order, id: id);
      case 'restaurant':
        return DeepLinkRoute(type: DeepLinkType.restaurant, id: id);
      default:
        return DeepLinkRoute(type: DeepLinkType.unknown, id: id);
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _routeController.close();
  }
}
