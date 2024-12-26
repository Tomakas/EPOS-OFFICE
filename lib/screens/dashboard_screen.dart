// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/receipt_provider.dart';
import '../models/product.dart'; // Přidáno
import '../l10n/app_localizations.dart';
import '../widgets/dashboard_widgets.dart' as widgets; // Prefix 'widgets'
import '../models/dashboard_widget_model.dart' as model; // Prefix 'model'
import '../services/utility_services.dart'; // Import StorageService
import 'package:uuid/uuid.dart'; // Pro generování unikátních ID

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<void> _fetchData;
  bool isEditMode = false; // Stav editačního režimu
  List<model.DashboardWidgetModel> widgetsList = []; // Seznam widgetů na dashboardu

  @override
  void initState() {
    super.initState();
    _fetchData = _loadData();
  }

  Future<void> _loadData() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final today = DateTime.now();

    // Nastavení dateRange na aktuální den
    receiptProvider.updateDateRange(
      DateTimeRange(
        start: DateTime(today.year, today.month, today.day),
        end: DateTime(today.year, today.month, today.day, 23, 59, 59),
      ),
    );

    // Načtení produktů před účtenkami
    await productProvider.fetchProducts(); // Ujistěte se, že máte tuto metodu implementovanou v ProductProvider

    // Načtení účtenek
    await receiptProvider.fetchReceipts();

    // Načtení widgetů z SharedPreferences
    List<model.DashboardWidgetModel> loadedWidgets =
    await StorageService.getDashboardWidgetsOrder();

    // Pokud není žádný uložený seznam, inicializujte výchozí widgety
    if (loadedWidgets.isEmpty) {
      loadedWidgets = [
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'summary'),
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'top_products'),
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'top_categories'), // Přidáno
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'hourly_graph'),
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'payment_pie_chart'),
        model.DashboardWidgetModel(id: const Uuid().v4(), type: 'today_revenue'),
      ];
      await StorageService.saveDashboardWidgetsOrder(loadedWidgets);
    }

    setState(() {
      widgetsList = loadedWidgets;
    });
  }

  Future<void> _saveWidgets() async {
    await StorageService.saveDashboardWidgetsOrder(widgetsList);
  }

  void _enterEditMode() {
    setState(() {
      isEditMode = true;
    });
  }

  void _exitEditMode() {
    setState(() {
      isEditMode = false;
    });
  }

  void _addNewWidget(String type) {
    setState(() {
      widgetsList.add(model.DashboardWidgetModel(id: const Uuid().v4(), type: type));
    });
    _saveWidgets();
  }

  void _removeWidget(String id) {
    setState(() {
      widgetsList.removeWhere((widget) => widget.id == id);
    });
    _saveWidgets();
  }

  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedType;
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('addWidget')),
          content: DropdownButtonFormField<String>(
            value: selectedType,
            items: [
              DropdownMenuItem(
                value: 'summary',
                child: Text(AppLocalizations.of(context)!.translate('summary')),
              ),
              DropdownMenuItem(
                value: 'top_products',
                child: Text(AppLocalizations.of(context)!.translate('topProducts')),
              ),
              DropdownMenuItem(
                value: 'top_categories',
                child: Text(AppLocalizations.of(context)!.translate('topCategories')),
              ),
              DropdownMenuItem(
                value: 'hourly_graph',
                child: Text(AppLocalizations.of(context)!.translate('hourlyGraph')),
              ),
              DropdownMenuItem(
                value: 'payment_pie_chart',
                child: Text(AppLocalizations.of(context)!.translate('paymentPieChart')),
              ),
              DropdownMenuItem(
                value: 'today_revenue',
                child: Text(AppLocalizations.of(context)!.translate('todayRevenue')),
              ),
            ],
            onChanged: (value) {
              selectedType = value;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.translate('selectWidgetType'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zavřít dialog
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                if (selectedType != null) {
                  _addNewWidget(selectedType!);
                  Navigator.of(context).pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.translate('add')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context, AppLocalizations localizations) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);
    final receipts = receiptProvider.receipts;

    final int todayReceiptsCount = receipts.length;
    final double todaySales = receipts.fold(
      0.0,
          (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
    );

    final Map<String, Map<String, dynamic>> productData = {};
    for (var receipt in receipts) {
      for (var item in receipt['items']) {
        if (!productData.containsKey(item['text'])) {
          productData[item['text']] = {
            'name': item['text'],
            'quantity': 0.0,
            'revenue': 0.0,
          };
        }
        productData[item['text']]!['quantity'] +=
            (item['quantity'] as num).toDouble();
        productData[item['text']]!['revenue'] +=
            (item['priceToPay'] as num).toDouble();
      }
    }

    final topProducts = productData.values.toList()
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));
    final displayedTopProducts = topProducts.take(5).toList();

    return ReorderableListView(
      padding: const EdgeInsets.all(16.0),
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4.0,
          color: Colors.transparent,
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = widgetsList.removeAt(oldIndex);
          widgetsList.insert(newIndex, item);
        });
        _saveWidgets();
      },
      children: [
        for (final widgetModel in widgetsList)
          GestureDetector(
            key: ValueKey(widgetModel.id),
            onLongPress: isEditMode
                ? null
                : () {
              setState(() {
                if (widgetModel.type == 'summary') {
                  // Například: zobrazit detail summary
                }
                // Přidejte další logiku pro různé typy widgetů
              });
            },
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isEditMode ? Colors.black : Colors.grey,
                      width: isEditMode ? 2 : 1,
                    ),
                    boxShadow: isEditMode
                        ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(4, 8),
                        spreadRadius: 10,
                      ),
                    ]
                        : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildWidgetContent(widgetModel.type, receiptProvider, localizations),
                  ),
                ),
                if (isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 34),
                          onPressed: () => _removeWidget(widgetModel.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWidgetContent(
      String type, ReceiptProvider receiptProvider, AppLocalizations localizations) {
    switch (type) {
      case 'summary':
        return widgets.buildSummaryBlock(
          context,
          '${receiptProvider.receipts.length}',
          isEditMode: isEditMode,
        );
      case 'top_products':
        final Map<String, Map<String, dynamic>> productData = {};
        for (var receipt in receiptProvider.receipts) {
          for (var item in receipt['items']) {
            if (!productData.containsKey(item['text'])) {
              productData[item['text']] = {
                'name': item['text'],
                'quantity': 0.0,
                'revenue': 0.0,
              };
            }
            productData[item['text']]!['quantity'] +=
                (item['quantity'] as num).toDouble();
            productData[item['text']]!['revenue'] +=
                (item['priceToPay'] as num).toDouble();
          }
        }

        final topProducts = productData.values.toList()
          ..sort((a, b) => b['revenue'].compareTo(a['revenue']));
        final displayedTopProducts = topProducts.take(5).toList();

        return widgets.buildTopProductsTable(context, displayedTopProducts);
      case 'top_categories': // Přidáno
        final List<Map<String, dynamic>> topCategories = _getTopCategories(receiptProvider);
        return widgets.buildTopCategoriesTable(context, topCategories);
      case 'hourly_graph':
        return widgets.buildHourlyRevenueChart(context, receiptProvider);
      case 'payment_pie_chart':
        return widgets.buildDynamicPieChart(context, receiptProvider, localizations);
      case 'today_revenue':
        final double todayRevenue = receiptProvider.receipts.fold(
          0.0,
              (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
        );
        return widgets.buildTodayRevenueBlock(context, todayRevenue, isEditMode: isEditMode);

      default:
        return const Text('Neznámý typ widgetu');
    }
  }

  // Přidání Metody _getTopCategories
  List<Map<String, dynamic>> _getTopCategories(ReceiptProvider receiptProvider) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    Map<String, Map<String, dynamic>> categoryMap = {};

    for (var receipt in receiptProvider.receipts) {
      if (receipt['items'] != null && receipt['items'] is List) {
        for (var item in receipt['items']) {
          String productName = item['text'];
          Product? product = productProvider.getProductByName(productName);

          // Získání kategorie produktu
          String category = product?.categoryName ?? 'Uncategorized'; // Upravte podle vaší struktury produktu

          // Debug: Vytisknout kategorii, množství a cenu položky
          print('Processing item: $productName, Category: $category, Quantity: ${item['quantity']}, Price: ${item['itemPrice']}');

          // Změna typu z int na double pro quantity a price
          double quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          double price = (item['itemPrice'] as num?)?.toDouble() ?? 0.0;
          double revenue = quantity * price;

          if (categoryMap.containsKey(category)) {
            categoryMap[category]!['quantity'] += quantity;
            categoryMap[category]!['revenue'] += revenue;
          } else {
            categoryMap[category] = {
              'name': category,
              'quantity': quantity,
              'revenue': revenue,
            };
          }
        }
      }
    }

    // Debug: Vytisknout agregovaná data kategorií
    print('Aggregated Categories:');
    categoryMap.forEach((key, value) {
      print('Category: $key, Quantity: ${value['quantity']}, Revenue: ${value['revenue']}');
    });

    // Převést mapu na list a seřadit podle tržby sestupně
    List<Map<String, dynamic>> sortedCategories = categoryMap.values.toList()
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));

    // Vezmeme pouze top 5
    List<Map<String, dynamic>> topCategories = sortedCategories.take(5).toList();

    // Debug: Vytisknout top 5 kategorií
    print('Top 5 Categories:');
    topCategories.forEach((category) {
      print('Name: ${category['name']}, Quantity: ${category['quantity']}, Revenue: ${category['revenue']}');
    });

    return topCategories;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('dashboardTitle'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[850],
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Upravit dashboard',
              onPressed: _enterEditMode,
            ),
          if (isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              tooltip: 'Ukončit úpravy',
              onPressed: _exitEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Přidat nový prvek',
              onPressed: _showAddWidgetDialog,
            ),
          ]
        ],
      ),
      body: FutureBuilder<void>(
        future: _fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '${localizations.translate('errorLoadingData')}: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return _buildDashboardContent(context, localizations);
          }
        },
      ),
    );
  }
}
