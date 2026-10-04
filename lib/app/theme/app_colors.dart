import 'package:flutter/material.dart';

class AppColors {
  // Mihan Store Brand Theme (Mirrored from mihan-store-web)
  static const Color primaryPurple = Color(0xFF7E22CE); // purple-700
  static const Color purpleLight = Color(0xFF9333EA);   // purple-600
  static const Color purpleDark = Color(0xFF6B21A8);    // purple-800
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);

  // Gradient Header
  static const List<Color> purpleGradient = [
    Color(0xFF9333EA), // from-purple-600
    Color(0xFF6B21A8), // to-purple-800
  ];

  // Image Placeholder Gradient (from-pink-400 to-red-500)
  static const List<Color> imageGradient = [
    Color(0xFFF472B6), // pink-400
    Color(0xFFEF4444), // red-500
  ];

  // Wholesale / Tier Badge Colors (Amber)
  static const Color amberBadgeBg = Color(0xFFFEF3C7);     // amber-100
  static const Color amberBadgeBorder = Color(0xFFFCD34D); // amber-300
  static const Color amberBadgeText = Color(0xFF78350F);   // amber-900
  static const Color amberBadgeHover = Color(0xFFFDE68A);  // amber-200
  static const Color amberAccordionBg = Color(0xFFFFFBEB); // amber-50
  static const Color amberAccordionBorder = Color(0xFFFDE68A); // amber-200

  // General / Neutral Colors
  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color cardBg = Colors.white;
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1F2937);  // gray-800
  static const Color textMuted = Color(0xFF4B5563); // gray-600
  static const Color textLight = Color(0xFF6B7280); // gray-500
  static const Color border = Color(0xFFE5E7EB);    // gray-200
  static const Color borderInput = Color(0xFFD1D5DB); // gray-300

  // Feedback Colors
  static const Color successGreen = Color(0xFF16A34A); // green-600
  static const Color errorRed = Color(0xFFDC2626);     // red-600

  // Legacy Invoice Colors
  static const Color primaryYellow = Color(0xFFFFE066);
  static const Color primaryDark = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color red = Color(0xFFE53935);
  static const Color green = Color(0xFF43A047);

  // Status Colors
  static const Color slotAvailable = Colors.white;
  static const Color slotBlocked = Color(0xFFF5F5F5);
  static const Color slotSelected = Color(0xFFFFF9C4); // Light yellow
  static const Color slotOccupied = Color(0xFFE0E0E0);
}
