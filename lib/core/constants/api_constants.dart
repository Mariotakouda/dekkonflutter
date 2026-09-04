class ApiConstants {
  ApiConstants._();

  // ⚠️ En développement local, l'IP dépend de l'environnement :
  // - Émulateur Android : 10.0.2.2 pointe vers le localhost de la machine hôte
  // - Appareil physique / iOS simulator : utiliser l'IP locale de ta machine (ex: 192.168.1.X)
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String sendVerification = '/auth/verification/send';
  static const String verifyAccount = '/auth/verification/verify';

  // Profile & Addresses
  static const String profile = '/profile';
  static const String addresses = '/addresses';

  // Catalogue
  static const String categories = '/categories';
  static const String products = '/products';

  // Favorites
  static const String favorites = '/favorites';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  // Orders
  static const String orders = '/orders';

  // Reviews
  static const String reviews = '/reviews';

  // Notifications
  static const String notifications = '/notifications';

    // Admin
  static const String adminEmployees = '/admin/employees';
  static const String adminRoles = '/admin/roles';
  static const String adminPermissions = '/admin/permissions';
  static const String adminCategories = '/admin/categories';
  static const String adminProducts = '/admin/products';
  static const String adminInventory = '/admin/inventory';
  static const String adminStockMovements = '/admin/stock-movements';
  static const String adminOrders = '/admin/orders';
  static const String adminPayments = '/admin/payments';
  static const String adminDeliveries = '/admin/deliveries';
  static const String adminDrivers = '/admin/drivers';
  static const String adminPromotions = '/admin/promotions';
  static const String adminActivityLogs = '/admin/activity-logs';
}