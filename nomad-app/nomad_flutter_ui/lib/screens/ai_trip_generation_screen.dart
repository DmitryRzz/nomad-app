import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/sunset_theme.dart';
import '../models/trip.dart';
import 'trip_detail_screen.dart';

class AITripGenerationScreen extends ConsumerStatefulWidget {
  const AITripGenerationScreen({super.key});

  @override
  ConsumerState<AITripGenerationScreen> createState() => _AITripGenerationScreenState();
}

class _AITripGenerationScreenState extends ConsumerState<AITripGenerationScreen> {
  final _destinationController = TextEditingController();
  final _requirementsController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));
  
  String _budgetLevel = 'moderate';
  String _intensity = 'balanced';
  String _transportMode = 'mixed';
  int _travelersCount = 1;
  
  final List<String> _selectedInterests = [];
  final List<String> _selectedCuisines = [];
  
  String? _wakeUpTime = '08:00';
  String? _sleepTime = '22:00';
  
  bool _isGenerating = false;
  int _generationProgress = 0;

  final List<Map<String, dynamic>> _interestOptions = [
    {'icon': Icons.museum, 'label': 'Museums'},
    {'icon': Icons.park, 'label': 'Nature'},
    {'icon': Icons.restaurant, 'label': 'Food'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'icon': Icons.nightlife, 'label': 'Nightlife'},
    {'icon': Icons.beach_access, 'label': 'Beach'},
    {'icon': Icons.hiking, 'label': 'Hiking'},
    {'icon': Icons.camera_alt, 'label': 'Photography'},
    {'icon': Icons.spa, 'label': 'Wellness'},
    {'icon': Icons.local_bar, 'label': 'Bars'},
    {'icon': Icons.sports, 'label': 'Sports'},
    {'icon': Icons.music_note, 'label': 'Music'},
  ];

  final List<String> _cuisineOptions = [
    'Local', 'Italian', 'Asian', 'French', 'Mexican',
    'Indian', 'Japanese', 'Mediterranean', 'Vegetarian', 'Vegan',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'AI Trip Generator',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            gradient: LinearGradient(colors: [Colors.white, SunsetColors.sunsetYellow]),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: _isGenerating ? _buildGenerationView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination
          _buildSectionTitle('Where to?'),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            style: const TextStyle(color: Colors.white),
            decoration: SunsetStyles.glassInput(
              hint: 'Enter destination (city or country)',
              prefixIcon: Icons.location_on,
            ),
          ),
          const SizedBox(height: 24),

          // Dates
          _buildSectionTitle('When?'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'Start',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: 'End',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Budget
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

          // Transport
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
          const SizedBox(height: 24),

          // Cuisines
          _buildSectionTitle('Cuisine Preferences'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cuisineOptions.map((cuisine) {
              final isSelected = _selectedCuisines.contains(cuisine);
              return ChoiceChip(
                label: Text(cuisine),
                selected: isSelected,
                selectedColor: SunsetColors.sunsetYellow,
                backgroundColor: Colors.white.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? SunsetColors.textDark : Colors.white.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCuisines.add(cuisine);
                    } else {
                      _selectedCuisines.remove(cuisine);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Schedule
          _buildSectionTitle('Daily Schedule'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  label: 'Wake up',
                  time: _wakeUpTime ?? '08:00',
                  onTap: () => _pickTime(isWakeUp: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePicker(
                  label: 'Sleep',
                  time: _sleepTime ?? '22:00',
                  onTap: () => _pickTime(isWakeUp: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Travelers
          _buildSectionTitle('Travelers'),
          const SizedBox(height: 12),
          _buildTravelersCounter(),
          const SizedBox(height: 24),

          // Special requirements
          _buildSectionTitle('Special Requirements'),
          const SizedBox(height: 12),
          TextField(
            controller: _requirementsController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: SunsetStyles.glassInput(
              hint: 'Accessibility needs, must-see places, dietary restrictions...',
            ),
          ),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _generateTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SunsetColors.sunsetRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text(
                'Generate My Trip',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenerationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated orb
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [SunsetColors.sunsetRed, SunsetColors.sunsetYellow],
              ),
              boxShadow: [
                BoxShadow(
                  color: SunsetColors.sunsetRed.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'AI is crafting your trip...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a minute',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _generationProgress / 100,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_generationProgress%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
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

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildTravelersCounter() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _travelersCount > 1
                    ? () => setState(() => _travelersCount--)
                    : null,
                icon: Icon(Icons.remove, color: Colors.white.withOpacity(0.7)),
              ),
              Text(
                '$_travelersCount ${_travelersCount == 1 ? 'person' : 'people'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _travelersCount < 10
                    ? () => setState(() => _travelersCount++)
                    : null,
                icon: Icon(Icons.add, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SunsetColors.sunsetRed,
            surface: SunsetColors.darkBg,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 3));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isWakeUp}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.parse('2024-01-01 ${isWakeUp ? _wakeUpTime : _sleepTime}:00'),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SunsetColors.sunsetRed,
            surface: SunsetColors.darkBg,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        if (isWakeUp) {
          _wakeUpTime = formatted;
        } else {
          _sleepTime = formatted;
        }
      });
    }
  }

  Future<void> _generateTrip() async {
    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0;
    });

    // Simulate streaming progress
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _generationProgress = i * 10;
        });
      }
    }

    // Create mock trip
    final trip = _createMockTrip();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailScreen(trip: trip),
        ),
      );
      setState(() => _isGenerating = false);
    }
  }

  Trip _createMockTrip() {
    final destination = _destinationController.text.trim();
    final days = _endDate.difference(_startDate).inDays + 1;
    
    final tripDays = List.generate(days, (index) {
      final date = _startDate.add(Duration(days: index));
      return TripDay(
        dayNumber: index + 1,
        date: date,
        theme: _getDayTheme(index, days),
        activities: _generateDayActivities(index, destination),
      );
    });

    return Trip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      title: '$destination Adventure',
      description: 'AI-generated ${_intensity} trip to $destination',
      destination: destination,
      country: _countryFromDestination(destination),
      startDate: _startDate,
      endDate: _endDate,
      status: 'active',
      budgetLevel: _budgetLevel,
      intensity: _intensity,
      transportMode: _transportMode,
      totalBudget: _estimateBudget(days),
      interests: _selectedInterests,
      cuisines: _selectedCuisines,
      wakeUpTime: _wakeUpTime,
      sleepTime: _sleepTime,
      days: tripDays,
      createdAt: DateTime.now(),
    );
  }

  String _getDayTheme(int index, int totalDays) {
    final themes = [
      'Arrival & Orientation',
      'City Highlights',
      'Hidden Gems',
      'Cultural Deep Dive',
      'Nature & Outdoors',
      'Food & Markets',
      'Museums & History',
      'Relaxation Day',
      'Adventure & Activities',
      'Farewell & Departure',
    ];
    if (index == 0) return 'Arrival & Orientation';
    if (index == totalDays - 1) return 'Farewell & Departure';
    return themes[index % themes.length];
  }

  List<TripActivity> _generateDayActivities(int dayIndex, String destination) {
    final activities = <TripActivity>[];
    final baseHour = 9;
    
    // Morning activity
    activities.add(TripActivity(
      id: 'act_${dayIndex}_1',
      title: dayIndex == 0 ? 'Check-in at hotel' : 'Morning exploration',
      category: dayIndex == 0 ? 'rest' : 'sightseeing',
      durationMinutes: dayIndex == 0 ? 120 : 180,
      startTime: DateTime(2024, 1, 1, baseHour, 0),
      cost: dayIndex == 0 ? null : 15,
    ));

    // Lunch
    activities.add(TripActivity(
      id: 'act_${dayIndex}_2',
      title: 'Lunch at local restaurant',
      category: 'food',
      durationMinutes: 90,
      startTime: DateTime(2024, 1, 1, baseHour + 4, 0),
      cost: _budgetLevel == 'budget' ? 10 : _budgetLevel == 'luxury' ? 50 : 25,
    ));

    // Afternoon
    activities.add(TripActivity(
      id: 'act_${dayIndex}_3',
      title: 'Afternoon activity in $destination',
      category: 'sightseeing',
      durationMinutes: 180,
      startTime: DateTime(2024, 1, 1, baseHour + 6, 0),
      cost: 20,
    ));

    // Dinner
    activities.add(TripActivity(
      id: 'act_${dayIndex}_4',
      title: 'Dinner experience',
      category: 'food',
      durationMinutes: 120,
      startTime: DateTime(2024, 1, 1, baseHour + 10, 0),
      cost: _budgetLevel == 'budget' ? 15 : _budgetLevel == 'luxury' ? 80 : 35,
    ));

    return activities;
  }

  String? _countryFromDestination(String destination) {
    // Simple mapping
    final cities = {
      'paris': 'France', 'london': 'UK', 'tokyo': 'Japan', 'new york': 'USA',
      'rome': 'Italy', 'barcelona': 'Spain', 'amsterdam': 'Netherlands',
      'berlin': 'Germany', 'dubai': 'UAE', 'bangkok': 'Thailand',
    };
    return cities[destination.toLowerCase()];
  }

  double _estimateBudget(int days) {
    final base = switch (_budgetLevel) {
      'budget' => 50.0,
      'luxury' => 300.0,
      _ => 150.0,
    };
    return base * days * _travelersCount;
  }
}
