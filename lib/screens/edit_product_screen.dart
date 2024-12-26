import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class EditProductScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categories; // Seznam kategorií načtený z API
  final Product? product; // Produkt při editaci, null při vytváření nového produktu

  const EditProductScreen({
    super.key,
    required this.categories,
    this.product,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  String? _selectedCategoryId; // Vybraná kategorie
  String? _selectedTaxId; // Vybraná daňová sazba
  int _selectedColor = 1; // Výchozí barva
  bool _onSale = true; // Výchozí hodnota "na prodej"
  List<Map<String, dynamic>> _taxSettings = []; // Načtené sazby DPH

  final TextEditingController _nameController =
  TextEditingController(); // Pro název produktu
  final TextEditingController _priceController =
  TextEditingController(); // Pro cenu produktu
  final TextEditingController _skuController =
  TextEditingController(); // Pro SKU (editovatelné)
  final TextEditingController _codeController =
  TextEditingController(); // Pro kód produktu
  final TextEditingController _noteController =
  TextEditingController(); // Pro poznámku

  @override
  void initState() {
    super.initState();
    // Předvyplnění hodnot pro úpravů produktu
    if (widget.product != null) {
      _nameController.text = widget.product!.itemName;
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _skuController.text = widget.product!.sku ?? ''; // SKU, pokud existuje
      _codeController.text = widget.product!.code.toString(); // Code jako text
      _noteController.text = widget.product!.note ?? ''; // Note, pokud existuje
      _selectedCategoryId = widget.product!.categoryId;
      _selectedTaxId = widget.product!.taxId;
      _selectedColor = widget.product!.color;
      _onSale = widget.product!.onSale;
    }

    _loadTaxSettings(); // Načtení daňových sazeb
  }

  Future<void> _loadTaxSettings() async {
    const apiKey = 'pak-equeghBq1UtfHWfDqtO52SC9ascosA';
    try {
      final taxSettings = await ApiService.fetchTaxSettings(apiKey);
      setState(() {
        _taxSettings = taxSettings;
      });
    } catch (e) {
      print('Error loading tax settings: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _codeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('editProduct')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: localizations.translate('saveProduct'),
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(localizations.translate('productName'), _nameController),
              const SizedBox(height: 16),
              _buildTextField(localizations.translate('price'), _priceController, isNumber: true),
              const SizedBox(height: 16),
              _buildCategoryDropdown(localizations),
              const SizedBox(height: 16),
              _buildColorPickerRow(localizations),
              const SizedBox(height: 16),
              _buildOnSaleSwitch(localizations),
              const SizedBox(height: 16),
              _buildTextField(localizations.translate('sku'), _skuController),
              const SizedBox(height: 16),
              _buildTextField(localizations.translate('productCode'), _codeController, isNumber: true),
              const SizedBox(height: 16),
              _buildTaxDropdown(localizations),
              const SizedBox(height: 16),
              _buildTextField(localizations.translate('note'), _noteController, isMultiline: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: isMultiline ? null : 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: label,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.translate('category'), style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _selectedCategoryId,
          isExpanded: true,
          hint: Text(localizations.translate('selectCategory')),
          items: widget.categories.map((category) {
            return DropdownMenuItem<String>(
              value: category['categoryId'],
              child: Text(category['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildColorPickerRow(AppLocalizations localizations) {
    final colors = [
      Colors.green,
      Colors.lightBlue,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.brown.shade300,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.translate('color'), style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Zabrání overflow
          child: Row(
            children: List.generate(colors.length, (index) {
              final colorIndex = index + 1; // Barvy jsou číslovány od 1 do 8
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = colorIndex;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: _selectedColor == colorIndex
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxDropdown(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.translate('taxRate'), style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _selectedTaxId,
          isExpanded: true,
          hint: Text(localizations.translate('selectTaxRate')),
          items: _taxSettings.map((tax) {
            return DropdownMenuItem<String>(
              value: tax['taxId'],
              child: Text('${tax['name']} (${(tax['percent'] ?? 0) * 100}%)'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTaxId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOnSaleSwitch(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(localizations.translate('onSale'), style: const TextStyle(fontSize: 16)),
        Switch(
          value: _onSale,
          onChanged: (value) {
            setState(() {
              _onSale = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategoryId == null ||
        _selectedTaxId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('fillAllFields'))),
      );
      return;
    }

    final newProduct = Product(
      itemId: widget.product?.itemId ?? '',
      itemName: _nameController.text,
      price: double.parse(_priceController.text),
      sku: _skuController.text,
      code: int.tryParse(_codeController.text) ?? 0,
      note: _noteController.text,
      categoryId: _selectedCategoryId!,
      categoryName: widget.categories
        .firstWhere((c) => c['categoryId'] == _selectedCategoryId)['name'],
      currency: 'CZK',
      taxId: _selectedTaxId!,
      color: _selectedColor,
      onSale: _onSale,
    );

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (widget.product == null) {
      await productProvider.addProduct(newProduct);
    } else {
      await productProvider.editProduct(newProduct);
    }

    Navigator.of(context).pop();
  }
}


