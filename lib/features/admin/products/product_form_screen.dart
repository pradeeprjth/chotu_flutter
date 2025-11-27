import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/catalog_service.dart';
import '../../../core/services/admin_service.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import 'providers/admin_products_provider.dart';

/// Provider for loading a single product for editing
final productDetailProvider = FutureProvider.autoDispose.family<AdminProduct?, String>((ref, productId) async {
  if (productId.isEmpty) return null;
  final adminService = ref.watch(adminServiceProvider);
  final result = await adminService.getProducts(search: null, page: 1, limit: 1);
  // Find the product by ID
  for (final product in result.products) {
    if (product.id == productId) return product;
  }
  // If not found in first page, fetch directly
  final allProducts = await adminService.getProducts(page: 1, limit: 100);
  return allProducts.products.firstWhere(
    (p) => p.id == productId,
    orElse: () => throw Exception('Product not found'),
  );
});

/// Provider for loading categories
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return catalogService.getCategories();
});

/// Form state for the product form
class ProductFormState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<String> imageUrls; // Existing image URLs
  final List<XFile> newImages; // Newly selected images

  ProductFormState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.imageUrls = const [],
    this.newImages = const [],
  });

  ProductFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<String>? imageUrls,
    List<XFile>? newImages,
    bool clearError = false,
  }) {
    return ProductFormState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      imageUrls: imageUrls ?? this.imageUrls,
      newImages: newImages ?? this.newImages,
    );
  }
}

