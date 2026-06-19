import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/settings_provider.dart';

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
    final String currency = context.watch<SettingsProvider>().currencySymbol;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF0F5132), Color(0xFF1F7A4D)],
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
                        'Set customer type, price rules, office rebate, doctor cashback defaults, and view outstanding credit.',
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
          const _CustomerFieldGuide(),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _editingId == null ? 'Add Customer Profile' : 'Edit Customer Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            helperText: 'Customer, doctor, clinic, office, or pharmacy name.',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String>('customer-type-$_type'),
                          initialValue: _type,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'regular',
                              child: Text('Regular Customer'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'office',
                              child: Text('Office / Pharmacy'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'doctor',
                              child: Text('Doctor'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() => _type = value ?? 'regular');
                          },
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            helperText: 'Used to identify which sale rule applies.',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 270,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey<String>('price-mode-$_priceMode'),
                          initialValue: _priceMode,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'normal',
                              child: Text('Normal Product Price'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'same_buying',
                              child: Text('Use Saved Product Price'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'adjust_selling_percent',
                              child: Text('Adjust Product Price by %'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _priceMode = value ?? 'normal';
                              if (_priceMode != 'adjust_selling_percent') {
                                _pricePercent.text = '0';
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Price Mode',
                            helperText: 'Choose how the POS calculates this customer’s default price.',
                            prefixIcon: Icon(Icons.price_change_outlined),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: TextField(
                          controller: _pricePercent,
                          enabled: _priceMode == 'adjust_selling_percent',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price Adjustment %',
                            helperText: '10 = add 10%. Use 0 when no adjustment is needed.',
                            prefixIcon: Icon(Icons.percent_outlined),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: TextField(
                          controller: _rebate,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Office Rebate %',
                            helperText: 'Discount applied to Office sales. Example: 2 = 2%.',
                            prefixIcon: Icon(Icons.discount_outlined),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 235,
                        child: TextField(
                          controller: _cashback,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Default Doctor Cashback %',
                            helperText: 'Starting suggestion only; it can be adjusted per sale.',
                            prefixIcon: Icon(Icons.redeem_outlined),
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
                      final CustomerModel customer = provider.customers[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              customer.type == 'doctor'
                                  ? Icons.medical_services_outlined
                                  : customer.type == 'office'
                                      ? Icons.business_outlined
                                      : Icons.person_outline,
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'Type: ${_typeLabel(customer.type)} | Price Mode: ${_priceModeLabel(customer.priceMode)}'
                            '\nPrice Adjustment: ${customer.pricePercent}% | Office Rebate: ${customer.rebatePercent}% | Default Doctor Cashback: ${customer.cashbackPercent}%'
                            '\nOutstanding Credit: ${Formatters.money(customer.creditBalance, symbol: currency)}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _editingId = customer.id;
                                    _name.text = customer.name;
                                    _type = customer.type;
                                    _priceMode = customer.priceMode;
                                    _pricePercent.text = customer.pricePercent.toString();
                                    _rebate.text = customer.rebatePercent.toString();
                                    _cashback.text = customer.cashbackPercent.toString();
                                  });
                                },
                                child: const Text('Edit'),
                              ),
                              OutlinedButton(
                                onPressed: customer.creditBalance > 0
                                    ? null
                                    : () => provider.delete(customer.id!),
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
    if (_name.text.trim().isEmpty) {
      _showMessage('Name is required');
      return;
    }

    final double pricePercent = double.tryParse(_pricePercent.text) ?? 0;
    final double rebatePercent = double.tryParse(_rebate.text) ?? 0;
    final double cashbackPercent = double.tryParse(_cashback.text) ?? 0;

    if (rebatePercent < 0 || rebatePercent > 100) {
      _showMessage('Office Rebate % must be between 0 and 100');
      return;
    }
    if (cashbackPercent < 0 || cashbackPercent > 100) {
      _showMessage('Default Doctor Cashback % must be between 0 and 100');
      return;
    }

    final CustomerProvider provider = context.read<CustomerProvider>();
    await provider.save(
      CustomerModel(
        id: _editingId,
        name: _name.text.trim(),
        type: _type,
        priceMode: _priceMode,
        pricePercent:
            _priceMode == 'adjust_selling_percent' ? pricePercent : 0,
        rebatePercent: rebatePercent,
        cashbackPercent: cashbackPercent,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _typeLabel(String value) {
    switch (value) {
      case 'office':
        return 'Office / Pharmacy';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Regular Customer';
    }
  }

  String _priceModeLabel(String value) {
    switch (value) {
      case 'adjust_selling_percent':
        return 'Adjust Product Price by %';
      case 'same_buying':
        return 'Use Saved Product Price';
      default:
        return 'Normal Product Price';
    }
  }
}

class _CustomerFieldGuide extends StatelessWidget {
  const _CustomerFieldGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.help_outline),
        title: const Text(
          'What do these fields mean?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Open this guide when adding a customer profile.'),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: const <Widget>[
          _GuideRow(
            title: 'Name',
            text: 'The customer, doctor, clinic, office, or pharmacy name.',
          ),
          _GuideRow(
            title: 'Type',
            text: 'Regular = normal customer, Office = rebate/office rules, Doctor = doctor cashback workflow.',
          ),
          _GuideRow(
            title: 'Price Mode',
            text: 'Normal uses the product price. Adjust Product Price by % changes the default price for this customer.',
          ),
          _GuideRow(
            title: 'Price Adjustment %',
            text: 'Used only with Adjust Product Price by %. Example: 10 means the product price increases by 10%.',
          ),
          _GuideRow(
            title: 'Office Rebate %',
            text: 'A percentage discount calculated for Office sales. Leave it at 0 when no rebate is used.',
          ),
          _GuideRow(
            title: 'Default Doctor Cashback %',
            text: 'A starting cashback suggestion for Doctor Cashback sales. The amount can still be changed on each sale.',
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 205,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
