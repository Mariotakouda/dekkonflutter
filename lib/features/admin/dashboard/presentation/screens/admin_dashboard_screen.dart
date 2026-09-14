import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final employee = user?.employee;
    final permissions = ref.watch(employeePermissionsProvider);

    final allTiles = <_AdminTileConfig>[
      const _AdminTileConfig(
        icon: Symbols.receipt_long_rounded,
        label: 'Commandes',
        subtitle: 'Suivi et traitement',
        route: '/admin/orders',
        color: Color(0xFFFF6600), // Orange Alibaba
        requiredPermissions: [AdminPermissions.ordersView],
        badgeText: '12',
      ),
      const _AdminTileConfig(
        icon: Symbols.inventory_2_rounded,
        label: 'Stock',
        subtitle: 'Inventaires & Alertes',
        route: '/admin/inventory',
        color: Color(0xFF7C5CFC),
        requiredPermissions: [AdminPermissions.inventoryView],
      ),
      const _AdminTileConfig(
        icon: Symbols.grid_view_rounded,
        label: 'Produits',
        subtitle: 'Catalogue & Prix',
        route: '/admin/products',
        color: Color(0xFF0288D1),
        requiredPermissions: [AdminPermissions.productsManage],
      ),
      const _AdminTileConfig(
        icon: Symbols.category_rounded,
        label: 'Catégories',
        subtitle: 'Organisation',
        route: '/admin/categories',
        color: Color(0xFF009688),
        requiredPermissions: [AdminPermissions.categoriesManage],
      ),
      const _AdminTileConfig(
        icon: Symbols.local_shipping_rounded,
        label: 'Livraisons',
        subtitle: 'Expéditions',
        route: '/admin/deliveries',
        color: Color(0xFF2E7D32),
        requiredPermissions: [AdminPermissions.deliveriesView],
      ),
      const _AdminTileConfig(
        icon: Symbols.two_wheeler_rounded,
        label: 'Livreurs',
        subtitle: 'Flotte & Effectifs',
        route: '/admin/drivers',
        color: Color(0xFFEF6C00),
        requiredPermissions: [AdminPermissions.driversManage],
      ),
      const _AdminTileConfig(
        icon: Symbols.people_alt_rounded,
        label: 'Employés',
        subtitle: 'Rôles & Accès',
        route: '/admin/employees',
        color: Color(0xFF673AB7),
        requiredPermissions: [AdminPermissions.employeesManage, AdminPermissions.rolesManage],
      ),
      const _AdminTileConfig(
        icon: Symbols.local_offer_rounded,
        label: 'Promotions',
        subtitle: 'Offres & Remises',
        route: '/admin/promotions',
        color: Color(0xFFE53935),
        requiredPermissions: [AdminPermissions.promotionsView],
      ),
      const _AdminTileConfig(
        icon: Symbols.account_balance_wallet_rounded,
        label: 'Paiements',
        subtitle: 'Transactions',
        route: '/admin/payments',
        color: Color(0xFF00796B),
        requiredPermissions: [AdminPermissions.paymentsView],
      ),
      const _AdminTileConfig(
        icon: Symbols.history_toggle_off_rounded,
        label: "Journal",
        subtitle: "Historique d'activité",
        route: '/admin/activity-logs',
        color: Color(0xFF546E7A),
        requiredPermissions: [AdminPermissions.activityLogsView],
      ),
    ];

    final visibleTiles = allTiles
        .where((t) => permissions.hasAny(t.requiredPermissions))
        .where((t) => _searchQuery.isEmpty || t.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final initials = _initialsOf(employee?.fullName);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- Header & Profil ---
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFF6600).withValues(alpha: 0.12),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFFFF6600),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee?.fullName ?? 'Administrateur',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            employee?.role?.name ?? 'Espace Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.logout_rounded, color: Color(0xFF64748B), size: 22),
                      tooltip: 'Se déconnecter',
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go('/auth');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // --- Barre de recherche ---
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un module...',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Symbols.search_rounded, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // --- Stats Rapides (Style Dashboard B2B) ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  height: 82,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      _StatCard(title: 'Commandes du jour', value: '128', icon: Symbols.shopping_bag, color: Color(0xFFFF6600)),
                      SizedBox(width: 10),
                      _StatCard(title: 'Livrées aujourd\'hui', value: '94', icon: Symbols.local_shipping, color: Color(0xFF2E7D32)),
                      SizedBox(width: 10),
                      _StatCard(title: 'Stock Faible', value: '5', icon: Symbols.warning_amber_rounded, color: Color(0xFFE53935)),
                    ],
                  ),
                ),
              ),
            ),

            // --- Titre de Section ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  'MODULES DE GESTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),

            // --- Grille des Modules ---
            if (visibleTiles.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Aucun module disponible',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tile = visibleTiles[index];
                      return _MobileAdminTile(
                        tile: tile,
                        onTap: () => context.push(tile.route),
                      );
                    },
                    childCount: visibleTiles.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  static String _initialsOf(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'A';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }
}

class _AdminTileConfig {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Color color;
  final List<String> requiredPermissions;
  final String? badgeText;

  const _AdminTileConfig({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.color,
    required this.requiredPermissions,
    this.badgeText,
  });
}

class _MobileAdminTile extends StatelessWidget {
  final _AdminTileConfig tile;
  final VoidCallback onTap;

  const _MobileAdminTile({
    required this.tile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tile.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tile.icon, color: tile.color, size: 20),
                    ),
                    if (tile.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tile.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tile.badgeText!,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tile.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}