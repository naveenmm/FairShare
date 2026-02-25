import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleAutoSave();
  }

  Future<void> _handleAutoSave() async {
    final provider = Provider.of<BillProvider>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 1500));
    provider.saveCurrentToHistory();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final provider = Provider.of<BillProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear All',
            onPressed: () => _confirmReset(context, provider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalCard(provider, theme),
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 20),
                const SizedBox(width: 8),
                Text('INDIVIDUAL SPLITS', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2, color: theme.colorScheme.outline)),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.people.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final person = provider.people[index];
                final subtotal = provider.getPersonSubtotal(person.id);
                final total = provider.getPersonTotal(person.id);
                final percentage = provider.grandTotal == 0 ? 0.0 : (total / provider.grandTotal) * 100;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(person.name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${total.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                                Text('${percentage.toStringAsFixed(1)}% of bill', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items base cost', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                            Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BillProvider provider, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text('Grand Total', style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('₹${provider.grandTotal.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 48, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _summaryRow('Subtotal', provider.subtotal, theme),
                const SizedBox(height: 12),
                _summaryRow('Tax', provider.tax, theme),
                const SizedBox(height: 12),
                _summaryRow('Discount', provider.discount, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.9), fontSize: 15)),
        Text('₹${value.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  void _confirmReset(BuildContext context, BillProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will reset the current bill. You can still find it in History later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.reset();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
