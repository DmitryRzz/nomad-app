import 'package:flutter/material.dart';

class SunsetColors {
  // Primary gradient colors
  static const Color sunsetRed = Color(0xFFFF6B6B);
  static const Color sunsetYellow = Color(0xFFFECA57);
  static const Color sunsetPink = Color(0xFFFF9FF3);
  static const Color sunsetBlue = Color(0xFF54A0FF);
  
  // Background
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardBg = Color(0xFFD9D9D9);
  static const Color glassBg = Color(0x26FFFFFF); // 15% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  
  // Text
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLightMuted = Color(0x99FFFFFF); // 60% white
  
  // Accent
  static const Color accent = sunsetRed;
  static const Color accentLight = Color(0xFFFF8585);
}

class SunsetGradients {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      SunsetColors.sunsetRed,
      SunsetColors.sunsetYellow,
      SunsetColors.sunsetPink,
      SunsetColors.sunsetBlue,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );
  
  static const LinearGradient primary = LinearGradient(
    colors: [SunsetColors.sunsetRed, SunsetColors.sunsetPink],
  );
  
  static const LinearGradient sunsetOrb = LinearGradient(
    colors: [SunsetColors.sunsetRed, SunsetColors.sunsetYellow, SunsetColors.sunsetPink],
  );
  
  static const LinearGradient cardBorder = LinearGradient(
    colors: [SunsetColors.sunsetRed, SunsetColors.sunsetYellow, SunsetColors.sunsetPink],
  );
  
  static const LinearGradient activeNav = LinearGradient(
    colors: [SunsetColors.sunsetRed, SunsetColors.sunsetPink],
  );
}

class SunsetStyles {
  static BoxDecoration glassCard = BoxDecoration(
    color: SunsetColors.glassBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: SunsetColors.glassBorder),
  );
  
  static BoxDecoration whiteCard = BoxDecoration(
    color: SunsetColors.cardBg,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  static BoxDecoration glassNav = BoxDecoration(
    color: const Color(0xE6FFFFFF), // 90% white
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    border: Border(
      top: BorderSide(color: const Color(0x4DFFFFFF)), // 30% white
    ),
  );
  
  static BoxDecoration sunsetOrb = BoxDecoration(
    shape: BoxShape.circle,
    gradient: SunsetGradients.sunsetOrb,
    boxShadow: [
      BoxShadow(
        color: SunsetColors.sunsetRed.withOpacity(0.4),
        blurRadius: 40,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: SunsetColors.sunsetPink.withOpacity(0.2),
        blurRadius: 80,
        spreadRadius: 20,
      ),
    ],
  );
  
  static InputDecoration glassInput({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: SunsetColors.textLightMuted),
      prefixIcon: icon != null ? Icon(icon, color: SunsetColors.textLightMuted) : null,
      filled: true,
      fillColor: SunsetColors.glassBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SunsetColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SunsetColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SunsetColors.textLight),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

// Widget for gradient text
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  
  const GradientText({
    Key? key,
    required this.text,
    required this.style,
    required this.gradient,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

// Glass card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  
  const GlassCard({Key? key, required this.child, this.padding}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: SunsetStyles.glassCard,
          child: child,
        ),
      ),
    );
  }
}

// White elevated card with gradient border effect
class SunsetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  
  const SunsetCard({Key? key, required this.child, this.padding, this.onTap}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        decoration: SunsetStyles.whiteCard,
        child: child,
      ),
    );
  }
}
