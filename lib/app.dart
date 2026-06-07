import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/theme/app_theme.dart';
import 'providers/category_provider.dart';
import 'providers/company_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/pos_provider.dart';
import 'providers/product_provider.dart';
import 'providers/report_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/backup/backup_restore_screen.dart';
import 'screens/categories/category_screen.dart';
import 'screens/companies/company_screen.dart';
import 'screens/customers/customer_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/pos/pos_sale_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/sales/sales_history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/stock/stock_management_screen.dart';
import 'widgets/app_sidebar.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider<CompanyProvider>(
          create: (_) => CompanyProvider(),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (_) => CustomerProvider(),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider<SalesProvider>(create: (_) => SalesProvider()),
        ChangeNotifierProvider<ReportProvider>(create: (_) => ReportProvider()),
        ChangeNotifierProxyProvider<CompanyProvider, PosProvider>(
          create: (BuildContext context) =>
              PosProvider(context.read<CompanyProvider>()),
          update: (_, CompanyProvider company, PosProvider? previous) =>
              previous ?? PosProvider(company),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, SettingsProvider settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Shine Myan Thit',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const RootGate(),
          );
        },
      ),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool initialized = false;
  bool showSplash = true;
  String? bootError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _boot();
      }
    });
  }

  Future<void> _boot() async {
    try {
      setState(() {
        bootError = null;
        showSplash = true;
      });

      final SettingsProvider settings = context.read<SettingsProvider>();
      final CategoryProvider categories = context.read<CategoryProvider>();
      final CompanyProvider companies = context.read<CompanyProvider>();
      final ProductProvider products = context.read<ProductProvider>();
      final CustomerProvider customers = context.read<CustomerProvider>();
      final SalesProvider sales = context.read<SalesProvider>();
      final ReportProvider reports = context.read<ReportProvider>();

      await settings.load();
      await sales.seedDemoData();
      await categories.load();
      await companies.load();
      await customers.load();
      await products.load();
      await sales.load();
      await reports.loadDashboard();

      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() {
          initialized = true;
          showSplash = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          bootError = e.toString();
          showSplash = false;
          initialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bootError != null) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 520,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Startup failed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(bootError ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _boot,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (showSplash || !initialized) {
      return const SplashScreen();
    }
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppPage page = AppPage.dashboard;

  Widget _body() {
    switch (page) {
      case AppPage.dashboard:
        return const DashboardScreen();
      case AppPage.pos:
        return const PosSaleScreen();
      case AppPage.products:
        return const ProductListScreen();
      case AppPage.categories:
        return const CategoryScreen();
      case AppPage.companies:
        return const CompanyScreen();
      case AppPage.customers:
        return const CustomerScreen();
      case AppPage.stock:
        return const StockManagementScreen();
      case AppPage.sales:
        return const SalesHistoryScreen();
      case AppPage.reports:
        return const ReportsScreen();
      case AppPage.settings:
        return const SettingsScreen();
      case AppPage.backup:
        return const BackupRestoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.f1): const _GoPageIntent(AppPage.pos),
        LogicalKeySet(LogicalKeyboardKey.f2): const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.f3): const _GoPageIntent(
          AppPage.products,
        ),
        LogicalKeySet(LogicalKeyboardKey.f4): const _SaveSaleIntent(),
        LogicalKeySet(LogicalKeyboardKey.f5): const _PrintVoucherIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _ClearOrCloseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _GoPageIntent: CallbackAction<_GoPageIntent>(
            onInvoke: (_GoPageIntent intent) {
              setState(() => page = intent.page);
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_FocusSearchIntent intent) {
              setState(() => page = AppPage.pos);
              PosSaleScreen.searchFocusNode.requestFocus();
              return null;
            },
          ),
          _SaveSaleIntent: CallbackAction<_SaveSaleIntent>(
            onInvoke: (_SaveSaleIntent intent) {
              PosSaleScreen.saveSaleGlobal?.call();
              return null;
            },
          ),
          _PrintVoucherIntent: CallbackAction<_PrintVoucherIntent>(
            onInvoke: (_PrintVoucherIntent intent) {
              PosSaleScreen.printLastVoucherGlobal?.call();
              return null;
            },
          ),
          _ClearOrCloseIntent: CallbackAction<_ClearOrCloseIntent>(
            onInvoke: (_ClearOrCloseIntent intent) {
              PosSaleScreen.clearCartGlobal?.call();
              return null;
            },
          ),
        },
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: <Widget>[
                AppSidebar(
                  current: page,
                  onSelect: (AppPage p) => setState(() => page = p),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoPageIntent extends Intent {
  const _GoPageIntent(this.page);
  final AppPage page;
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _SaveSaleIntent extends Intent {
  const _SaveSaleIntent();
}

class _PrintVoucherIntent extends Intent {
  const _PrintVoucherIntent();
}

class _ClearOrCloseIntent extends Intent {
  const _ClearOrCloseIntent();
}
