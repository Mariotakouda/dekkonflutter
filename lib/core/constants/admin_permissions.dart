/// Codes de permissions utilisés côté admin, en miroir exact des
/// middlewares `permission:...` définis dans `routes/api_admin.php`
/// côté backend Laravel. Toute modification ici doit rester synchronisée
/// avec le backend.
class AdminPermissions {
  AdminPermissions._();

  // Employés / Rôles / Permissions
  static const employeesManage = 'employees.manage';
  static const rolesManage = 'roles.manage';
  static const permissionsManage = 'permissions.manage';

  // Catalogue
  static const categoriesManage = 'categories.manage';
  static const productsManage = 'products.manage';

  // Stock
  static const inventoryView = 'inventory.view';
  static const inventoryUpdate = 'inventory.update';
  static const stockMovementsView = 'stock_movements.view';

  // Commandes
  static const ordersView = 'orders.view';
  static const ordersConfirm = 'orders.confirm';
  static const ordersUpdate = 'orders.update';
  static const ordersCancel = 'orders.cancel';

  // Paiements
  static const paymentsView = 'payments.view';
  static const paymentsManage = 'payments.manage';

  // Livraisons / Livreurs
  static const deliveriesView = 'deliveries.view';
  static const deliveriesManage = 'deliveries.manage';
  static const driversManage = 'drivers.manage';

  // Promotions
  static const promotionsView = 'promotions.view';
  static const promotionsManage = 'promotions.manage';

  // Journal d'activité
  static const activityLogsView = 'activity_logs.view';
}