import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/product_model.dart';
import 'company_provider.dart';

enum SalePricingMode { normal, cd2, drCashback }

extension SalePricingModeX on SalePricingMode {
  String get code {
    switch (this) {
      case SalePricingMode.normal:
        return 'normal';
      case SalePricingMode.cd2:
        return 'cd2';
      case SalePricingMode.drCashback:
        return 'dr_cashback';
    }
  }

  String get label {
    switch (this) {
      case SalePricingMode.normal:
        return 'Normal Price';
      case SalePricingMode.cd2:
        return 'CD 2%';
      case SalePricingMode.drCashback:
        return 'Doctor Cashback';
    }
  }

  double get discountPercent {
    switch (this) {
      case SalePricingMode.cd2:
        return 2;
      case SalePricingMode.normal:
      case SalePricingMode.drCashback:
        return 0;
    }
  }
}

class CartLine {
  CartLine({
    required this.product,
    this.qty = 1,
    this.pricingMode = SalePricingMode.normal,
    this.customUnitPrice,
    this.doctorCashbackAmount = 0,
  });

  final ProductModel product;
  int qty;
  SalePricingMode pricingMode;
  double? customUnitPrice;
  double doctorCashbackAmount;

  int get focQty {
    if (!product.focEnabled) return 0;
    if (product.focBuyQty <= 0 || product.focFreeQty <= 0) return 0;
    return (qty ~/ product.focBuyQty) * product.focFreeQty;
  }

  int get stockOutQty => qty + focQty;
}

class PosProvider extends ChangeNotifier {
  PosProvider(this._companyProvider);

  final DatabaseHelper _db = DatabaseHelper.instance;
  final CompanyProvider _companyProvider;

  final List<CartLine> cart = <CartLine>[];
  int? customerId;
  String customerName = '';
  String customerType = 'regular';
  String customerPriceMode = 'normal';
  double customerPricePercent = 0;
  double customerRebatePercent = 0;
  double customerCashbackPercent = 0;
  double customerCdPercent = 0;
  String paymentMethod = 'Cash';
  double paidAmount = 0;

  bool get isCreditSale => paymentMethod == 'Credit';

  double get subtotal => cart.fold<double>(
    0,
    (double total, CartLine line) => total + _lineSubtotalBeforeRebate(line),
  );

  double get rebateAmount => cart.fold<double>(
    0,
    (double total, CartLine line) => total + _lineRebateAmount(line),
  );

  double get customerCdAmount => cart.fold<double>(
    0,
    (double total, CartLine line) => total + _lineLegacyDiscountAmount(line),
  );

  double get customerCashbackAmount => cart.fold<double>(
    0,
    (double total, CartLine line) => total + _lineCustomerCashbackAmount(line),
  );

  double get companyCashbackAmount => cart.fold<double>(
    0,
    (double total, CartLine line) => total + _lineCompanyCashbackAmount(line),
  );

  double get finalTotal => subtotal - rebateAmount;

  double get buyingTotal => cart.fold<double>(
    0,
    (double total, CartLine line) =>
        total + line.product.buyingPrice * line.stockOutQty,
  );

  double get grossProfit => cart.fold<double>(
    0,
    (double total, CartLine line) =>
        total + _lineCompanyCashbackAmount(line) + _linePriceUplift(line),
  );

  double get netProfit => grossProfit - customerCashbackAmount;

  double get officePayableAmount => finalTotal - companyCashbackAmount;

  double get ownerKeepProfit => netProfit;

  int get totalFocQty => cart.fold<int>(
    0,
    (int total, CartLine line) => total + _lineFocQty(line),
  );

  double get changeAmount => isCreditSale ? 0 : paidAmount - finalTotal;

  double get creditDueAmount => isCreditSale ? finalTotal : 0;

  double lineUnitPrice(CartLine line) => _lineUnitPrice(line);

  double lineSubtotal(CartLine line) => _lineFinalSubtotal(line);

