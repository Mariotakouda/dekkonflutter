import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/admin_permissions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_employee_model.dart';
import '../providers/admin_employees_provider.dart';
import 'admin_employee_form_screen.dart';
import 'admin_roles_screen.dart';

class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminEmployeeListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminEmployeeListProvider);
    final permissions = ref.watch(employeePermissionsProvider);
    final canManageRoles = permissions.has(AdminPermissions.rolesManage);
    final canManageEmployees = permissions.has(AdminPermissions.employeesManage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employés'),
        actions: [
          if (canManageRoles)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Gérer les rôles',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminRolesScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: canManageEmployees
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AdminEmployeeFormScreen()),
                );
                if (created == true) ref.read(adminEmployeeListProvider.notifier).loadFirstPage();
              },
              child: const Icon(Icons.person_add_outlined, color: Colors.white),
            )
          : null,
      body: state.isLoading
          ? const LoadingIndicator()
          : state.error != null
              ? ErrorView(
                  message: 'Impossible de charger les employés.',
                  onRetry: () => ref.read(adminEmployeeListProvider.notifier).loadFirstPage(),
                )
              : state.employees.isEmpty
                  ? const EmptyState(icon: Icons.people_outline, title: 'Aucun employé')
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.employees.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _EmployeeTile(employee: state.employees[index]),
                    ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  final AdminEmployeeModel employee;

  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = employee.status == 'ACTIVE';
    final canManageEmployees = ref.watch(employeePermissionsProvider).has(AdminPermissions.employeesManage);

    return InkWell(
      onTap: !canManageEmployees
          ? null
          : () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => AdminEmployeeFormScreen(employeeId: employee.id)),
              );
              if (updated == true) ref.read(adminEmployeeListProvider.notifier).loadFirstPage();
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.ambientShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                employee.firstName.isNotEmpty ? employee.firstName[0].toUpperCase() : '?',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.fullName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  Text('${employee.employeeNumber} · ${employee.roleName ?? 'Sans rôle'}', style: AppTextStyles.caption),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Actif' : employee.status,
                style: AppTextStyles.caption.copyWith(color: isActive ? AppColors.primary : AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}