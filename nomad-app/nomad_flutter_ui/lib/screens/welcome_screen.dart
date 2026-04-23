import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../theme/sunset_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                // Sunset Orb with animation
                const Center(child: _SunsetOrb()),
                const SizedBox(height: 32),
                // Gradient Title
                Center(
                  child: GradientText(
                    text: 'NOMAD',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        SunsetColors.sunsetYellow.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'AI Travel Planner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: SunsetColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find your next adventure',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: SunsetColors.textLightMuted,
                  ),
                ),
                const Spacer(flex: 3),
                // Feature icons in glass cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _FeatureGlass(icon: Icons.map, label: 'Routes'),
                    SizedBox(width: 20),
                    _FeatureGlass(icon: Icons.explore, label: 'Compass'),
                    SizedBox(width: 20),
                    _FeatureGlass(icon: Icons.translate, label: 'Translate'),
                  ],
                ),
                const Spacer(flex: 2),
                // Buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SunsetColors.sunsetRed,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: const Text(
                    'Start Exploring',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x80FFFFFF), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                // Terms
                const Text(
                  'By continuing, you agree to Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: SunsetColors.textLightMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SunsetOrb extends StatefulWidget {
  const _SunsetOrb();

  @override
  State<_SunsetOrb> createState() => _SunsetOrbState();
}

class _SunsetOrbState extends State<_SunsetOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  SunsetColors.sunsetRed,
                  SunsetColors.sunsetYellow,
                  SunsetColors.sunsetPink,
                ],
              ),
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
            ),
            child: const Center(
              child: Icon(
                Icons.flight,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureGlass extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureGlass({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
