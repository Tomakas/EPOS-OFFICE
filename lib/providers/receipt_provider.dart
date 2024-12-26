import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/utility_services.dart';

class ReceiptProvider extends ChangeNotifier {
  String? apiKey;
  List receipts = [];
  bool isLoading = false;

  // Rozsah dat pro filtrování
  DateTimeRange? dateRange;

  // Filtrační parametry
  bool showCash = true;
  bool showCard = true;
  bool showBank = true;
  bool showOther = true;
  bool showWithDiscount = false;

  ReceiptProvider(this.apiKey);

  /// Celkový příjem z účtenek
  double get totalRevenue {
    return receipts.fold(
        0.0, (sum, receipt) => sum + (receipt['total'] as num).toDouble());
  }

  /// Průměrná hodnota účtenky
  double get averageValue {
    return receipts.isNotEmpty ? totalRevenue / receipts.length : 0.0;
  }

  /// Načtení účtenek z API
  Future<void> fetchReceipts() async {
    isLoading = true;
    notifyListeners();

    try {
      // Dynamické načtení aktuálního API klíče
      apiKey = await StorageService.getApiKey();
      if (apiKey == null || apiKey!.isEmpty) {
        print('Chyba: API klíč není zadán.');
        return;
      }

      // Získání rozsahu dat
      String dateFrom = dateRange != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.start)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      String dateTo = dateRange != null
          ? DateFormat('yyyy-MM-dd').format(dateRange!.end)
          : DateFormat('yyyy-MM-dd').format(DateTime.now());

      print(
          'Načítání účtenek s API klíčem: $apiKey, datum od: $dateFrom, do: $dateTo');

      List allReceipts =
          await ApiService.fetchReceipts(apiKey!, dateFrom, dateTo, 500);

      print('API odpověď: $allReceipts');

      // Filtrace účtenek
      receipts = allReceipts.where((receipt) {
        String paymentType = receipt['paymentType'];
        bool matchesPayment = (paymentType == 'CASH' && showCash) ||
            (paymentType == 'CARD' && showCard) ||
            (paymentType == 'BANK' && showBank) ||
            (paymentType == 'OTHER' && showOther);

        bool hasDiscount = receipt['items'].any((item) {
          var price = item['itemPrice'];
          return price is num && price < 0;
        });

        return matchesPayment && (!showWithDiscount || hasDiscount);
      }).toList();

      print('Filtrované účtenky: ${receipts.length}');
    } catch (e) {
      print('Chyba při načítání účtenek: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Aktualizace rozsahu dat
  void updateDateRange(DateTimeRange? newDateRange) {
    dateRange = newDateRange;
    fetchReceipts();
  }

  /// Aktualizace filtračních parametrů
  void updateFilters({
    bool? showCash,
    bool? showCard,
    bool? showBank,
    bool? showOther,
    bool? showWithDiscount,
  }) {
    if (showCash != null) this.showCash = showCash;
    if (showCard != null) this.showCard = showCard;
    if (showBank != null) this.showBank = showBank;
    if (showOther != null) this.showOther = showOther;
    if (showWithDiscount != null) this.showWithDiscount = showWithDiscount;

    fetchReceipts();
  }

  /// Nastavení API klíče (používá se při přímé aktualizaci bez načítání z úložiště)
  void setApiKey(String newApiKey) {
    apiKey = newApiKey;
    notifyListeners();
    fetchReceipts();
  }
}