  int lineFocQty(CartLine line) => _lineFocQty(line);

  int lineStockOutQty(CartLine line) => _lineTotalQty(line);

  double lineDoctorCashback(CartLine line) =>
      _lineCustomerCashbackAmount(line);

  void setCustomerCdPercent(double value) {
    customerCdPercent = value;
    notifyListeners();
  }

  void setCustomerName(String value) {
    customerName = value;
    notifyListeners();
  }

  void setCustomerProfile({
    required int? id,
    required String name,
    required String type,
    String priceMode = 'normal',
    double pricePercent = 0,
    double rebatePercent = 0,
    double cashbackPercent = 0,
  }) {
    customerId = id;
    customerName = name;
    customerType = type;
    customerPriceMode = priceMode;
    customerPricePercent = pricePercent;
    customerRebatePercent = rebatePercent;
    customerCashbackPercent = cashbackPercent;
    notifyListeners();
  }

  void setLinePricingMode(CartLine line, SalePricingMode mode) {
    line.pricingMode = mode;
    if (mode == SalePricingMode.drCashback) {
      line.customUnitPrice ??= line.product.sellingPrice;
      if (line.doctorCashbackAmount == 0 && customerCashbackPercent > 0) {
        line.doctorCashbackAmount =
            _lineGrossSubtotal(line) * customerCashbackPercent / 100;
      }
    } else {
      line.customUnitPrice = null;
      line.doctorCashbackAmount = 0;
    }
    notifyListeners();
  }

  void setLineUnitPrice(CartLine line, double value) {
    if (value < 0) {
      throw Exception('Sale price cannot be negative');
    }
    line.customUnitPrice = value;
    notifyListeners();
  }

  void setLineDoctorCashbackAmount(CartLine line, double value) {
    if (value < 0) {
      throw Exception('Doctor cashback cannot be negative');
    }
    line.doctorCashbackAmount = value;
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    paymentMethod = value;
    if (isCreditSale) {
      paidAmount = 0;
    }
    notifyListeners();
  }

  void setPaidAmount(double value) {
    if (isCreditSale) return;
    paidAmount = value;
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    final CartLine? existing = cart
        .where((CartLine c) => c.product.id == product.id)
        .cast<CartLine?>()
        .firstOrNull;
    if (existing != null) {
      if (_lineTotalQty(existing, paidQty: existing.qty + 1) >
          product.stockQuantity) {
        throw Exception('Stock not enough');
      }
      existing.qty += 1;
    } else {
      final CartLine line = CartLine(product: product);
      if (_lineTotalQty(line) > product.stockQuantity) {
        throw Exception('Stock not enough');
      }
      cart.add(line);
    }
    notifyListeners();
  }

  void incQty(CartLine line) {
    if (_lineTotalQty(line, paidQty: line.qty + 1) >
        line.product.stockQuantity) {
      throw Exception('Stock not enough including FOC quantity');
    }
    line.qty += 1;
    notifyListeners();
  }

  void decQty(CartLine line) {
    if (line.qty <= 1) {
      cart.remove(line);
    } else {
      line.qty -= 1;
    }
    notifyListeners();
  }

  void remove(CartLine line) {
    cart.remove(line);
    notifyListeners();
  }

  void clear() {
    cart.clear();
    customerId = null;
    customerName = '';
    customerType = 'regular';
    customerPriceMode = 'normal';
    customerPricePercent = 0;
    customerRebatePercent = 0;
    customerCashbackPercent = 0;
    paidAmount = 0;
    paymentMethod = 'Cash';
    notifyListeners();
  }

