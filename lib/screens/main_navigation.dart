import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import 'bill_setup_screen.dart';
import 'participants_screen.dart';
import 'assignment_screen.dart';
import 'summary_screen.dart';
import 'history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 4;

  static const List<Widget> _screens = [
    BillSetupScreen(),
    ParticipantsScreen(),
    AssignmentScreen(),
    SummaryScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
    });
  }

  void _checkInitialState() {
    final provider = Provider.of<BillProvider>(context, listen: false);
    if (provider.history.isEmpty && provider.items.isEmpty) {
      _showNewBillPopup();
    }
  }

  void _showNewBillPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Welcome!'),
        content: const Text('Would you like to start a new bill?'),
        actions: [
          if (Provider.of<BillProvider>(context, listen: false).history.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          TextButton(
            onPressed: () {
              Provider.of<BillProvider>(context, listen: false).startNewBill();
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
            child: const Text('Start New Bill'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Items'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Assign'),
            NavigationDestination(icon: Icon(Icons.summarize_outlined), selectedIcon: Icon(Icons.summarize), label: 'Summary'),
            NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 4
          ? FloatingActionButton.extended(
              onPressed: _showNewBillPopup,
              icon: const Icon(Icons.add),
              label: const Text('New Bill'),
            )
          : null,
    );
  }
}
