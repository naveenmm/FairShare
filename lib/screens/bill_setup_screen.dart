import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';

class BillSetupScreen extends StatelessWidget {
  const BillSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BillProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Items')),
      body: Column(
        children: [
          Expanded(
            child: provider.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text('No items added yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => provider.removeItem(item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                _InlineModifierRow(
                  label: 'Tax',
                  initialValue: provider.tax,
                  onChanged: (val) => provider.updateTax(val),
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _InlineModifierRow(
                  label: 'Discount',
                  initialValue: provider.discount,
                  onChanged: (val) => provider.updateDiscount(val),
                  theme: theme,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddItemDialog(context, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, BillProvider provider) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g., Pizza')),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final price = double.tryParse(priceController.text) ?? 0;
              if (nameController.text.isNotEmpty && price > 0) {
                provider.addItem(nameController.text, price);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _InlineModifierRow extends StatefulWidget {
  final String label;
  final double initialValue;
  final Function(double) onChanged;
  final ThemeData theme;

  const _InlineModifierRow({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_InlineModifierRow> createState() => _InlineModifierRowState();
}

class _InlineModifierRowState extends State<_InlineModifierRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue == 0 ? '' : widget.initialValue.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _InlineModifierRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if the value changed externally AND the user isn't currently typing
    if (widget.initialValue != oldWidget.initialValue) {
      final currentLocalVal = double.tryParse(_controller.text) ?? 0;
      if (currentLocalVal != widget.initialValue) {
        final text = widget.initialValue == 0 ? '' : widget.initialValue.toStringAsFixed(2);
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              height: 42,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (val) => widget.onChanged(double.tryParse(val) ?? 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
