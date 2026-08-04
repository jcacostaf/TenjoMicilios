import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api_config.dart';
import '../../core/models/product.dart';
import '../../core/services/api_service.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

class ProductFormScreen extends StatefulWidget {
  final int storeId;
  final Product? product;

  const ProductFormScreen({super.key, required this.storeId, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _imagePicker = ImagePicker();

  static const double _priceStep = 500;
  static const double _minPrice = _priceStep;
  static const double _maxPrice = 100000;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late double _price;
  late bool _isActive;
  String? _existingImageUrl;
  Uint8List? _newImageBytes;
  String? _newImageName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _price = (product?.price ?? _minPrice).clamp(_minPrice, _maxPrice);
    _isActive = product?.isActive ?? true;
    _existingImageUrl = product?.imageUrl;
  }

  Future<void> _pickImage() async {
    // maxWidth/imageQuality mantienen la foto en un tamano razonable antes de subirla.
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _newImageBytes = bytes;
      _newImageName = picked.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id ?? 0,
      storeId: widget.storeId,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      price: _price,
      isActive: _isActive,
      imageUrl: _existingImageUrl,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
    );

    int productId;
    if (widget.product == null) {
      final created = await _api.createProduct(widget.storeId, product);
      productId = created.id;
    } else {
      await _api.updateProduct(product);
      productId = product.id;
    }

    if (_newImageBytes != null) {
      await _api.uploadProductPhoto(productId, _newImageBytes!, _newImageName ?? 'photo.jpg');
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar producto' : 'Nuevo producto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePreview(),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: Text(_newImageBytes != null || _existingImageUrl != null
                    ? 'Cambiar foto'
                    : 'Agregar foto'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Precio: ${_currencyFormat.format(_price)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Slider(
                value: _price,
                min: _minPrice,
                max: _maxPrice,
                divisions: ((_maxPrice - _minPrice) / _priceStep).round(),
                label: _currencyFormat.format(_price),
                onChanged: (value) => setState(() => _price = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isActive ? Colors.green.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isActive ? Colors.green : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      'Activo en el catálogo',
                      style: TextStyle(
                        color: _isActive ? Colors.green.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando...' : (isEditing ? 'Actualizar' : 'Guardar')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_newImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_newImageBytes!, height: 160, fit: BoxFit.cover),
      );
    }
    if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '$apiBaseUrl$_existingImageUrl',
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}
