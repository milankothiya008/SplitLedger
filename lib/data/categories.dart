import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final String icon;
  const ExpenseCategory(this.name, this.icon);

  String get asset => 'assets/icons/$icon';
}

/// Names must stay stable: they are stored as-is in Firestore.
const List<ExpenseCategory> kCategories = [
  ExpenseCategory('Food', 'food.png'),
  ExpenseCategory('Grocery', 'grocery.png'),
  ExpenseCategory('Transport', 'transportation.png'),
  ExpenseCategory('Petrol', 'petrol.png'),
  ExpenseCategory('Shopping', 'shopping.png'),
  ExpenseCategory('Clothing', 'clothing.png'),
  ExpenseCategory('Health', 'health.png'),
  ExpenseCategory('Education', 'education.png'),
  ExpenseCategory('Fees', 'fees.png'),
  ExpenseCategory('Recharge', 'recharge.png'),
  ExpenseCategory('Entertainment', 'entertainment.png'),
  ExpenseCategory('Movie', 'movie.png'),
  ExpenseCategory('Snacks', 'snacks.png'),
  ExpenseCategory('Travel', 'travel.png'),
  ExpenseCategory('Friends', 'friends.png'),
  ExpenseCategory('Party', 'party.png'),
  ExpenseCategory('Social', 'social.png'),
  ExpenseCategory('Birthday', 'birthday.png'),
  ExpenseCategory('Gifts', 'gifts.png'),
  ExpenseCategory('Beauty', 'beauty.png'),
  ExpenseCategory('Gym', 'gym.png'),
  ExpenseCategory('Sports', 'sport.png'),
  ExpenseCategory('Children', 'children.png'),
  ExpenseCategory('Pet', 'pet.png'),
  ExpenseCategory('Homedecor', 'homedecor.png'),
  ExpenseCategory('Repairing', 'repair.png'),
  ExpenseCategory('Investments', 'investments.png'),
  ExpenseCategory('Donation', 'donation.png'),
  ExpenseCategory('Others', 'others.png'),
];

final Map<String, ExpenseCategory> _byName = {for (final c in kCategories) c.name: c};

String categoryAsset(String name) => (_byName[name] ?? _byName['Others']!).asset;

/// Distinct, colour-blind-friendlier palette for charts.
const List<Color> kChartPalette = [
  Color(0xFF3F51B5),
  Color(0xFF00A3A3),
  Color(0xFFF59E0B),
  Color(0xFFE5484D),
  Color(0xFF8E4EC6),
  Color(0xFF30A46C),
  Color(0xFF0091FF),
  Color(0xFFF76B15),
  Color(0xFFD6409F),
  Color(0xFF6E56CF),
  Color(0xFF12A594),
  Color(0xFF978365),
];

Color chartColor(int index) => kChartPalette[index % kChartPalette.length];
