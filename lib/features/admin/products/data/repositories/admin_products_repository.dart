import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/error_handler.dart';
import '../models/admin_product_model.dart';

/// Image en attente d'upload dans le flux de création tout-en-un.
class PendingProductImage {
  final XFile file;
  final bool isPrimary;
  final String? altText;

  PendingProductImage({required this.file, this.isPrimary = false, this.altText});
}

class AdminProductsRepository {
  final Dio _dio;

  AdminProductsRepository(this._dio);

  Future<AdminPaginatedProducts<AdminProductModel>> getProducts({
    String? search,
    String? categoryId,
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.adminProducts, queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'category_id': ?categoryId,
        'status': ?status,
        'page': page,
      });

      final data = response.data['data'] as List;
      final meta = response.data['meta'] as Map<String, dynamic>;

      return AdminPaginatedProducts(
        items: data.map((p) => AdminProductModel.fromJson(p as Map<String, dynamic>)).toList(),
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminProductModel> getProduct(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.adminProducts}/$id');
      return AdminProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.adminProducts, data: data);
      return AdminProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Crée un produit complet en un seul appel : produit + attributs de catégorie
  /// + variantes (avec stock initial) + images, dans une seule requête multipart.
  /// Correspond à POST /admin/products côté Laravel (CreateProductWithVariantsAction).
  Future<AdminProductModel> createProductFull({
    required Map<String, dynamic> productFields,
    Map<String, dynamic> attributes = const {},
    List<Map<String, dynamic>> variants = const [],
    List<PendingProductImage> images = const [],
  }) async {
    try {
      final formData = FormData();

      productFields.forEach((key, value) {
        if (value == null) return;
        _appendField(formData, key, value);
      });

      attributes.forEach((key, value) {
        if (value == null) return;
        _appendField(formData, 'attributes[$key]', value);
      });

      for (var i = 0; i < variants.length; i++) {
        variants[i].forEach((key, value) {
          if (value == null) return;
          _appendField(formData, 'variants[$i][$key]', value);
        });
      }

      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final bytes = await image.file.readAsBytes();

        String filename = image.file.name;
        if (filename.isEmpty || !filename.contains('.')) {
          filename = 'upload_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        }

        formData.files.add(MapEntry(
          'images[$i][file]',
          MultipartFile.fromBytes(bytes, filename: filename, contentType: _resolveImageContentType(filename)),
        ));
        formData.fields.add(MapEntry('images[$i][is_primary]', image.isPrimary ? '1' : '0'));
        if (image.altText != null && image.altText!.isNotEmpty) {
          formData.fields.add(MapEntry('images[$i][alt_text]', image.altText!));
        }
      }

      final response = await _dio.post(
        ApiConstants.adminProducts,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return AdminProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Ajoute un champ (scalaire, booléen ou liste) à un FormData en notation
  /// à crochets compatible avec la validation Laravel (ex: 'variants[0][sku]').
  void _appendField(FormData formData, String key, dynamic value) {
    if (value is bool) {
      formData.fields.add(MapEntry(key, value ? '1' : '0'));
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _appendField(formData, '$key[$i]', value[i]);
      }
    } else {
      formData.fields.add(MapEntry(key, value.toString()));
    }
  }

  Future<AdminProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.adminProducts}/$id', data: data);
      return AdminProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminProducts}/$id');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<AdminCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.adminCategories);
      final data = response.data['data'] as List;
      return data.map((c) => AdminCategoryModel.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // --- Images ---

  /// Détermine le Content-Type correct à partir de l'extension du fichier.
  /// Sans ça, Laravel reçoit souvent 'application/octet-stream' et rejette
  /// la validation `'image'` avec "Le champ image doit être une image."
  MediaType _resolveImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    // JPEG par défaut (cas le plus fréquent, y compris .jpeg/.jpg)
    return MediaType('image', 'jpeg');
  }

  Future<void> uploadImage(String productId, XFile file, {bool isPrimary = false}) async {
    try {
      final bytes = await file.readAsBytes();

      // image_picker sur le web renvoie parfois un name vide ou sans extension —
      // on force un nom de fichier valide avec extension pour que Laravel détecte le type.
      String filename = file.name;
      if (filename.isEmpty || !filename.contains('.')) {
        filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final contentType = _resolveImageContentType(filename);

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: contentType,
        ),
        // Laravel attend une valeur booléenne valide.
        // 1 = true, 0 = false.
        'is_primary': isPrimary ? '1' : '0',
      });

      await _dio.post(
        '${ApiConstants.adminProducts}/$productId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteImage(String productId, String imageId) async {
    try {
      await _dio.delete('${ApiConstants.adminProducts}/$productId/images/$imageId');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> setPrimaryImage(String productId, String imageId) async {
    try {
      await _dio.patch('${ApiConstants.adminProducts}/$productId/images/$imageId/primary');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // --- Variantes ---

  Future<AdminProductVariantModel> createVariant(String productId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('${ApiConstants.adminProducts}/$productId/variants', data: data);
      return AdminProductVariantModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<AdminProductVariantModel> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.adminProducts}/$productId/variants/$variantId', data: data);
      return AdminProductVariantModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    try {
      await _dio.delete('${ApiConstants.adminProducts}/$productId/variants/$variantId');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // --- Stock (NOUVEAU) ---

  /// Ajuste le stock d'une variante. Seul endpoint qui modifie réellement
  /// l'inventaire côté Laravel : POST /admin/inventory/{variant}/adjust.
  /// [type] doit être 'IN' (entrée), 'OUT' (sortie) ou 'ADJUSTMENT' (valeur absolue).
  Future<void> adjustStock(
    String variantId, {
    required String type,
    required int quantity,
    String? reason,
  }) async {
    try {
      await _dio.post('${ApiConstants.adminInventory}/$variantId/adjust', data: {
        'type': type,
        'quantity': quantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}