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
        return 'Normal';
      case SalePricingMode.cd2:
        return 'CD 2%';
      case SalePricingMode.drCashback:
        return 'DR Cashback';
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

  bool get includesCompanyCashback {
    switch (this) {
      case SalePricingMode.drCashback:
        return true;
      case SalePricingMode.normal:
      case SalePricingMode.cd2:
        return false;
    }
  }
}

class CartLine {
  CartLine({
    required this.product,
    this.qty = 1,
    this.pricingMode = SalePricingMode.normal,
  });

  final ProductModel product;
  int qty;
  SalePricingMode pricingMode;

  double get grossSubtotal => product.sellingPrice * qty;
  double get discountPercent => pricingMode.discountPercent;
  double get discountAmount => grossSubtotal * discountPercent / 100;
  double get subtotal => grossSubtotal - discountAmount;
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

  double get companyCashbackAmount {
    double total = 0;
    for (final CartLine line in cart) {
      total += _lineCompanyCashbackAmount(line);
    }
    return total;
  }

  double get finalTotal => subtotal - rebateAmount;

  double get buyingTotal => 0;

  double get grossProfit => companyCashbackAmount;

  double get netProfit => companyCashbackAmount;

  double get officePayableAmount => finalTotal - companyCashbackAmount;

  double get ownerKeepProfit => netProfit;

  int get totalFocQty => cart.fold<int>(
    0,
    (int total, CartLine line) => total + _lineFocQty(line),
  );

  double get changeAmount => paidAmount - finalTotal;

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
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    paymentMethod = value;
    notifyListeners();
  }

  void setPaidAmount(double value) {
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
      throw Exception('Stock not enough');
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
    if (paidAmount < finalTotal) {
      throw Exception('Paid amount is less than total');
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
      final double itemProfit = companyCbAmount;
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
        'buying_price': line.product.sellingPrice,
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
      paidAmount: paidAmount,
      changeAmount: changeAmount,
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

  int _lineFocQty(CartLine line) {
    if (customerType != 'office') return 0;
    if (!line.product.focEnabled) return 0;
    if (line.product.focBuyQty <= 0 || line.product.focFreeQty <= 0) return 0;
    return (line.qty ~/ line.product.focBuyQty) * line.product.focFreeQty;
  }

  int _lineTotalQty(CartLine line, {int? paidQty}) {
    final int basePaid = paidQty ?? line.qty;
    if (customerType != 'office') return basePaid;
    if (!line.product.focEnabled) return basePaid;
    if (line.product.focBuyQty <= 0 || line.product.focFreeQty <= 0) {
      return basePaid;
    }
    final int focQty =
        (basePaid ~/ line.product.focBuyQty) * line.product.focFreeQty;
    return basePaid + focQty;
  }

  double _lineUnitPrice(CartLine line) {
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
    if (customerType == 'office') {
      return 'office_rule';
    }
    if (customerType == 'doctor') {
      return 'doctor_rule';
    }
    return line.pricingMode.code;
  }

  double _lineGrossSubtotal(CartLine line) => _lineUnitPrice(line) * line.qty;

  double _lineLegacyDiscountPercent(CartLine line) {
    if (customerType != 'regular') return 0;
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
    if (customerType != 'doctor') return 0;
    return customerCashbackPercent;
  }

  double _lineCustomerCashbackAmount(CartLine line) =>
      _lineSubtotalBeforeRebate(line) *
      _lineCustomerCashbackPercent(line) /
      100;

  double _lineCompanyCashbackPercent(CartLine line) {
    return _companyProvider.cashbackByCompanyId(line.product.companyId);
  }

  double _lineCompanyCashbackAmount(CartLine line) =>
      _lineFinalSubtotal(line) * _lineCompanyCashbackPercent(line) / 100;
}
