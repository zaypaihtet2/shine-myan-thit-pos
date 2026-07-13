import 'package:flutter/material.dart';

enum AppPage {
  dashboard,
  pos,
  products,
  purchases,
  categories,
  companies,
  customers,
  stock,
  sales,
  reports,
  settings,
  backup,
}

class _SidebarItem {
  const _SidebarItem(this.page, this.icon, this.label);

  final AppPage page;
  final IconData icon;
  final String label;
}

const List<_SidebarItem> _sidebarItems = <_SidebarItem>[
  _SidebarItem(AppPage.dashboard, Icons.dashboard_outlined, 'Dashboard'),
  _SidebarItem(AppPage.pos, Icons.point_of_sale_outlined, 'POS'),
  _SidebarItem(AppPage.products, Icons.inventory_2_outlined, 'Products'),
  _SidebarItem(AppPage.purchases, Icons.local_shipping_outlined, 'Purchases'),
  _SidebarItem(AppPage.categories, Icons.category_outlined, 'Categories'),
  _SidebarItem(AppPage.companies, Icons.apartment_outlined, 'Companies'),
  _SidebarItem(AppPage.customers, Icons.groups_outlined, 'Customers'),
  _SidebarItem(AppPage.stock, Icons.move_down_outlined, 'Stock'),
  _SidebarItem(AppPage.sales, Icons.receipt_long_outlined, 'Sales'),
  _SidebarItem(AppPage.reports, Icons.assessment_outlined, 'Reports'),
  _SidebarItem(AppPage.settings, Icons.settings_outlined, 'Settings'),
  _SidebarItem(AppPage.backup, Icons.backup_outlined, 'Backup'),
];

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, required this.current, required this.onSelect});

  final AppPage current;
  final ValueChanged<AppPage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerLowest,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF0F5132), Color(0xFF1F7A4D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Shine Myan Thit POS',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pharmacy sales & stock system',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      'Navigation',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ..._sidebarItems.map((_SidebarItem item) {
                    final bool selected = item.page == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          item.icon,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                        onTap: () => onSelect(item.page),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
