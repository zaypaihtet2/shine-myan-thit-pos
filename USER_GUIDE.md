# Shine Myan Thit POS - User Guide

## 1) Introduction
This guide explains the complete daily workflow for using the Shine Myan Thit POS system.

Main flow:
- Initial setup
- Master data setup (Category, Company, Customer, Product)
- POS sale process
- Sales history and return checks
- Reports and export
- Backup and restore

## 2) Initial Setup (Do this first)
Open Settings and configure:
- Shop Name
- Shop Phone
- Shop Address
- Default Customer CD %
- Currency Symbol
- Voucher Footer Text
- Voucher Paper Width (58/80 mm)
- Voucher Font Size
- Low Stock Alert Default

Then click Save Changes.

## 3) Master Data Setup

### 3.1 Categories
Go to Categories:
- Add category names used in your store
- Edit/Delete when needed

### 3.2 Companies / Brands
Go to Companies / Brands:
- Add company name
- Set Cashback % for each company

Important:
- Profit is now calculated from company cashback percentage.
- So each product should be linked to the correct company.

### 3.3 Customers
Go to Customers:
- Add customer with type: regular / office / doctor
- Configure optional pricing and cashback/rebate rules

### 3.4 Products
Go to Products and add product details:
- Product name
- Barcode / SKU (optional)
- Category
- Company/Brand
- Selling Price (single price)
- Discount % (optional)
- Stock quantity and low-stock alert
- FOC rule (optional)

Note:
- Buying price is no longer required in product entry.
- Selling price is the main product price used.

### 3.5 Opening Stock / Stock Management
Go to Stock Management:
- Select product
- Enter quantity
- Use Stock In for adding inventory
- Use Stock Out for manual stock reductions

## 4) POS Sale Workflow
1. Open POS screen.
2. Search product by name, barcode, or SKU.
3. Tap product card to add to cart.
4. Increase/decrease quantity in cart.
5. Select payment method.
6. Select customer profile (optional) or keep walk-in.
7. Enter paid amount.
8. Review summary values:
   - Subtotal
   - Customer CD
   - Customer Rebate
   - Doctor Cashback
   - Owner Cashback
   - Payable To Office
   - My Remaining Profit
   - Final Total
   - Change
9. Click Save Sale (or press F4).
10. Voucher preview opens automatically after save.
11. Print last voucher with F5 when needed.

Keyboard shortcuts:
- F1: POS
- F2: Search focus
- F4: Save sale
- F5: Print last voucher
- ESC: Clear cart

## 5) Profit Logic (Current)
Current profit model:
- Profit is based on company cashback percentage
- Line profit = company cashback amount
- My Remaining Profit = Profit

Practical meaning:
- Product buying-cost margin is not used for profit reporting now.
- Company cashback setup directly affects profit output.

## 6) Sales History and Return
Go to Sales History:
- Search by invoice number
- Open sale details with View
- Return entries appear with RETURN type
- Deleting a normal sale reverts stock

## 7) Reports
Go to Reports:
- Choose date range: Today, Yesterday, This Week, This Month, or Custom Date
- Review summary metrics:
  - Sales
  - Profit
  - Customer CD
  - Rebate
  - Doctor Cashback
  - Owner Cashback
  - Payable To Office
  - My Remaining Profit
  - Total Invoices
- Review invoice list details
- Export CSV when needed

## 8) Backup and Restore
Go to Backup & Restore:
- Export SQLite Backup: saves a .db backup file
- Restore SQLite Backup: replaces current local data with selected backup

Recommended practice:
- Export one backup daily
- Keep backups in a safe folder (cloud sync or external drive)

## 9) Daily Operating Checklist
Use this simple sequence every day:
1. Check low-stock items
2. Perform POS sales
3. Verify sales list for mistakes
4. Review daily report totals
5. Export daily backup

## 10) Troubleshooting Quick Notes
- If stock cannot be sold: verify stock quantity in Stock Management.
- If profit looks low/high: verify company cashback % settings.
- If report seems missing data: check date range and time.
- If wrong customer pricing appears: verify selected customer profile and type.

---
If needed, create a training version of this guide with screenshots for cashier onboarding.