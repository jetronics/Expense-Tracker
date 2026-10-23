import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> kWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Icons are stored by key so release builds can tree-shake the icon font.
final Map<String, IconData> kIcons = {
  'food': Icons.restaurant,
  'shopping': Icons.shopping_cart,
  'transport': Icons.directions_bus,
  'home': Icons.home,
  'bills': Icons.receipt,
  'health': Icons.local_hospital,
  'fun': Icons.movie,
  'education': Icons.school,
  'gift': Icons.card_giftcard,
  'travel': Icons.flight,
  'pets': Icons.pets,
  'work': Icons.work,
  'savings': Icons.savings,
  'money': Icons.attach_money,
  'label': Icons.label,
};

final List<Color> kPalette = [
  Colors.red.shade400,
  Colors.pink.shade400,
  Colors.purple.shade400,
  Colors.indigo.shade400,
  Colors.blue.shade500,
  Colors.teal.shade500,
  Colors.green.shade500,
  Colors.lime.shade700,
  Colors.orange.shade500,
  Colors.deepOrange.shade400,
  Colors.brown.shade400,
  Colors.blueGrey.shade500,
];

class Category {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool income;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.income,
  });

  IconData get iconData => kIcons[icon] ?? Icons.label;
  Color get colorValue => kPalette[color % kPalette.length];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'income': income,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        icon: j['icon'] as String,
        color: j['color'] as int,
        income: j['income'] as bool,
      );
}

const List<Category> kDefaultCategories = [
  Category(id: 'food', name: 'Food & Drinks', icon: 'food', color: 8, income: false),
  Category(id: 'shopping', name: 'Shopping', icon: 'shopping', color: 1, income: false),
  Category(id: 'transport', name: 'Transport', icon: 'transport', color: 4, income: false),
  Category(id: 'home', name: 'Home & Rent', icon: 'home', color: 10, income: false),
  Category(id: 'bills', name: 'Bills & Utilities', icon: 'bills', color: 3, income: false),
  Category(id: 'health', name: 'Health', icon: 'health', color: 0, income: false),
  Category(id: 'fun', name: 'Entertainment', icon: 'fun', color: 2, income: false),
  Category(id: 'education', name: 'Education', icon: 'education', color: 5, income: false),
  Category(id: 'gifts', name: 'Gifts', icon: 'gift', color: 9, income: false),
  Category(id: 'other_exp', name: 'Other', icon: 'label', color: 11, income: false),
  Category(id: 'salary', name: 'Salary', icon: 'work', color: 6, income: true),
  Category(id: 'business', name: 'Business', icon: 'money', color: 7, income: true),
  Category(id: 'gift_in', name: 'Gifts', icon: 'gift', color: 9, income: true),
  Category(id: 'other_inc', name: 'Other', icon: 'label', color: 11, income: true),
];

class Txn {
  final String id;
  final double amount;
  final bool income;
  final String categoryId;
  final String note;
  final DateTime date;

  const Txn({
    required this.id,
    required this.amount,
    required this.income,
    required this.categoryId,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'income': income,
        'categoryId': categoryId,
        'note': note,
        'date': date.millisecondsSinceEpoch,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        income: j['income'] as bool,
        categoryId: j['categoryId'] as String,
        note: (j['note'] as String?) ?? '',
        date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
      );
}

String money(double v, String cur) {
  final neg = v < 0;
  final parts = v.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '${neg ? '-' : ''}$cur$whole.${parts[1]}';
}

String fmtDate(DateTime d) =>
    '${kMonths[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';

String dayHeader(DateTime d) =>
    '${kWeekdays[d.weekday - 1]}, ${kMonths[d.month - 1].substring(0, 3)} ${d.day}';

class Store extends ChangeNotifier {
  List<Category> categories = List<Category>.of(kDefaultCategories);
  List<Txn> txns = [];
  Map<String, double> budgets = {};
  String currency = '\$';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    currency = p.getString('currency') ?? '\$';
    final raw = p.getString('data');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final cats = (j['categories'] as List)
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (cats.isNotEmpty) categories = cats;
      txns = (j['txns'] as List)
          .map((e) => Txn.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      budgets = (j['budgets'] as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    } catch (_) {
      // Corrupt data: keep defaults.
    }
  }

  Future<void> _commit() async {
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('currency', currency);
    await p.setString(
      'data',
      jsonEncode({
        'categories': categories.map((c) => c.toJson()).toList(),
        'txns': txns.map((t) => t.toJson()).toList(),
        'budgets': budgets,
      }),
    );
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Category cat(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return const Category(
        id: '?', name: 'Uncategorized', icon: 'label', color: 11, income: false);
  }

  Future<void> addTxn(Txn t) {
    txns.add(t);
    return _commit();
  }

  Future<void> updateTxn(Txn t) {
    final i = txns.indexWhere((x) => x.id == t.id);
    if (i >= 0) txns[i] = t;
    return _commit();
  }

  Future<void> deleteTxn(String id) {
    txns.removeWhere((t) => t.id == id);
    return _commit();
  }

  Future<void> setBudget(String catId, double v) {
    if (v <= 0) {
      budgets.remove(catId);
    } else {
      budgets[catId] = v;
    }
    return _commit();
  }

  Future<void> addCategory(Category c) {
    categories.add(c);
    return _commit();
  }

  Future<void> deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id);
    budgets.remove(id);
    return _commit();
  }

  Future<void> setCurrency(String c) {
    currency = c.isEmpty ? '\$' : c;
    return _commit();
  }

  Future<void> clearAll() {
    txns = [];
    budgets = {};
    categories = List<Category>.of(kDefaultCategories);
    return _commit();
  }

  List<Txn> monthTxns(DateTime m) {
    final l = txns
        .where((t) => t.date.year == m.year && t.date.month == m.month)
        .toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  double incomeOf(DateTime m) => monthTxns(m)
      .where((t) => t.income)
      .fold<double>(0, (a, t) => a + t.amount);

  double expenseOf(DateTime m) => monthTxns(m)
      .where((t) => !t.income)
      .fold<double>(0, (a, t) => a + t.amount);

  double spentIn(String catId, DateTime m) => monthTxns(m)
      .where((t) => !t.income && t.categoryId == catId)
      .fold<double>(0, (a, t) => a + t.amount);
}
