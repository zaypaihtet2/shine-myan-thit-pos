# Jar Jar POS (Offline Desktop)

Offline Flutter desktop POS system for a small shop owner.

- Platform: Windows + Linux
- Storage: Local SQLite only (no internet required)
- State management: Provider
- Database driver: sqflite_common_ffi

## Features

- Dashboard (today sales/profit/CD/cashback, product and low-stock count)
- Product management (CRUD, search, category/company filters, product image upload)
- Category management
- Company/brand management with cashback percentage
- POS sale screen with cart, payment, discount, customer CD, change calculation
- Automatic stock deduction and insufficient stock prevention
- Sale history and sale detail
- Voucher preview and print
- Reports with date presets and CSV export
- Settings including optional PIN lock
- Backup/restore SQLite database

## Keyboard Shortcuts

- F1: POS screen
- F2: Focus product search
- F3: Product screen
- F4: Save sale
- F5: Print last voucher
- ESC: Clear cart

## Database

SQLite tables are created locally on first launch in:

- products
- categories
- companies
- sales
- sale_items
- stock_histories
- settings

The `products` table includes `image_path` so products can store local image files.

## Build And Run

```bash
flutter pub get
flutter run -d windows
flutter run -d linux
flutter build windows --release
flutter build linux --release
```

## Notes

- This app is fully offline. No API/Firebase/MySQL/Laravel dependency.
- Product images are copied into app local storage when selected.
- Backup exports `.db` file to a folder you choose.

## Main Project Structure

```text
lib/
	main.dart
	app.dart
	core/
		database/
		constants/
		utils/
		theme/
	models/
	providers/
	screens/
		auth/
		dashboard/
		pos/
		products/
		categories/
		companies/
		stock/
		sales/
		reports/
		settings/
		backup/
	widgets/
	services/
```
