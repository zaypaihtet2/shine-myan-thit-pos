import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _pricePercent = TextEditingController(text: '0');
  final TextEditingController _rebate = TextEditingController(text: '0');
  final TextEditingController _cashback = TextEditingController(text: '0');
  String _type = 'regular';
  String _priceMode = 'normal';
  int? _editingId;

  @override
  void dispose() {
    _name.dispose();
    _pricePercent.dispose();
    _rebate.dispose();
    _cashback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerProvider provider = context.watch<CustomerProvider>();

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
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Customers / Doctors / Offices',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Define rebate and cashback defaults by customer type.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'regular',
                          child: Text('Regular'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'office',
                          child: Text('Office'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'doctor',
                          child: Text('Doctor'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _type = value ?? 'regular');
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _priceMode,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'normal',
                          child: Text('Normal Price'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'same_buying',
                          child: Text('Same As Product Price'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'adjust_selling_percent',
                          child: Text('Adjust Selling %'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() => _priceMode = value ?? 'normal');
                      },
                      decoration: const InputDecoration(
                        labelText: 'Price Mode',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _pricePercent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Price %'),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _rebate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Rebate %'),
                    ),
                  ),
                  SizedBox(
                    width: 150,
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
                  FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      _editingId == null ? Icons.add : Icons.save_outlined,
                    ),
                    label: Text(_editingId == null ? 'Add' : 'Update'),
                  ),
                  if (_editingId != null)
                    OutlinedButton(
                      onPressed: _resetForm,
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: provider.customers.isEmpty
                ? const Center(child: Text('No customers yet.'))
                : ListView.separated(
                    itemCount: provider.customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, int i) {
                      final CustomerModel c = provider.customers[i];
                      return Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                            'Type: ${c.type} | Price: ${c.priceMode} (${c.pricePercent}%) | Rebate: ${c.rebatePercent}% | Cashback: ${c.cashbackPercent}%',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _editingId = c.id;
                                    _name.text = c.name;
                                    _type = c.type;
                                    _priceMode = c.priceMode;
                                    _pricePercent.text = c.pricePercent
                                        .toString();
                                    _rebate.text = c.rebatePercent.toString();
                                    _cashback.text = c.cashbackPercent
                                        .toString();
                                  });
                                },
                                child: const Text('Edit'),
                              ),
                              OutlinedButton(
                                onPressed: () => provider.delete(c.id!),
                                child: const Text('Delete'),
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
    final CustomerProvider provider = context.read<CustomerProvider>();
    await provider.save(
      CustomerModel(
        id: _editingId,
        name: _name.text.trim(),
        type: _type,
        priceMode: _priceMode,
        pricePercent: double.tryParse(_pricePercent.text) ?? 0,
        rebatePercent: double.tryParse(_rebate.text) ?? 0,
        cashbackPercent: double.tryParse(_cashback.text) ?? 0,
      ),
    );
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _name.clear();
      _type = 'regular';
      _priceMode = 'normal';
      _pricePercent.text = '0';
      _rebate.text = '0';
      _cashback.text = '0';
    });
  }
}
