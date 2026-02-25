import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BillProvider>(context);
    final theme = Theme.of(context);

    if (provider.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign Items')),
        body: const Center(child: Text('Add items first')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Items')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.items.length,
        itemBuilder: (context, index) {
          final item = provider.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: InkWell(
              onTap: () => _showDetailedAdjustmentPopup(context, provider, item),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (item.totalShares > 0)
                          Chip(
                            label: Text('${item.totalShares.toInt()} total shares', style: const TextStyle(fontSize: 12)),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Toggle to assign 1 share:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.people.isEmpty
                          ? [const Text('No people added', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))]
                          : provider.people.map((person) {
                              final shares = item.assignments[person.id] ?? 0.0;
                              final isSelected = shares > 0;
                              return InkWell(
                                onTap: () {
                                   provider.assignItem(item.id, person.id, isSelected ? 0 : 1);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.colorScheme.primaryContainer : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        person.name,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (shares > 1) ...[
                                        const SizedBox(width: 6),
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: theme.colorScheme.primary,
                                          child: Text(
                                            shares.toInt().toString(),
                                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Tap card to adjust specific shares', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetailedAdjustmentPopup(BuildContext context, BillProvider provider, Item item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text('₹${item.price.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Adjust Multiple Shares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: provider.people.isEmpty
                        ? const Center(child: Text('Add people first'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.people.length,
                            itemBuilder: (context, index) {
                              final person = provider.people[index];
                              final currentShare = item.assignments[person.id] ?? 0.0;
                              final isSelected = currentShare > 0;

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                      child: Text(person.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(person.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _shareBtnSmall(Icons.remove, isSelected ? () {
                                          provider.assignItem(item.id, person.id, (currentShare - 1).clamp(0, 99).toDouble());
                                          setModalState(() {});
                                        } : null, theme),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(currentShare.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        _shareBtnSmall(Icons.add, () {
                                          provider.assignItem(item.id, person.id, (currentShare + 1).toDouble());
                                          setModalState(() {});
                                        }, theme),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shareBtnSmall(IconData icon, VoidCallback? onPressed, ThemeData theme) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed == null ? Colors.transparent : theme.colorScheme.primary.withOpacity(0.1),
        ),
        child: Icon(icon, size: 18, color: onPressed == null ? Colors.grey.withOpacity(0.5) : theme.colorScheme.primary),
      ),
    );
  }
}
