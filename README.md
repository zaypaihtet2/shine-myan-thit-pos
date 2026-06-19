# Shine Myan Thit POS

Shine Myan Thit POS is an offline desktop point-of-sale, inventory, purchase, customer credit, voucher, and reporting system designed for a pharmacy or medicine distribution shop.

The application runs locally on Windows and Linux, uses SQLite for storage, and does not require an internet connection, cloud server, API, MySQL, Firebase, or Laravel backend.

## Application Summary

- **Application name:** Shine Myan Thit POS
- **Platforms:** Windows and Linux desktop
- **Framework:** Flutter
- **Local database:** SQLite
- **State management:** Provider
- **Database package:** `sqflite_common_ffi`
- **Windows executable:** `shine_myan_thit_pos.exe`
- **Internet required:** No

## Main Features

### Dashboard

The dashboard provides a quick summary of shop activity, including:

- Today's sales
- Today's profit
- Customer discount totals
- Doctor cashback totals
- Product count
- Low-stock product count
- Recent sales information

### Product Management

Products can be created, edited, searched, filtered, and deleted.

Each product can include:

- Product name
- Expiry date
- Optional internal product code (SKU)
- Optional product discount percentage
- Category
- Company or brand
- Product image
- Product price
- Current stock quantity
- Low-stock alert quantity
- FOC rule

#### Expiry Date

The product form uses **Expiry Date** instead of Barcode. The date is selected from a calendar and stored in `YYYY-MM-DD` format.

Expired products are marked with an **EXPIRED** badge in the product list.

#### SKU

SKU means **Stock Keeping Unit**. It is an optional internal code created by the shop to identify products.

Examples:

```text
MED-001
PARA-500
AMOX-500-10
```

The SKU field may be left empty when the shop does not use internal product codes.

#### Product Discount Percentage

The Product Discount % field is optional and can be used to record product-level promotion information, such as 5% or 10%.

Set the value to `0` when no product promotion is used.

> Note: This field is currently stored as product information and displayed in the product list. It is not automatically applied to every POS sale.

### Categories

Categories can be used to organize products, for example:

- Medicine
- Supplement
- Injection
- Medical equipment
- Other

Products can be filtered by category from the Products page.

### Companies and Brands

Companies or brands can be created and assigned to products.

A company cashback percentage can also be stored and used during sale and profit calculations.

### Customers, Doctors, and Offices

Customer profiles can be created for regular customers, doctors, clinics, pharmacies, and offices.

Available fields include:

#### Name

The customer, doctor, clinic, pharmacy, or office name.

#### Type

- **Regular Customer:** Standard customer profile
- **Doctor:** Used for Doctor Cashback sales
- **Office / Pharmacy:** Used for office price and rebate rules

#### Price Mode

Controls the customer's default product price behavior.

- **Normal Product Price:** Uses the product's saved selling price
- **Use Saved Product Price:** Uses the product's stored price without an additional percentage adjustment
- **Adjust Product Price by %:** Increases the product price using the configured Price Adjustment percentage

#### Price Adjustment Percentage

Used only when **Adjust Product Price by %** is selected.

Example:

```text
Product price: 50,000 Ks
Price adjustment: 10%
Adjusted price: 55,000 Ks
```

Use `0` when no price adjustment is required.

#### Office Rebate Percentage

A percentage discount applied to Office or Pharmacy sales.

Example:

```text
Sale amount: 500,000 Ks
Office rebate: 2%
Rebate amount: 10,000 Ks
```

#### Default Doctor Cashback Percentage

A starting cashback suggestion for Doctor Cashback sales.

The cashback amount can still be changed manually for each sale.

#### Customer Credit

Outstanding customer credit is displayed in the customer list and in the POS customer selector.

A customer with an outstanding credit balance cannot be deleted until the balance is cleared.

## Point of Sale

The POS screen supports product search, cart management, customer selection, pricing modes, payment methods, stock validation, FOC calculation, cashback, profit calculation, and voucher printing.

### Sale Pricing Modes

Each cart item can use one of the following modes:

