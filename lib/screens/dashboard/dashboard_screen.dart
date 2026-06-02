import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../providers/report_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportProvider report = context.watch<ReportProvider>();
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final String currency = settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  const Color(0xFF0F5132),
                  const Color(0xFF1F7A4D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily sales, profit, stock health, and payment mix at a glance.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      context.read<ReportProvider>().loadDashboard(),
                  icon: const Icon(Icons.refresh),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth > 1500
                    ? 4
                    : constraints.maxWidth > 1050
                    ? 3
                    : 2;

                return GridView.count(
                  crossAxisCount: columns,
                  childAspectRatio: columns == 2 ? 1.8 : 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: <Widget>[
                    DashboardCard(
                      title: 'Today Sales',
                      value: Formatters.money(
                        report.summary['todaySales'] ?? 0,
                        symbol: currency,
                      ),
                      icon: Icons.payments_outlined,
                    ),
                    DashboardCard(
                      title: 'Today Profit',
                      value: Formatters.money(
                        report.summary['todayProfit'] ?? 0,
                        symbol: currency,
                      ),
                      icon: Icons.trending_up,
                    ),
                    DashboardCard(
                      title: 'Today Customer CD',
                      value: Formatters.money(
                        report.summary['todayCd'] ?? 0,
                        symbol: currency,
                      ),
                      icon: Icons.percent,
                    ),
                    DashboardCard(
                      title: 'Today Owner Cashback',
                      value: Formatters.money(
                        report.summary['todayCashback'] ?? 0,
                        symbol: currency,
                      ),
                      icon: Icons.redeem_outlined,
                    ),
                    DashboardCard(
                      title: 'Total Products',
                      value: '${report.summary['totalProducts'] ?? 0}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    DashboardCard(
                      title: 'Low Stock',
                      value: '${report.summary['lowStock'] ?? 0}',
                      icon: Icons.warning_amber_outlined,
                    ),
                    _InsightPanel(
                      title: 'Best Selling Products',
                      icon: Icons.local_fire_department_outlined,
                      child: report.bestSelling.isEmpty
                          ? _EmptyNote(text: 'No sale data yet.')
                          : ListView.separated(
                              itemCount: report.bestSelling.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 16),
                              itemBuilder: (_, int index) {
                                final Map<String, Object?> item =
                                    report.bestSelling[index];
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. ${item['product_name']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Text('${item['qty']} pcs'),
                                  ],
                                );
                              },
                            ),
                    ),
                    _InsightPanel(
                      title: 'Payment Summary',
                      icon: Icons.account_balance_wallet_outlined,
                      child: report.paymentSummary.isEmpty
                          ? _EmptyNote(text: 'No payment breakdown yet.')
                          : ListView.separated(
                              itemCount: report.paymentSummary.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, int index) {
                                final Map<String, Object?> item =
                                    report.paymentSummary[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${item['payment_method']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        Formatters.money(
                                          item['total'] as num? ?? 0,
                                          symbol: currency,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