  Future<int> saveSale() async {
    if (cart.isEmpty) {
      throw Exception('Cart is empty');
    }
    if (isCreditSale && customerId == null) {
      throw Exception('Select a saved customer for a Credit sale');
    }
    if (!isCreditSale && paidAmount < finalTotal) {
      throw Exception('Paid amount is less than total');
    }
    for (final CartLine line in cart) {
      if (line.pricingMode == SalePricingMode.drCashback &&
          line.doctorCashbackAmount > _lineFinalSubtotal(line)) {
        throw Exception(
          'Doctor cashback is greater than the sale amount for ${line.product.productName}',
        );
      }
      if (_lineTotalQty(line) > line.product.stockQuantity) {
        throw Exception(
          'Stock not enough for ${line.product.productName}, including FOC',
        );
      }
    }

    final String invoice = await _db.nextInvoiceNo();
    final List<Map<String, Object?>> items = cart.map((CartLine line) {
      final int focQty = _lineFocQty(line);
      final int totalQty = line.qty + focQty;
      final double legacyDiscountPercent = _lineLegacyDiscountPercent(line);
      final double legacyDiscountAmount = _lineLegacyDiscountAmount(line);
      final double rebatePercent = _lineRebatePercent(line);
      final double rebateAmount = _lineRebateAmount(line);
      final double lineFinalSubtotal = _lineFinalSubtotal(line);
      final double appliedUnitPrice = _lineUnitPrice(line);
      final double companyCbPercent = _lineCompanyCashbackPercent(line);
      final double companyCbAmount = _lineCompanyCashbackAmount(line);
      final double customerCbPercent = _lineCustomerCashbackPercent(line);
      final double customerCbAmount = _lineCustomerCashbackAmount(line);
      final double itemProfit =
          companyCbAmount + _linePriceUplift(line) - customerCbAmount;
      return <String, Object?>{
        'product_id': line.product.id,
        'company_id': line.product.companyId,
        'product_name': line.product.productName,
        'sale_option': _lineSaleOptionCode(line),
        'quantity': totalQty,
        'paid_quantity': line.qty,
        'foc_quantity': focQty,
        'discount_percent': legacyDiscountPercent,
        'discount_amount': legacyDiscountAmount,
        'rebate_percent': rebatePercent,
        'rebate_amount': rebateAmount,
        'buying_price': line.product.buyingPrice,
        'selling_price': line.product.sellingPrice,
        'unit_price_applied': appliedUnitPrice,
        'subtotal': lineFinalSubtotal,
        'customer_cashback_percent': customerCbPercent,
        'customer_cashback_amount': customerCbAmount,
        'company_cashback_percent': companyCbPercent,
        'company_cashback_amount': companyCbAmount,
        'profit_amount': itemProfit,
      };
    }).toList();

    final double totalDiscount = customerCdAmount + rebateAmount;
    final double cdPercentForSale = customerCdAmount > 0 ? 2 : 0;
    final double avgRebatePercent = subtotal > 0
        ? rebateAmount * 100 / subtotal
        : 0;
    final double avgCustomerCashbackPercent = subtotal > 0
        ? customerCashbackAmount * 100 / subtotal
        : 0;
    final double savedPaidAmount = isCreditSale ? 0 : paidAmount;
    final double savedChangeAmount = isCreditSale ? 0 : changeAmount;

    final int saleId = await _db.saveSale(
      invoiceNo: invoice,
      customerId: customerId,
      customerName: customerName,
      customerType: customerType,
      items: items,
      subtotal: subtotal,
      discountAmount: totalDiscount,
      rebatePercent: avgRebatePercent,
      rebateAmount: rebateAmount,
      customerCdPercent: cdPercentForSale,
      customerCdAmount: customerCdAmount,
      customerCashbackPercent: avgCustomerCashbackPercent,
      customerCashbackAmount: customerCashbackAmount,
      companyCashbackAmount: companyCashbackAmount,
      officePayableAmount: officePayableAmount,
      ownerKeepProfit: ownerKeepProfit,
      finalTotal: finalTotal,
      paidAmount: savedPaidAmount,
      changeAmount: savedChangeAmount,
      paymentMethod: paymentMethod,
      profitAmount: netProfit,
    );

    clear();
    return saleId;
  }

