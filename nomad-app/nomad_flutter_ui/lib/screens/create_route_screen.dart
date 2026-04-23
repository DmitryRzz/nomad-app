import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/sunset_theme.dart';
import '../models/route.dart';
import '../providers/route_provider.dart';

class CreateRouteScreen extends ConsumerStatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  ConsumerState<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends ConsumerState<CreateRouteScreen> {
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  
  final List<String> _selectedInterests = [];
  String _budgetLevel = 'moderate';
  String _intensity = 'balanced';
  String _transportMode = 'mixed';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _interestOptions = [
    {'icon': Icons.museum, 'label': 'Art'},
    {'icon': Icons.restaurant, 'label': 'Food'},
    {'icon': Icons.history_edu, 'label': 'History'},
    {'icon': Icons.park, 'label': 'Nature'},
    {'icon': Icons.music_note, 'label': 'Music'},
    {'icon': Icons.account_balance, 'label': 'Architecture'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'icon': Icons.nightlife, 'label': 'Nightlife'},
    {'icon': Icons.sports, 'label': 'Sports'},
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'Create Route',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            gradient: LinearGradient(colors: [Colors.white, SunsetColors.sunsetYellow]),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City input
              _buildSectionTitle('Destination'),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                style: const TextStyle(color: Colors.white),
                decoration: SunsetStyles.glassInput(
                  hint: 'City (e.g., Paris, Tokyo)',
                  prefixIcon: Icons.location_city,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _countryController,
                style: const TextStyle(color: Colors.white),
                decoration: SunsetStyles.glassInput(
                  hint: 'Country (optional)',
                  prefixIcon: Icons.public,
                ),
              ),
              const SizedBox(height: 24),

              // Budget Level
              _buildSectionTitle('Budget Level'),
              const SizedBox(height: 12),
              _buildSegmentedControl(
                options: ['budget', 'moderate', 'luxury'],
                labels: ['Budget', 'Moderate', 'Luxury'],
                selected: _budgetLevel,
                onChanged: (v) => setState(() => _budgetLevel = v),
              ),
              const SizedBox(height: 24),

              // Intensity
              _buildSectionTitle('Trip Intensity'),
              const SizedBox(height: 12),
              _buildSegmentedControl(
                options: ['relaxed', 'balanced', 'intense'],
                labels: ['Relaxed', 'Balanced', 'Intense'],
                selected: _intensity,
                onChanged: (v) => setState(() => _intensity = v),
              ),
              const SizedBox(height: 24),

              // Transport Mode
              _buildSectionTitle('Transport Mode'),
              const SizedBox(height: 12),
              _buildSegmentedControl(
                options: ['air', 'land', 'sea', 'mixed'],
                labels: ['Air', 'Land', 'Sea', 'Mixed'],
                selected: _transportMode,
                onChanged: (v) => setState(() => _transportMode = v),
              ),
              const SizedBox(height: 24),

              // Interests
              _buildSectionTitle('Interests'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interestOptions.map((opt) {
                  final label = opt['label'] as String;
                  final isSelected = _selectedInterests.contains(label);
                  return ChoiceChip(
                    avatar: Icon(opt['icon'] as IconData, size: 18, color: isSelected ? Colors.white : Colors.white70),
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: SunsetColors.sunsetRed,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(label);
                        } else {
                          _selectedInterests.remove(label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: SunsetColors.sunsetRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Route',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required Function(String) onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: List.generate(options.length, (index) {
              final option = options[index];
              final label = labels[index];
              final isSelected = selected == option;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? SunsetColors.sunsetRed : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _createRoute() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = RouteGenerationRequest(
        city: _cityController.text.trim(),
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        interests: _selectedInterests,
        budgetLevel: _budgetLevel == 'budget' ? 1 : _budgetLevel == 'luxury' ? 5 : 3,
        pace: _intensity,
      );

      await ref.read(routeProvider.notifier).generateRoute(request);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
