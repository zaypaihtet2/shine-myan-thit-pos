import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _name = TextEditingController();
  int? editingId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CategoryProvider provider = context.watch<CategoryProvider>();

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
                        'Categories',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep inventory organized with a simple category structure.',
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
                  child: Icon(Icons.category_outlined, color: Colors.white),
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
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      editingId == null ? Icons.add : Icons.save_outlined,
                    ),
                    label: Text(editingId == null ? 'Add Category' : 'Update'),
                  ),
                  if (editingId != null) ...<Widget>[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          editingId = null;
                          _name.clear();
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
            child: provider.categories.isEmpty
                ? const _EmptyState(text: 'No categories yet.')
                : ListView.separated(
                    itemCount: provider.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int i) {
                      final CategoryModel item = provider.categories[i];
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
                              Icons.category_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('Category ID: ${item.id ?? '-'}'),
                          trailing: Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  setState(() {
                                    editingId = item.id;
                                    _name.text = item.name;
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => provider.delete(item.id!),
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
    final CategoryProvider provider = context.read<CategoryProvider>();
    await provider.save(CategoryModel(id: editingId, name: _name.text.trim()));
    setState(() {
      editingId = null;
      _name.clear();
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