  Future<Map<String, Object?>> saleDetail(int saleId) async {
    final List<Map<String, Object?>> sale = await _db.query(
      DatabaseTables.sales,
      where: 'id = ?',
      whereArgs: <Object?>[saleId],
    );
    final List<Map<String, Object?>> items = await _db.query(
      DatabaseTables.saleItems,
      where: 'sale_id = ?',
      whereArgs: <Object?>[saleId],
    );
    if (sale.isEmpty) {
      throw Exception('Sale not found');
    }
    return <String, Object?>{'sale': sale.first, 'items': items};
  }

  int _lineFocQty(CartLine line, {int? paidQty}) {
    final int basePaid = paidQty ?? line.qty;
    if (!line.product.focEnabled) return 0;
    if (line.product.focBuyQty <= 0 || line.product.focFreeQty <= 0) return 0;
    return (basePaid ~/ line.product.focBuyQty) * line.product.focFreeQty;
  }

  int _lineTotalQty(CartLine line, {int? paidQty}) {
    final int basePaid = paidQty ?? line.qty;
    return basePaid + _lineFocQty(line, paidQty: basePaid);
  }

  double _lineUnitPrice(CartLine line) {
    if (line.pricingMode == SalePricingMode.drCashback &&
        line.customUnitPrice != null) {
      return line.customUnitPrice!;
    }
    switch (customerPriceMode) {
      case 'same_buying':
        return line.product.sellingPrice;
      case 'adjust_selling_percent':
        return line.product.sellingPrice * (1 + customerPricePercent / 100);
      default:
        return line.product.sellingPrice;
    }
  }

  String _lineSaleOptionCode(CartLine line) {
    if (line.pricingMode == SalePricingMode.drCashback) {
      return 'dr_cashback';
    }
    if (customerType == 'office') {
      return 'office_rule';
    }
    if (line.pricingMode == SalePricingMode.cd2) {
      return 'cd2';
    }
    return 'normal';
  }

  double _lineGrossSubtotal(CartLine line) => _lineUnitPrice(line) * line.qty;

  double _lineLegacyDiscountPercent(CartLine line) {
    if (line.pricingMode != SalePricingMode.cd2) return 0;
    return line.pricingMode.discountPercent;
  }

  double _lineLegacyDiscountAmount(CartLine line) =>
      _lineGrossSubtotal(line) * _lineLegacyDiscountPercent(line) / 100;

  double _lineSubtotalBeforeRebate(CartLine line) =>
      _lineGrossSubtotal(line) - _lineLegacyDiscountAmount(line);

  double _lineRebatePercent(CartLine line) {
    if (customerType != 'office') return 0;
    return customerRebatePercent;
  }

  double _lineRebateAmount(CartLine line) =>
      _lineSubtotalBeforeRebate(line) * _lineRebatePercent(line) / 100;

  double _lineFinalSubtotal(CartLine line) =>
      _lineSubtotalBeforeRebate(line) - _lineRebateAmount(line);

  double _lineCustomerCashbackPercent(CartLine line) {
    final double base = _lineSubtotalBeforeRebate(line);
    if (base <= 0) return 0;
    return _lineCustomerCashbackAmount(line) * 100 / base;
  }

  double _lineCustomerCashbackAmount(CartLine line) {
    if (line.pricingMode != SalePricingMode.drCashback) return 0;
    return line.doctorCashbackAmount;
  }

  double _lineCompanyCashbackPercent(CartLine line) {
    return _companyProvider.cashbackByCompanyId(line.product.companyId);
  }

  double _lineCompanyCashbackAmount(CartLine line) =>
      _lineFinalSubtotal(line) * _lineCompanyCashbackPercent(line) / 100;

  double _linePriceUplift(CartLine line) {
    final double difference = _lineUnitPrice(line) - line.product.sellingPrice;
    return difference > 0 ? difference * line.qty : 0;
  }
}
