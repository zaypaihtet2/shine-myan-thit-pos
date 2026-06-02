import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/company_model.dart';
import '../../providers/company_provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _cashback = TextEditingController(text: '0');
  int? editingId;

  @override
  void dispose() {
    _name.dispose();
    _cashback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CompanyProvider provider = context.watch<CompanyProvider>();

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
                        'Companies / Brands',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track brand cashback and keep supplier names tidy.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: Icon(Icons.apartment_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _cashback,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cashback %',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      editingId == null ? Icons.add : Icons.save_outlined,
                    ),
                    label: Text(editingId == null ? 'Add Brand' : 'Update'),
                  ),
                  if (editingId != null) ...<Widget>[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          editingId = null;
                          _name.clear();
                          _cashback.text = '0';
                        });
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: provider.companies.isEmpty
                ? const _EmptyState(text: 'No companies yet.')
                : ListView.separated(
                    itemCount: provider.companies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int i) {
                      final CompanyModel c = provider.companies[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.apartment_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('Cashback: ${c.cashbackPercent}%'),
                          trailing: Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    editingId = c.id;
                                    _name.text = c.name;
                                    _cashback.text = c.cashbackPercent
                                        .toString();
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => provider.delete(c.id!),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final CompanyProvider provider = context.read<CompanyProvider>();
    await provider.save(
      CompanyModel(
        id: editingId,
        name: _name.text.trim(),
        cashbackPercent: double.tryParse(_cashback.text) ?? 0,
      ),
    );
    setState(() {
      editingId = null;
      _name.clear();
      _cashback.text = '0';
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