#### Normal Price

Uses the product's normal selling price.

If the product has an FOC rule, the FOC quantity is calculated automatically.

#### Net Price

Allows the operator to enter a custom net selling price per unit.

Net Price mode is useful when the customer does not want the normal FOC package and wants a smaller quantity at a lower net unit price.

Example supplier rule:

```text
Paid quantity from supplier: 10
Supplier FOC quantity: 5
Purchase price per paid unit: 53,000 Ks
Total quantity received: 15
```

The effective cost per unit is calculated as:

```text
53,000 × 10 ÷ 15 = 35,333.33 Ks
```

The operator may then enter a net sale price such as `35,000`, `35,500`, or another amount.

In Net Price mode:

- Customer FOC is not issued
- Only the sold quantity is deducted from stock
- Estimated profit is shown immediately in the cart

#### CD 2%

Applies a 2% customer discount to the selected cart item.

#### Doctor Cashback

Allows the operator to adjust both:

- Sale price per unit
- Total Doctor Cashback amount for the cart line

Example:

```text
Original product price: 53,000 Ks
Adjusted sale price: 60,000 Ks
Doctor cashback: 7,000 Ks
```

The selected sale price and cashback amount are stored with the sale and shown in sale details and vouchers.

### FOC Rules

FOC means **Free of Charge**.

A product can be configured with a rule such as:

```text
Buy quantity: 10
FOC quantity: 5
```

When 10 units are sold using a normal FOC-enabled mode:

```text
Paid quantity: 10
FOC quantity: 5
Total stock out: 15
```

The cart, sale item, voucher, stock history, and database record keep paid quantity and FOC quantity separately.

### Payment Methods

Supported payment methods include:

- Cash
- KPay
- WavePay
- Bank Transfer
- Credit

#### Credit Sales

When **Credit** is selected:

- The Paid Amount field is hidden
- A saved customer must be selected
- Paid amount is saved as zero
- The sale total becomes the customer's outstanding credit
- The voucher shows the credit balance

For non-credit sales, the paid amount must be at least the final total.

### Profit Calculation

The POS calculates estimated profit for each cart line and total profit for the sale.

The calculation considers:

- Actual sale price
- Effective inventory cost
- FOC-adjusted product cost
- Company cashback
- Doctor cashback
- Customer discount
- Office rebate

A simplified line profit formula is:

```text
Sale amount
+ Company cashback
- Inventory cost
- Doctor cashback
```

Negative profit is shown as a loss.

## Purchase Entries

The Purchases module is a digital incoming-goods register.

A purchase entry can include:

- Supplier or company
- Supplier invoice or reference number
- Purchase date
- Note
- Multiple products
- Quantity per product
- Purchase price per unit
- Line total
- Total purchase value

### Automatic Stock Update

When a purchase is saved, the application automatically:

1. Creates a purchase header record
2. Creates one purchase item record for each product
3. Adds the purchased quantity to product stock
4. Updates the product's latest buying price
5. Creates a stock history record
6. Stores old stock and new stock values

Example:

```text
Old stock: 20
Purchased quantity: 100
New stock: 120
```

The user does not need to enter the same stock quantity again in the Stock module.

## Stock Management

The Stock module supports manual stock-in and stock-out operations.

Each stock movement records:

- Product
- Movement type
- Quantity
- Old stock
- New stock
- Note
- Date and time

The system prevents stock from going below zero.

## Sales History

The Sales History page is designed to show the most important information first:

```text
DATE | CUSTOMER | AMOUNT
```

Each record clearly displays:

- Sale date
- Sale time
- Customer name
- Invoice number
- Customer type
- Payment method
- Sale amount
- Return status
- View Voucher action

Sales can be searched by:

- Invoice number
- Customer name
- Sale date

## Voucher and Invoice View

The voucher detail view uses a clear invoice-style layout.

The product table includes:

```text
No | Description | Qty | FOC | Unit Price | Amount
```

The voucher also displays:

