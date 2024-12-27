//lib/widgets/product_widget.dart


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/edit_product_screen.dart';
import '../l10n/app_localizations.dart';

/// Pokud nemáte nikde definovanou mapu productColors, můžete ji sem přidat např.:
/// const Map<int, Color> productColors = {
///   1: Colors.green,
///   2: Colors.lightBlue,
///   3: Colors.blue,
///   4: Colors.yellow,
///   5: Colors.orange,
///   6: Colors.purple,
///   7: Colors.red,
///   8: Color(0xFF8B4513), // hnědá
/// };

class ProductWidget extends StatefulWidget {
  final Product product;
  final List<Map<String, dynamic>> categories;
  final double? stockQuantity;    // Množství na skladě, může být null
  final bool isExpanded;          // Indikace rozbalení widgetu
  final VoidCallback onExpand;    // Akce při kliknutí na "záhlaví" widgetu

  const ProductWidget({
    super.key,
    required this.product,
    required this.categories,
    this.stockQuantity,
    required this.isExpanded,
    required this.onExpand,
  });

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  late AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    localizations = AppLocalizations.of(context)!;

    // Najdeme jméno kategorie - pokud nenajdeme, zobrazíme "Neznámá kategorie"
    final categoryName = widget.categories.firstWhere(
          (cat) => cat['categoryId'] == widget.product.categoryId,
      orElse: () => {'name': localizations.translate("unknownCategory")},
    )['name'];

    // Formát pro cenu a sklad (CZ, 2 desetinná místa, bez symbolu)
    final numberFormat = NumberFormat.currency(
      locale: 'cs_CZ',
      symbol: '',
      decimalDigits: 2,
    );

    // Barva proužku dle product.color (1-8)
    final color = productColors[widget.product.color] ?? Colors.grey;

    return GestureDetector(
      onTap: widget.onExpand, // Kliknutí → rozbalit/sbalit detail
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Stack(
            children: [
              // Barevný svislý proužek vlevo
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 5,
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(left: 13.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Horní řádek: Jméno, kategorie, cena
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Levá část
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Jméno produktu
                              Text(
                                widget.product.itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  // Pokud onSale = false, přeškrtneme
                                  decoration: widget.product.onSale
                                      ? TextDecoration.none
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Kategorie
                              Text(
                                '${localizations.translate("category")}: $categoryName',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              // Cena
                              Text(
                                '${localizations.translate("price")}: '
                                    '${numberFormat.format(widget.product.price)} Kč',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        // Pravá část - sklad (pokud je stockQuantity != null)
                        if (widget.stockQuantity != null)
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.center,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${localizations.translate("stock")}:\n',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextSpan(
                                      text: numberFormat.format(widget.stockQuantity),
                                      style: TextStyle(
                                        color: (widget.stockQuantity! <= 0)
                                            ? Colors.red
                                            : Colors.black,
                                        fontWeight: (widget.stockQuantity! < 0)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Rozbalovací část (tlačítka) - pomocí AnimatedCrossFade
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: widget.isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            // Tlačítka: Edit, Copy, Delete
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // EDIT
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: localizations.translate("edit"),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditProductScreen(
                                            categories: widget.categories,
                                            product: widget.product,
                                            // isCopy: false (default), aby šlo o úpravu
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // COPY (duplikace)
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.green),
                                    tooltip: localizations.translate("copy"),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditProductScreen(
                                            categories: widget.categories,
                                            product: widget.product,
                                            isCopy: true, // Zde je klíč
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: localizations.translate("delete"),
                                    onPressed: () {
                                      _showDeleteConfirmation(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Tlačítko pro změnu skladového stavu (pokud chcete)
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.exposure, color: Colors.orange),
                                    tooltip: localizations.translate("changeStock"),
                                    onPressed: () {
                                      _showStockChangeDialog(
                                        context,
                                        title: localizations.translate("changeStockTitle"),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog pro úpravu stavu skladu (jen příklad – není implementováno volání API).
  void _showStockChangeDialog(BuildContext context, {required String title}) {
    int currentValue = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() => currentValue--);
                    },
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: TextEditingController(
                        text: currentValue.toString(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          currentValue = parsed;
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => currentValue++);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Zavřít dialog
                  },
                  child: Text(localizations.translate("cancel")),
                ),
                TextButton(
                  onPressed: () {
                    // Zde případně volání API pro update skladu
                    print('$title: $currentValue');
                    Navigator.of(context).pop();
                  },
                  child: Text(localizations.translate("confirm")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Potvrzovací dialog pro smazání produktu
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.translate("deleteProduct")),
          content: Text(
            '${localizations.translate("confirmDelete")} "${widget.product.itemName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Zavřít dialog bez smazání
              },
              child: Text(localizations.translate("cancel")),
            ),
            TextButton(
              onPressed: () async {
                // Zavřeme dialog
                Navigator.of(context).pop();

                // Smažeme produkt
                final productProvider =
                Provider.of<ProductProvider>(context, listen: false);
                try {
                  await productProvider.deleteProduct(widget.product.itemId);
                  // Tím dojde i k fetchProducts() (dle kódu v ProductProvider),
                  // a ProductListScreen se díky addListener automaticky zaktualizuje.

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${localizations.translate("productDeleted")}: ${widget.product.itemName}',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${localizations.translate("deleteError")}: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(localizations.translate("delete")),
            ),
          ],
        );
      },
    );
  }
}
