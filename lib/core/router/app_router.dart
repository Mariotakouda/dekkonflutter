import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/secure_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'scaffold_with_nav_bar.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/delivery/presentation/screens/delivery_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/addresses/presentation/screens/addresses_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/orders/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/orders/presentation/screens/admin_order_detail_screen.dart';
import '../../features/admin/inventory/presentation/screens/admin_inventory_screen.dart';
import '../../features/admin/products/presentation/screens/admin_products_list_screen.dart';
import '../../features/admin/categories/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/deliveries/presentation/screens/admin_deliveries_screen.dart';
import '../../features/admin/drivers/presentation/screens/admin_drivers_screen.dart';
import '../../features/admin/employees/presentation/screens/admin_employees_screen.dart';
import '../../features/admin/promotions/presentation/screens/admin_promotions_screen.dart';
import '../../features/admin/activity_logs/presentation/screens/admin_activity_logs_screen.dart';
import '../../features/admin/payments/presentation/screens/admin_payments_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Arguments passés en `extra` vers la route `/auth`. `redirectTo` permet de
/// revenir sur la page d'origine (ex: fiche produit) après une connexion ou
/// une inscription déclenchée depuis une action qui exige un compte (ajout
/// au panier, favoris...), au lieu d'atterrir systématiquement sur l'accueil.
class AuthScreenArgs {
  final bool startInLoginMode;
  final String? redirectTo;

  const AuthScreenArgs({this.startInLoginMode = true, this.redirectTo});
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String payments = '/payments';
  static const String delivery = '/delivery/:id';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String addresses = '/addresses';
  static const String reviews = '/reviews';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/:id';
  static const String adminInventory = '/admin/inventory';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminDeliveries = '/admin/deliveries';
  static const String adminDrivers = '/admin/drivers';
  static const String adminEmployees = '/admin/employees';
  static const String adminPromotions = '/admin/promotions';
  static const String adminPayments = '/admin/payments';
  static const String adminActivityLogs = '/admin/activity-logs';
}

// Routes accessibles sans connexion : navigation/découverte uniquement.
// Tout le reste (panier, commandes, paiements, profil, favoris, avis, admin...)
// nécessite un compte, à l'image du groupe 'auth:sanctum' côté Laravel
// (routes/api_client.php : seuls 'categories' et 'products' sont publics).
const Set<String> _publicRoutePaths = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.auth,
  AppRoutes.home,
  AppRoutes.categories,
  AppRoutes.products,
  AppRoutes.productDetail,
};

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final hasToken = await SecureStorage.hasToken();
      // fullPath donne le gabarit de route ('/products/:id'), pas l'URL résolue —
      // nécessaire pour matcher AppRoutes.productDetail correctement.
      final matchedPath = state.fullPath ?? state.matchedLocation;
      final isAuthRoute = matchedPath == AppRoutes.auth;
      final isSplash = matchedPath == AppRoutes.splash;
      final isPublicRoute = _publicRoutePaths.contains(matchedPath);

      if (isSplash) return null;

      if (!hasToken && !isPublicRoute) {
        return AppRoutes.auth;
      }

      if (hasToken && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashRedirector(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) {
          // `extra` transporte soit un simple bool (ancien usage : mode
          // initial connexion/inscription), soit un AuthScreenArgs complet
          // avec une éventuelle page de retour (`redirectTo`).
          final extra = state.extra;
          bool startInLoginMode = true;
          String? redirectTo;
          if (extra is AuthScreenArgs) {
            startInLoginMode = extra.startInLoginMode;
            redirectTo = extra.redirectTo;
          } else if (extra is bool) {
            startInLoginMode = extra;
          }
          return AuthScreen(startInLoginMode: startInLoginMode, redirectTo: redirectTo);
        },
      ),

      // --- Coquille persistante des 5 onglets principaux ---
      // Chaque branche garde sa propre pile de navigation et son état
      // (scroll, filtres) même en changeant d'onglet : les écrans ne sont
      // jamais reconstruits, contrairement à l'ancien système où chaque
      // écran gérait sa propre bottomNavigationBar via context.go().
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, state) {
                  final categoryId = state.uri.queryParameters['category_id'];
                  final featured = state.uri.queryParameters['featured'] == 'true';
                  final search = state.uri.queryParameters['search'];
                  return ProductsScreen(
                    initialCategoryId: categoryId,
                    initialFeaturedOnly: featured,
                    initialSearch: search,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Écrans secondaires (hors shell) ---
      // Poussés en plein écran, par-dessus la coquille, sans bottom nav :
      // détail, formulaires, tunnels de paiement... Volontaire (voir
      // explication UX) — on ne laisse pas sortir facilement d'un tunnel
      // comme le checkout, et un écran de détail n'est pas une "destination"
      // au même titre qu'un onglet.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.payments,
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.delivery,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeliveryScreen(deliveryId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.reviews,
        builder: (context, state) => const ReviewsScreen(),
      ),

      // Admin
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminOrders,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminOrderDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminOrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminInventory,
        builder: (context, state) => const AdminInventoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminProducts,
        builder: (context, state) => const AdminProductsListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminCategories,
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminDeliveries,
        builder: (context, state) => const AdminDeliveriesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminDrivers,
        builder: (context, state) => const AdminDriversScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminEmployees,
        builder: (context, state) => const AdminEmployeesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminPromotions,
        builder: (context, state) => const AdminPromotionsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminPayments,
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.adminActivityLogs,
        builder: (context, state) => const AdminActivityLogsScreen(),
      ),
    ],
  );
});

class _SplashRedirector extends ConsumerStatefulWidget {
  const _SplashRedirector();

  @override
  ConsumerState<_SplashRedirector> createState() => _SplashRedirectorState();
}

class _SplashRedirectorState extends ConsumerState<_SplashRedirector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    // Barre de chargement animée sur 3 secondes (demande explicite : logo +
    // barre qui charge pendant 3s avant la suite).
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..forward();

    Future.microtask(() async {
      // On charge la session ET on attend les 3 secondes minimum en parallèle,
      // pour ne pas rallonger l'attente si la session se charge plus vite.
      await Future.wait([
        ref.read(authNotifierProvider.notifier).loadCurrentUser(),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final onboardingSeen = prefs.getBool(onboardingSeenKey) ?? false;

      if (!mounted) return;

      if (!onboardingSeen) {
        // Premier lancement de l'app : on montre les pages de bienvenue
        // avant tout, même pour un utilisateur déjà connecté (rare en
        // pratique) — l'onboarding lui-même redirige ensuite vers /home.
        context.go(AppRoutes.onboarding);
        return;
      }

      final authState = ref.read(authNotifierProvider);

      if (!authState.isAuthenticated) {
        // Pas de session valide : on laisse l'invité explorer le catalogue
        // plutôt que de le forcer vers l'écran de connexion.
        context.go(AppRoutes.home);
        return;
      }

      final isEmployee = authState.user?.isEmployee ?? false;
      context.go(isEmployee ? AppRoutes.adminDashboard : AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                // Le fichier doit être fourni par l'équipe design/produit à
                // assets/images/logodekkon.png (déclaré dans pubspec.yaml).
                // Repli propre en attendant si le fichier est absent.
                child: Image.asset(
                  'assets/images/logodekkon.png',
                  width: 160,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.storefront, size: 72, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text('DEKKON', style: AppTextStyles.h1.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressController.value,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}