- Shop name
- Shop phone
- Shop address
- Customer name
- Customer type
- Invoice number
- Sale date and time
- Payment method
- Subtotal
- Discount or CD
- Rebate
- Doctor cashback
- Owner cashback
- Payable to office
- Final total
- Paid amount
- Balance or change
- Customer signature
- Authorized signature

Available actions include:

- PDF preview
- Print
- Process sale return

## Sale Returns

A completed sale can be partially or fully returned.

The return workflow:

- Selects sale items and return quantities
- Calculates return amount
- Restores returned quantity to stock
- Creates return records
- Preserves the original sale history

## Reports

The Reports page provides large, colorful summary cards and clear sale rows.

Available report cards include:

- Net Sales
- My Remaining Profit
- Payable to Office
- Owner Cashback
- Doctor Cashback
- Customer CD
- Rebate
- Returns

Date filters include:

- Today
- Yesterday
- This Week
- This Month
- Custom Date Range

Report sale rows show:

```text
DATE | CUSTOMER | AMOUNT | PROFIT / OFFICE
```

Reports can be exported to CSV.

## Settings

Settings include:

- Shop name
- Shop phone
- Shop address
- Currency symbol
- Voucher footer
- Voucher logo
- Voucher paper size
- Voucher font size
- Dark mode
- Optional PIN lock

## Backup and Restore

The application stores data locally in SQLite.

The Backup module can:

- Export the SQLite database to a selected folder
- Restore a previously exported database

The existing database filename remains `jar_jar_pos.db` so older shop data is preserved after the application name change.

> Create regular backups, especially before replacing the application or moving it to another computer.

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `F1` | Open POS screen |
| `F2` | Focus product search |
| `F3` | Open Products screen |
| `F4` | Save current sale |
| `F5` | Print the last voucher |
| `ESC` | Clear the current cart |

## Local Database Tables

The application creates and manages tables including:

- `products`
- `categories`
- `companies`
- `customers`
- `purchase_entries`
- `purchase_items`
- `sales`
- `sale_items`
- `sale_returns`
- `sale_return_items`
- `stock_histories`
- `settings`

## Main Project Structure

```text
lib/
  main.dart
  app.dart
  core/
    constants/
    database/
    theme/
    utils/
  models/
  providers/
  screens/
    auth/
    backup/
    categories/
    companies/
    customers/
    dashboard/
    pos/
    products/
    purchases/
    reports/
    sales/
    settings/
    stock/
  services/
  widgets/
```

## Development Requirements

- Flutter stable channel
- Dart SDK supported by the project
- Visual Studio with Desktop development with C++ for Windows builds
- GTK development packages for Linux builds

## Install Dependencies

```bash
flutter pub get
```

## Run on Windows

```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## Build Windows Release

```bash
flutter clean
flutter pub get
flutter analyze
flutter build windows --release
```

The release folder is normally located at:

```text
build/windows/x64/runner/Release/
```

Run:

```text
shine_myan_thit_pos.exe
```

Keep the EXE, DLL files, and `data` directory together. Do not move only the EXE file.

## Run and Build on Linux

```bash
flutter config --enable-linux-desktop
flutter run -d linux
flutter build linux --release
```

## GitHub Actions Windows Build

The repository contains a Windows build workflow at:

```text
.github/workflows/windows-build.yml
```

The workflow runs on:

- Push to `main`
- Pull request targeting `main`
- Manual workflow dispatch

It performs:

1. Checkout source
2. Install Flutter stable
3. Enable Windows desktop support
4. Install dependencies
5. Run Flutter analysis
6. Build Windows release
7. Create `Shine-Myan-Thit-POS-Windows.zip`
8. Upload the ZIP as a GitHub Actions artifact

The artifact is retained for 30 days.

## Important Notes

- The application is fully offline.
- All business data is stored on the local computer.
- Product images are copied into application support storage.
- A database backup should be created regularly.
- The application folder must keep its DLL and data files beside the EXE.
- Test sales, FOC rules, credit sales, purchases, returns, and printing before using the application in production.

## License

This project is a private custom POS application for Shine Myan Thit.
