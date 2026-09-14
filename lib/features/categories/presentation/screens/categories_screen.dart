import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/models/categories_model.dart';
import '../providers/categories_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class CategoriesScreen extends ConsumerWidget {
  /// Titre de l'écran. Par défaut 'Catégories' (niveau racine).
  final String? title;
  /// Sous-catégories déjà chargées (navigation depuis une catégorie parente) —
  /// évite un nouvel appel API puisque l'arbre complet est déjà en mémoire.
  final List<CategoryModel>? categories;
  /// Id de la catégorie parente, pour proposer "Voir tous les produits" de ce rayon.
  final String? parentId;
  final String? parentName;

  const CategoriesScreen({super.key, this.title, this.categories, this.parentId, this.parentName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providedCategories = categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Dégradé orange -> blanc commun à toutes les pages principales.
            GradientHeader(
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        title ?? 'Catégories',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // équilibre visuel avec la flèche retour
                  ],
                ),
              ),
            ),
            Expanded(
              child: providedCategories != null
                  ? _CategoriesBody(categories: providedCategories, parentId: parentId, parentName: parentName)
                  : Builder(
                      builder: (context) {
                        final categoriesAsync = ref.watch(categoriesProvider);
                        return categoriesAsync.when(
                          loading: () => const LoadingIndicator(),
                          error: (e, _) => ErrorView(
                            message: 'Impossible de charger les catégories.',
                            onRetry: () => ref.invalidate(categoriesProvider),
                          ),
                          data: (cats) => cats.isEmpty
                              ? const EmptyState(icon: Symbols.category, title: 'Aucune catégorie')
                              : _CategoriesBody(categories: cats, parentId: null, parentName: null),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesBody extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? parentId;
  final String? parentName;

  const _CategoriesBody({required this.categories, this.parentId, this.parentName});

  @override
  State<_CategoriesBody> createState() => _CategoriesBodyState();
}

class _CategoriesBodyState extends State<_CategoriesBody> {
  final _searchController = TextEditingController();
  final Set<String> _expandedIds = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage 100% local sur les catégories déjà en mémoire (pas d'appel API).
    final filtered = _query.isEmpty
        ? widget.categories
        : widget.categories
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        if (widget.parentId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/products?category_id=${widget.parentId}'),
                child: Text('Voir tous les produits — ${widget.parentName ?? ''}'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Symbols.search, color: AppColors.outline, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une catégorie...',
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Symbols.search_off_rounded,
                  title: 'Aucune catégorie trouvée',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    return _CategoryAccordionTile(
                      category: category,
                      expanded: _expandedIds.contains(category.id),
                      onToggle: () => setState(() {
                        if (_expandedIds.contains(category.id)) {
                          _expandedIds.remove(category.id);
                        } else {
                          _expandedIds.add(category.id);
                        }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CategoryAccordionTile extends StatelessWidget {
  final CategoryModel category;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryAccordionTile({
    required this.category,
    required this.expanded,
    required this.onToggle,
  });

  bool get _hasChildren => category.children.isNotEmpty;

  void _openSubCategory(BuildContext context, CategoryModel sub) {
    if (sub.children.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoriesScreen(
            title: sub.name,
            categories: sub.children,
            parentId: sub.id,
            parentName: sub.name,
          ),
        ),
      );
    } else {
      context.push('/products?category_id=${sub.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _hasChildren
                ? onToggle
                : () => context.push('/products?category_id=${category.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: category.imageUrl != null
                              ? CachedNetworkImage(imageUrl: category.imageUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.surface,
                                  child: const Icon(Symbols.category, color: AppColors.primaryDark),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 3, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.h4.copyWith(color: AppColors.secondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_hasChildren) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${category.children.length} sous-catégorie(s)',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_hasChildren)
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Symbols.expand_more, color: AppColors.primaryDark),
                    )
                  else
                    const Icon(Symbols.chevron_right, color: AppColors.textDisabled),
                ],
              ),
            ),
          ),
          if (_hasChildren)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
                child: Column(
                  children: category.children
                      .map((sub) => InkWell(
                            onTap: () => _openSubCategory(context, sub),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: AppColors.divider, width: 2)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(sub.name, style: AppTextStyles.bodyMedium),
                                    ),
                                    const Icon(Symbols.chevron_right, size: 18, color: AppColors.textDisabled),
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}