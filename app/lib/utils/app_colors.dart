import 'package:flutter/material.dart';

class AppColors {
  // Brand — Kaamkaaz Blue
  static const Color primary = Color(0xFF1565C0); // Deep Blue
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Accent — Professional Gray/Blue
  static const Color accent = Color(0xFF1E88E5); // Bright Blue
  static const Color secondary = Color(0xFF455A64); // Blue Gray

  // Status
  static const Color success = Color(0xFF2E7D32); // Green
  static const Color danger = Color(0xFFD32F2F); // Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF1565C0); // Blue
  static const Color safetyOrange = Color(0xFFFF5F15); // Vibrant non-alarming action color

  // Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC); // Very light blue-gray
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF334155);
  static const Color textLight = Color(0xFF64748B);

  // Decorative
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
        color: const Color(0xFF1565C0).withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
        color: primary.withValues(alpha: 0.2),
        blurRadius: 16,
        offset: const Offset(0, 8)),
  ];

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primary],
  );

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF0D47A1)], // Blue to Dark Blue
  );

  static const Gradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, success],
  );

  // Job Categories
  static const Color construction = Color(0xFFE74C3C);
  static const Color farming = Color(0xFF2ECC71);
  static const Color cleaning = Color(0xFF3498DB);
  static const Color painting = Color(0xFFF39C12);
  static const Color plumbing = Color(0xFF9B59B6);
  static const Color electrical = Color(0xFFF1C40F);
  static const Color carpentry = Color(0xFFD35400);
  static const Color loading = Color(0xFF7F8C8D);
  static const Color cooking = Color(0xFFE91E8C);
  static const Color driving = Color(0xFF1ABC9C);
  static const Color security = Color(0xFF2C3E50);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'construction':
        return construction;
      case 'farming':
        return farming;
      case 'cleaning':
        return cleaning;
      case 'painting':
        return painting;
      case 'plumbing':
        return plumbing;
      case 'electrical':
        return electrical;
      case 'carpentry':
        return carpentry;
      case 'loading':
        return loading;
      case 'cooking':
        return cooking;
      case 'driving':
        return driving;
      case 'security':
        return security;
      default:
        return primary;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'construction':
        return Icons.construction_rounded;
      case 'farming':
        return Icons.agriculture_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'carpentry':
        return Icons.carpenter_rounded;
      case 'loading':
        return Icons.local_shipping_rounded;
      case 'cooking':
        return Icons.restaurant_rounded;
      case 'driving':
        return Icons.directions_car_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  static String getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'construction':
        return '🏗️';
      case 'farming':
        return '🌾';
      case 'cleaning':
        return '🧹';
      case 'painting':
        return '🎨';
      case 'plumbing':
        return '🔧';
      case 'electrical':
        return '⚡';
      case 'carpentry':
        return '🪚';
      case 'loading':
        return '📦';
      case 'cooking':
        return '🍳';
      case 'driving':
        return '🚗';
      case 'security':
        return '🛡️';
      default:
        return 'logo';
    }
  }
}
