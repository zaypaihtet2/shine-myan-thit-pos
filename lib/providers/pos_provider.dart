import 'package:flutter/foundation.dart';

import '../core/database/database_helper.dart';
import '../core/database/database_tables.dart';
import '../models/product_model.dart';
import 'company_provider.dart';

class CartLine {
  CartLine({required this.product, this.qty = 1});

  final ProductModel product;
  int qty;

  double get grossSubtotal => product.sellingPrice * qty;
  double get discountAmount => grossSubtotal * product.discountPercent / 100;
  double get subtotal => grossSubtotal - discountAmount;
  double get buyingTotal => product.buyingPrice * qty;
}

class PosProvider extends ChangeNotifier {
  PosProvider(this._companyProvider);

  final DatabaseHelper _db = DatabaseHelper.instance;
  final CompanyProvider _companyProvider;

  final List<CartLine> cart = <CartLine>[];
  double customerCdPercent = 0;
  String paymentMethod = 'Cash';
  double paidAmount = 0;

  double get subtotal =>
      cart.fold<double>(0, (double v, CartLine e) => v + e.subtotal);

  double get customerCdAmount => 0;

  double get companyCashbackAmount {
    double total = 0;
    for (final CartLine line in cart) {
      final double cashbackPercent = _companyProvider.cashbackByCompanyId(
        line.product.companyId,
      );
      total += line.subtotal * cashbackPercent / 100;
    }
    return total;
  }

  double get finalTotal => subtotal;

  double get buyingTotal =>
      cart.fold<double>(0, (double v, CartLine e) => v + e.buyingTotal);

  double get grossProfit => subtotal - buyingTotal;

  double get netProfit => subtotal - buyingTotal + companyCashbackAmount;

  double get changeAmount => paidAmount - finalTotal;

  void setCustomerCdPercent(double value) {
    customerCdPercent = value;
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
      if (existing.qty + 1 > product.stockQuantity) {
        throw Exception('Stock not enough');
      }
      existing.qty += 1;
    } else {
      if (product.stockQuantity <= 0) {
        throw Exception('Stock not enough');
      }
      cart.add(CartLine(product: product));
    }
    notifyListeners();
  }

  void incQty(CartLine line) {
    if (line.qty + 1 > line.product.stockQuantity) {
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
      final double cbPercent = _companyProvider.cashbackByCompanyId(
        line.product.companyId,
      );
      final double itemCashback = line.subtotal * cbPercent / 100;
      final double itemProfit = line.subtotal - line.buyingTotal + itemCashback;
      return <String, Object?>{
        'product_id': line.product.id,
        'company_id': line.product.companyId,
        'product_name': line.product.productName,
        'quantity': line.qty,
        'discount_percent': line.product.discountPercent,
        'discount_amount': line.discountAmount,
        'buying_price': line.product.buyingPrice,
        'selling_price': line.product.sellingPrice,
        'subtotal': line.subtotal,
        'company_cashback_percent': cbPercent,
        'company_cashback_amount': itemCashback,
        'profit_amount': itemProfit,
      };
    }).toList();

    final int saleId = await _db.saveSale(
      invoiceNo: invoice,
      items: items,
      subtotal: subtotal,
      discountAmount: 0,
      customerCdPercent: customerCdPercent,
      customerCdAmount: customerCdAmount,
      companyCashbackAmount: companyCashbackAmount,
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
}