/// Notifier for the product form
class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(ProductFormState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setSaving(bool saving) {
    state = state.copyWith(isSaving: saving);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, clearError: error == null);
  }

  void setImageUrls(List<String> urls) {
    state = state.copyWith(imageUrls: urls);
  }

  void addNewImage(XFile image) {
    state = state.copyWith(newImages: [...state.newImages, image]);
  }

  void removeNewImage(int index) {
    final newImages = [...state.newImages];
    newImages.removeAt(index);
    state = state.copyWith(newImages: newImages);
  }

  void removeExistingImage(int index) {
    final imageUrls = [...state.imageUrls];
    imageUrls.removeAt(index);
    state = state.copyWith(imageUrls: imageUrls);
  }
}

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isInitialized = false;

  bool get isEditMode => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _initializeForm(AdminProduct product) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toString();
    _mrpController.text = product.mrp.toString();
    _unitController.text = product.unit;
    _selectedCategoryId = product.category['_id']?.toString() ?? product.category['id']?.toString();
    _isActive = product.isActive;

    // Set existing images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productFormProvider.notifier).setImageUrls(product.images);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final formState = ref.watch(productFormProvider);

    // Load product for editing
    if (isEditMode) {
      final productAsync = ref.watch(productDetailProvider(widget.productId!));
      productAsync.whenData((product) {
        if (product != null) {
          _initializeForm(product);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Product' : 'Add Product'),
        actions: [
          if (isEditMode)
            IconButton(
              icon: Icon(_isActive ? Icons.visibility : Icons.visibility_off),
              tooltip: _isActive ? 'Product is Active' : 'Product is Inactive',
              onPressed: () {
                setState(() {
                  _isActive = !_isActive;
                });
              },
            ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error.toString()),
        data: (categories) => _buildForm(categories, formState),
      ),
      bottomNavigationBar: _buildBottomBar(formState),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load data', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(categoriesProvider);
              if (isEditMode) {
                ref.invalidate(productDetailProvider(widget.productId!));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(List<Category> categories, ProductFormState formState) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Product Images Section
          _buildImagesSection(formState),
          const SizedBox(height: AppSpacing.xl),

          // Product Name
          _buildTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'Enter product name',
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product name is required';
              }
              if (value.trim().length < 2) {
                return 'Product name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter product description (optional)',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category Dropdown
          _buildCategoryDropdown(categories),
          const SizedBox(height: AppSpacing.lg),

          // Price and MRP Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Selling Price',
                  hint: '0.00',
                  prefix: '\u20B9 ',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _mrpController,
                  label: 'MRP',
                  hint: '0.00',
                  prefix: '\u20B9 ',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'MRP is required';
                    }
                    final mrp = double.tryParse(value);
                    if (mrp == null || mrp <= 0) {
                      return 'Invalid MRP';
                    }
                    final price = double.tryParse(_priceController.text) ?? 0;
                    if (mrp < price) {
                      return 'MRP cannot be less than price';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Unit and Stock Row
          Row(
            children: [
              Expanded(
                child: _buildUnitField(),
              ),
              if (!isEditMode) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: 'Initial Stock',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Status Toggle (Edit mode only)
          if (isEditMode)
            _buildStatusToggle(),

          // Error Message
          if (formState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Extra space for bottom bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildImagesSection(ProductFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Images', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Add up to 5 images. First image will be the main product image.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Existing images
              ...formState.imageUrls.asMap().entries.map((entry) {
                return _buildImageCard(
                  imageUrl: entry.value,
                  onRemove: () {
                    ref.read(productFormProvider.notifier).removeExistingImage(entry.key);
                  },
                );
              }),

              // New images
              ...formState.newImages.asMap().entries.map((entry) {
                return _buildImageCard(
                  file: File(entry.value.path),
                  onRemove: () {
                    ref.read(productFormProvider.notifier).removeNewImage(entry.key);
                  },
                );
              }),

              // Add image button
              if (formState.imageUrls.length + formState.newImages.length < 5)
                _buildAddImageButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard({String? imageUrl, File? file, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.grey100,
                      child: const Icon(Icons.broken_image, color: AppColors.grey400),
                    ),
                  )
                : Image.file(
                    file!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
          color: AppColors.primarySurface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add Image',
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        ref.read(productFormProvider.notifier).addNewImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTypography.titleSmall),
            if (required)
              Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Category', style: AppTypography.titleSmall),
            Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            hintText: 'Select a category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          items: categories
              .where((c) => c.isActive)
              .map((category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUnitField() {
    final units = ['1 kg', '500 g', '250 g', '1 L', '500 ml', '1 pc', '1 pack', '1 dozen'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Unit', style: AppTypography.titleSmall),
            Text(' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _unitController.text),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return units;
            }
            return units.where((unit) =>
                unit.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (selection) {
            _unitController.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            // Sync with our controller
            controller.text = _unitController.text;
            controller.addListener(() {
              _unitController.text = controller.text;
            });

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'e.g., 1 kg, 500 ml',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Unit is required';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _isActive ? AppColors.successLight : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isActive ? AppColors.success : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle : Icons.cancel,
            color: _isActive ? AppColors.success : AppColors.grey500,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Status',
                  style: AppTypography.titleSmall,
                ),
                Text(
                  _isActive
                      ? 'Product is visible to customers'
                      : 'Product is hidden from customers',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeTrackColor: AppColors.successLight,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductFormState formState) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: formState.isSaving ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: formState.isSaving ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: formState.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEditMode ? 'Update Product' : 'Create Product'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formNotifier = ref.read(productFormProvider.notifier);
    final formState = ref.read(productFormProvider);

    formNotifier.setSaving(true);
    formNotifier.setError(null);

    try {
      final adminService = ref.read(adminServiceProvider);

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final mrp = double.parse(_mrpController.text);
      final unit = _unitController.text.trim();
      final stock = int.tryParse(_stockController.text) ?? 0;

      if (isEditMode) {
        // Update existing product
        final updates = <String, dynamic>{
          'name': name,
          'description': description.isEmpty ? null : description,
          'category': _selectedCategoryId,
          'price': price,
          'mrp': mrp,
          'unit': unit,
          'isActive': _isActive,
          'images': formState.imageUrls,
        };

        await adminService.updateProduct(widget.productId!, updates);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        // Create new product
        await adminService.createProduct(
          name: name,
          description: description.isEmpty ? null : description,
          category: _selectedCategoryId!,
          price: price,
          mrp: mrp,
          unit: unit,
          images: formState.imageUrls,
          initialStock: stock > 0 ? stock : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }

      // Refresh products list
      ref.invalidate(adminProductsProvider);
    } catch (e) {
      formNotifier.setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      formNotifier.setSaving(false);
    }
  }
}
