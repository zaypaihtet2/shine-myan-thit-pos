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
                    colors: <Color>[
                      Color(0xFF0F5132),
                      Color(0xFF1F7A4D),
                    ],
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
              child: NavigationRail(
                selectedIndex: AppPage.values.indexOf(current),
                onDestinationSelected: (int index) =>
                    onSelect(AppPage.values[index]),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Navigation',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                    ),
                  ),
                ),
                groupAlignment: -0.9,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.point_of_sale_outlined),
                    selectedIcon: Icon(Icons.point_of_sale_rounded),
                    label: Text('POS'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2_rounded),
                    label: Text('Products'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping_rounded),
                    label: Text('Purchases'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.category_outlined),
                    selectedIcon: Icon(Icons.category_rounded),
                    label: Text('Categories'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.apartment_outlined),
                    selectedIcon: Icon(Icons.apartment_rounded),
                    label: Text('Companies'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                    label: Text('Customers'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.move_down_outlined),
                    selectedIcon: Icon(Icons.move_down_rounded),
                    label: Text('Stock'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: Text('Sales'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.assessment_outlined),
                    selectedIcon: Icon(Icons.assessment_rounded),
                    label: Text('Reports'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: Text('Settings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.backup_outlined),
                    selectedIcon: Icon(Icons.backup_rounded),
                    label: Text('Backup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
