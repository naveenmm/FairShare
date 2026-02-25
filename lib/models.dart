import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Person {
  final String id;
  final String name;

  Person({String? id, required this.name}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Person.fromJson(Map<String, dynamic> json) => Person(id: json['id'], name: json['name']);
}

class Item {
  final String id;
  String name;
  double price;
  Map<String, double> assignments;

  Item({
    String? id,
    required this.name,
    required this.price,
    Map<String, double>? assignments,
  })  : id = id ?? const Uuid().v4(),
        assignments = assignments ?? {};

  double get totalShares => assignments.values.fold(0.0, (sum, share) => sum + share);
  double getShareFor(String personId) => assignments[personId] ?? 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'assignments': assignments,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        assignments: Map<String, double>.from(json['assignments'] ?? {}),
      );
}

class SavedBill {
  final String id;
  final DateTime date;
  final List<Person> people;
  final List<Item> items;
  final double tax;
  final double discount;
  final double total;

  SavedBill({
    String? id,
    required this.date,
    required this.people,
    required this.items,
    required this.tax,
    required this.discount,
    required this.total,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'people': people.map((p) => p.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'tax': tax,
        'discount': discount,
        'total': total,
      };

  factory SavedBill.fromJson(Map<String, dynamic> json) => SavedBill(
        id: json['id'],
        date: DateTime.parse(json['date']),
        people: (json['people'] as List).map((p) => Person.fromJson(p)).toList(),
        items: (json['items'] as List).map((i) => Item.fromJson(i)).toList(),
        tax: (json['tax'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

class BillProvider extends ChangeNotifier {
  List<Person> _people = [];
  List<Item> _items = [];
  double _tax = 0.0;
  double _discount = 0.0;
  List<SavedBill> _history = [];
  String? _currentBillId;
  Set<String> _savedPeople = {};

  BillProvider() {
    _loadState();
  }

  List<Person> get people => _people;
  List<Item> get items => _items;
  double get tax => _tax;
  double get discount => _discount;
  List<SavedBill> get history => _history;
  Set<String> get savedPeople => _savedPeople;
  String? get currentBillId => _currentBillId;

  // Persistence
  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load History
    final historyJson = prefs.getString('bill_history');
    if (historyJson != null) {
      final List decoded = jsonDecode(historyJson);
      _history = decoded.map((j) => SavedBill.fromJson(j)).toList();
      _history.sort((a, b) => b.date.compareTo(a.date));
    }

    // Load Saved People
    final peopleNames = prefs.getStringList('saved_people');
    if (peopleNames != null) {
      _savedPeople = Set.from(peopleNames);
    }
    
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_history.map((h) => h.toJson()).toList());
    await prefs.setString('bill_history', historyJson);
  }

  Future<void> _savePeople() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_people', _savedPeople.toList());
  }

  void saveCurrentToHistory() {
    if (grandTotal <= 0 && _items.isEmpty && _people.isEmpty) return;
    
    final bill = SavedBill(
      id: _currentBillId, // Use existing ID if editing
      date: DateTime.now(),
      people: List.from(_people),
      items: List.from(_items),
      tax: _tax,
      discount: _discount,
      total: grandTotal,
    );

    if (_currentBillId != null) {
      // Overwrite existing
      final index = _history.indexWhere((h) => h.id == _currentBillId);
      if (index != -1) {
        _history[index] = bill;
      } else {
        _history.insert(0, bill);
      }
    } else {
      // New bill
      _history.insert(0, bill);
      _currentBillId = bill.id; // Now we are editing this bill
    }
    
    _saveHistory();
    notifyListeners();
  }

  void startNewBill() {
    _people = [];
    _items = [];
    _tax = 0.0;
    _discount = 0.0;
    _currentBillId = null;
    notifyListeners();
  }

  void loadBill(SavedBill bill) {
    _people = List.from(bill.people);
    _items = List.from(bill.items);
    _tax = bill.tax;
    _discount = bill.discount;
    _currentBillId = bill.id;
    notifyListeners();
  }

  void deleteHistoryItem(String id) {
    if (_currentBillId == id) {
      _currentBillId = null;
    }
    _history.removeWhere((h) => h.id == id);
    _saveHistory();
    notifyListeners();
  }

  void addPerson(String name) {
    _people.add(Person(name: name));
    _savedPeople.add(name);
    _savePeople();
    notifyListeners();
  }

  void addMultiplePeople(int count) {
    final startId = _people.where((p) => p.name.startsWith('Person ')).length + 1;
    for (int i = 0; i < count; i++) {
        final name = 'Person ${startId + i}';
        _people.add(Person(name: name));
        _savedPeople.add(name);
    }
    _savePeople();
    notifyListeners();
  }

  void removePerson(String id) {
    _people.removeWhere((p) => p.id == id);
    for (var item in _items) {
      item.assignments.remove(id);
    }
    notifyListeners();
  }

  void addItem(String name, double price) {
    _items.add(Item(name: name, price: price));
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateTax(double tax) {
    _tax = tax;
    notifyListeners();
  }

  void updateDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }

  void reset() {
    _people = [];
    _items = [];
    _tax = 0.0;
    _discount = 0.0;
    notifyListeners();
  }

  void assignItem(String itemId, String personId, double shares) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      if (shares <= 0) {
        _items[itemIndex].assignments.remove(personId);
      } else {
        _items[itemIndex].assignments[personId] = shares;
      }
      notifyListeners();
    }
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.price);

  double getPersonSubtotal(String personId) {
    double personSubtotal = 0.0;
    for (var item in _items) {
      final totalShares = item.totalShares;
      if (totalShares > 0 && item.assignments.containsKey(personId)) {
        personSubtotal += (item.price * item.assignments[personId]! / totalShares);
      }
    }
    return personSubtotal;
  }

  double getPersonTax(String personId) {
    final totalSubtotal = subtotal;
    if (totalSubtotal == 0) return 0.0;
    return (getPersonSubtotal(personId) / totalSubtotal) * _tax;
  }

  double getPersonDiscount(String personId) {
    final totalSubtotal = subtotal;
    if (totalSubtotal == 0) return 0.0;
    return (getPersonSubtotal(personId) / totalSubtotal) * _discount;
  }

  double getPersonTotal(String personId) {
    return getPersonSubtotal(personId) + getPersonTax(personId) - getPersonDiscount(personId);
  }

  double get grandTotal => subtotal + _tax - _discount;
}
