class Config {
  // Backend Configuration
  static const String apiUrl = 'http://localhost:5000/api';
  static const String socketUrl = 'http://localhost:5000';
  
  // For demo mode - uses mock data when backend unavailable
  static const bool demoMode = true;
  
  // Google Maps API Key - Get free key from https://console.cloud.google.com/google/maps-apis/
  // For production, add your key here. Demo will show placeholder maps.
  static const String googleMapsApiKey = '';
  
  // App Info
  static const String appName = 'OmniMarket';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'سوق إلكتروني سوري موثوق';
  
  // Contact
  static const String supportPhone = '+963';
  static const String supportWhatsApp = '+963';
  
  // Currency - SYP exchange rate (updated in Admin Panel)
  static double exchangeRate = 13000.0;
  
  // Delivery Configuration
  static const double deliveryFee = 5.0;
  static const double freeDeliveryThreshold = 50.0;
  static const int deliveryTimeMinutes = 120;
  
  // Order Status Messages (Arabic)
  static const Map<String, String> orderStatusMessages = {
    'pending': 'جاري المعالجة',
    'accepted': 'تم القبول',
    'picked_up': 'تم الاستلام',
    'in_transit': 'في الطريق',
    'delivered': 'تم التوصيل',
    'cancelled': 'ملغى',
  };
}