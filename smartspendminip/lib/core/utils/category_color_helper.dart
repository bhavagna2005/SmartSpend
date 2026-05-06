import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryColorHelper {
  static final Map<String, Color> _fixedColors = {
    'Food': AppColors.foodGreen,
    'Transport': AppColors.transportBlue,
    'Shopping': AppColors.shoppingOrange,
    'Entertainment': AppColors.entertainmentPurple,
    'Bills': AppColors.expenseRed,
    'Rent': const Color(0xFF5C6BC0),
    'Health': const Color(0xFF66BB6A),
    'Education': const Color(0xFF26C6DA),
    'Investment': const Color(0xFFFFCA28),
    'Travel': const Color(0xFF7E57C2),
    'Misc': AppColors.textGrey,
  };

  static final List<Color> _dynamicPalette = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD93D),
    const Color(0xFF6C5CE7),
    const Color(0xFFA29BFE),
    const Color(0xFF81ECEC),
    const Color(0xFF74B9FF),
    const Color(0xFFFAB1A0),
    const Color(0xFFFF7675),
    const Color(0xFFFD79A8),
    const Color(0xFF55E6C1),
    const Color(0xFF25CCF7),
    const Color(0xFFFD7272),
    const Color(0xFF58B19F),
    const Color(0xFFF368E0),
  ];

  static Color getColor(String category) {
    if (_fixedColors.containsKey(category)) {
      return _fixedColors[category]!;
    }
    
    // Hash the category name to pick a stable color from the palette
    int hash = 0;
    for (int i = 0; i < category.length; i++) {
        hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return _dynamicPalette[hash.abs() % _dynamicPalette.length];
  }
}
