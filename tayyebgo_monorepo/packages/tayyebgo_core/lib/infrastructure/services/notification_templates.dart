class NotificationTemplate {
  final String title;
  final String body;
  final String type;

  const NotificationTemplate({
    required this.title,
    required this.body,
    required this.type,
  });

  Map<String, dynamic> toMap(String orderId) => {
        'title': title,
        'body': body,
        'type': type,
        'orderId': orderId,
        'createdAt': DateTime.now().toIso8601String(),
      };
}

class NotificationTemplates {
  static NotificationTemplate forStatus(String status, String restaurantName) {
    switch (status) {
      case 'placed':
        return const NotificationTemplate(
          title: 'Order Placed',
          body: 'Your order has been placed successfully',
          type: 'order_placed',
        );
      case 'accepted':
        return NotificationTemplate(
          title: 'Order Accepted',
          body: '$restaurantName has accepted your order',
          type: 'order_accepted',
        );
      case 'preparing':
        return NotificationTemplate(
          title: 'Preparing Your Order',
          body: '$restaurantName is now preparing your food',
          type: 'order_preparing',
        );
      case 'ready':
      case 'ready_for_driver':
        return NotificationTemplate(
          title: 'Order Ready',
          body: 'Your order from $restaurantName is ready for pickup',
          type: 'order_ready',
        );
      case 'dispatched':
      case 'picked_up':
        return const NotificationTemplate(
          title: 'Order Dispatched',
          body: 'Your driver is on the way with your order',
          type: 'order_dispatched',
        );
      case 'delivered':
        return const NotificationTemplate(
          title: 'Order Delivered',
          body: 'Your order has been delivered. Enjoy!',
          type: 'order_delivered',
        );
      case 'cancelled':
        return NotificationTemplate(
          title: 'Order Cancelled',
          body: 'Your order from $restaurantName has been cancelled',
          type: 'order_cancelled',
        );
      default:
        return NotificationTemplate(
          title: 'Order Update',
          body: 'Your order status has changed to ${status.replaceAll('_', ' ')}',
          type: 'order_update',
        );
    }
  }

  static Map<String, dynamic> driverNotification(String action, String orderId) {
    switch (action) {
      case 'new_dispatch':
        return {
          'title': 'New Delivery Assignment',
          'body': 'You have been assigned a new delivery',
          'type': 'driver_new_dispatch',
          'orderId': orderId,
        };
      case 'pickup_ready':
        return {
          'title': 'Pickup Ready',
          'body': 'The order is ready for pickup at the restaurant',
          'type': 'driver_pickup_ready',
          'orderId': orderId,
        };
      default:
        return {
          'title': 'Delivery Update',
          'body': 'Your delivery has been updated',
          'type': 'driver_update',
          'orderId': orderId,
        };
    }
  }
}
