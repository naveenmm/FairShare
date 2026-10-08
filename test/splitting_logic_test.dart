import 'package:flutter_test/flutter_test.dart';
import 'package:split_bills/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BillProvider Logic Tests', () {
    test('Basic splitting between two people', () {
      final provider = BillProvider();

      provider.addPerson('Alice'); // id1
      provider.addPerson('Bob'); // id2

      final aliceId = provider.people[0].id;
      final bobId = provider.people[1].id;

      provider.addItem('Pizza', 20.0);
      final pizzaId = provider.items[0].id;

      // Split pizza equally
      provider.assignItem(pizzaId, aliceId, 1.0);
      provider.assignItem(pizzaId, bobId, 1.0);

      expect(provider.subtotal, 20.0);
      expect(provider.getPersonSubtotal(aliceId), 10.0);
      expect(provider.getPersonSubtotal(bobId), 10.0);
    });

    test('Splitting with custom shares', () {
      final provider = BillProvider();

      provider.addPerson('Alice');
      provider.addPerson('Bob');

      final aliceId = provider.people[0].id;
      final bobId = provider.people[1].id;

      provider.addItem('Wine', 30.0);
      final wineId = provider.items[0].id;

      // Alice has 2 shares, Bob has 1 share
      provider.assignItem(wineId, aliceId, 2.0);
      provider.assignItem(wineId, bobId, 1.0);

      expect(provider.getPersonSubtotal(aliceId), 20.0);
      expect(provider.getPersonSubtotal(bobId), 10.0);
    });

    test('Proportional tax and discount distribution', () {
      final provider = BillProvider();

      provider.addPerson('Alice');
      provider.addPerson('Bob');

      final aliceId = provider.people[0].id;
      final bobId = provider.people[1].id;

      provider.addItem('Steak', 20.0); // Alice
      provider.addItem('Salad', 10.0); // Bob

      final steakId = provider.items[0].id;
      final saladId = provider.items[1].id;

      provider.assignItem(steakId, aliceId, 1.0);
      provider.assignItem(saladId, bobId, 1.0);

      provider.updateTax(3.0); // 10% tax
      provider.updateDiscount(6.0); // 20% discount

      // Alice: Subtotal 20, Tax 2, Discount 4 -> Total 18
      // Bob: Subtotal 10, Tax 1, Discount 2 -> Total 9

      expect(provider.getPersonTax(aliceId), 2.0);
      expect(provider.getPersonTax(bobId), 1.0);
      expect(provider.getPersonDiscount(aliceId), 4.0);
      expect(provider.getPersonDiscount(bobId), 2.0);
      expect(provider.getPersonTotal(aliceId), 18.0);
      expect(provider.getPersonTotal(bobId), 9.0);
      expect(provider.grandTotal, 27.0);
    });

    test('Duplicate people are rejected', () {
      final provider = BillProvider();

      expect(provider.addPerson('Alice'), isTrue);
      expect(provider.addPerson('alice'), isFalse);
      expect(provider.people.length, 1);
    });

    test('Percentage and exact split modes calculate correctly', () {
      final provider = BillProvider();

      provider.addPerson('Alice');
      provider.addPerson('Bob');
      final aliceId = provider.people[0].id;
      final bobId = provider.people[1].id;

      provider.addItem('Dinner', 100.0);
      final itemId = provider.items[0].id;

      provider.setItemSplitMode(itemId, 'percentage');
      provider.assignItem(itemId, aliceId, 25.0);
      provider.assignItem(itemId, bobId, 75.0);

      expect(provider.getPersonSubtotal(aliceId), 25.0);
      expect(provider.getPersonSubtotal(bobId), 75.0);

      provider.setItemSplitMode(itemId, 'exact');
      provider.assignItem(itemId, aliceId, 40.0);
      provider.assignItem(itemId, bobId, 60.0);

      expect(provider.getPersonSubtotal(aliceId), 40.0);
      expect(provider.getPersonSubtotal(bobId), 60.0);
    });

    test('Saved bills preserve modification timestamps and read legacy data',
        () {
      final date = DateTime.utc(2026, 1, 1);
      final updatedAt = DateTime.utc(2026, 1, 2);
      final bill = SavedBill(
        id: 'bill-1',
        date: date,
        updatedAt: updatedAt,
        people: const [],
        items: const [],
        tax: 0,
        discount: 0,
        total: 0,
      );
      final restored = SavedBill.fromJson(bill.toJson());
      final legacyJson = bill.toJson()..remove('updatedAt');
      final legacy = SavedBill.fromJson(legacyJson);

      expect(restored.updatedAt, updatedAt);
      expect(legacy.updatedAt, date);
    });
  });
}
