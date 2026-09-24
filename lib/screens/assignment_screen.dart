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
              side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: InkWell(
              onTap: () =>
                  _showDetailedAdjustmentPopup(context, provider, item),
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
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('₹${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (item.totalShares > 0)
                          Chip(
                            label: Text(
                                '${item.totalShares.toInt()} total shares',
                                style: const TextStyle(fontSize: 12)),
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Toggle to assign 1 share:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.people.isEmpty
                          ? [
                              const Text('No people added',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic))
                            ]
                          : provider.people.map((person) {
                              final shares = item.assignments[person.id] ?? 0.0;
                              final isSelected = shares > 0;
                              return InkWell(
                                onTap: () {
                                  provider.assignItem(
                                      item.id, person.id, isSelected ? 0 : 1);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        person.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? theme.colorScheme
                                                  .onPrimaryContainer
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (shares > 1) ...[
                                        const SizedBox(width: 6),
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          child: Text(
                                            shares.toInt().toString(),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
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
                        Icon(Icons.tune,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Tap card to adjust specific shares',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
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

  void _showDetailedAdjustmentPopup(
      BuildContext context, BillProvider provider, Item item) {
    final theme = Theme.of(context);
    String selectedMode = item.splitMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
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
                          Text(
                            item.name,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Split mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'equal', label: Text('Equal')),
                      ButtonSegment(
                        value: 'percentage',
                        label: Text('Percent'),
                      ),
                      ButtonSegment(
                        value: 'exact',
                        label: Text('Exact'),
                      ),
                      ButtonSegment(
                        value: 'quantity',
                        label: Text('Qty'),
                      ),
                    ],
                    selected: {selectedMode},
                    onSelectionChanged: (newSelection) {
                      selectedMode = newSelection.first;
                      provider.setItemSplitMode(item.id, selectedMode);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  if (provider.people.isEmpty)
                    const Center(child: Text('Add people first'))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.people.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final person = provider.people[index];
                        final currentValue = item.assignments[person.id] ?? 0.0;
                        final isSelected = currentValue > 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                    .withOpacity(0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                child: Text(
                                  person.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  person.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  key: ValueKey(
                                    '${person.id}-${item.id}-${selectedMode}-${currentValue}',
                                  ),
                                  initialValue: _formatSplitValue(
                                    currentValue,
                                    selectedMode,
                                  ),
                                  textAlign: TextAlign.end,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                    prefixText:
                                        selectedMode == 'exact' ? '₹ ' : null,
                                    suffixText: selectedMode == 'percentage'
                                        ? '%'
                                        : selectedMode == 'quantity'
                                            ? 'qty'
                                            : selectedMode == 'equal'
                                                ? 'sh'
                                                : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final parsed =
                                        double.tryParse(value) ?? 0.0;
                                    provider.assignItem(
                                      item.id,
                                      person.id,
                                      parsed < 0 ? 0 : parsed,
                                    );
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.done),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatSplitValue(double value, String mode) {
    switch (mode) {
      case 'percentage':
        return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
      case 'exact':
        return value.toStringAsFixed(2);
      case 'quantity':
        return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
      case 'equal':
      default:
        return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    }
  }

  Widget _shareBtnSmall(
      IconData icon, VoidCallback? onPressed, ThemeData theme) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onPressed == null
              ? Colors.transparent
              : theme.colorScheme.primary.withOpacity(0.1),
        ),
        child: Icon(icon,
            size: 18,
            color: onPressed == null
                ? Colors.grey.withOpacity(0.5)
                : theme.colorScheme.primary),
      ),
    );
  }
}
