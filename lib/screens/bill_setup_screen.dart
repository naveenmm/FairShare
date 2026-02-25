import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../services/ocr_service.dart';

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
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!kIsWeb) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Scan Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: () => _handleScan(context, provider),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('New Item', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showAddItemDialog(context, provider),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScan(BuildContext context, BillProvider provider) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await picker.pickImage(source: source);
      if (image != null) {
        if (!context.mounted) return;
        _showScanReviewDialog(context, provider, image.path);
      }
    }
  }

  void _showScanReviewDialog(BuildContext context, BillProvider provider, String imagePath) {
    final ocrService = OCRService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<List<ScannedItem>>(
        future: ocrService.scanBill(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing bill...'),
                ],
              ),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return AlertDialog(
              title: const Text('No Items Found'),
              content: const Text('We couldn\'t recognize any items. Try a clearer photo or add items manually.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            );
          }

          final scannedItems = snapshot.data!;
          final selectedItems = List<bool>.filled(scannedItems.length, true);

          return StatefulBuilder(
            builder: (context, setModalState) => AlertDialog(
              title: const Text('Review Scanned Items'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: scannedItems.length,
                  itemBuilder: (context, index) {
                    final item = scannedItems[index];
                    return CheckboxListTile(
                      title: Text(item.name),
                      subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                      value: selectedItems[index],
                      onChanged: (val) => setModalState(() => selectedItems[index] = val!),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    for (int i = 0; i < scannedItems.length; i++) {
                      if (selectedItems[i]) {
                        provider.addItem(scannedItems[i].name, scannedItems[i].price);
                      }
                    }
                    Navigator.pop(context);
                    ocrService.dispose();
                  },
                  child: const Text('Add Selected'),
                ),
              ],
            ),
          );
        },
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
