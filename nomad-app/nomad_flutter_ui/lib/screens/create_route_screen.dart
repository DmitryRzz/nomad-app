import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  int _budgetLevel = 3;
  String _pace = 'balanced';
  bool _isLoading = false;

  final List<String> _availableInterests = [
    'art', 'food', 'history', 'nature', 'music', 
    'architecture', 'shopping', 'nightlife', 'sports'
  ];

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Route'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City input
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City *',
                hintText: 'e.g., Paris, Tokyo, New York',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Country input
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: 'Country (optional)',
                hintText: 'e.g., France, Japan, USA',
                prefixIcon: const Icon(Icons.public),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Interests
            Text(
              'Interests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Budget level
            Text(
              'Budget Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('${index + 1}'),
                      selected: _budgetLevel == index + 1,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _budgetLevel = index + 1);
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _getBudgetLabel(_budgetLevel),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            
            // Pace
            Text(
              'Pace',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'relaxed',
                  label: Text('Relaxed'),
                  icon: Icon(Icons.coffee),
                ),
                ButtonSegment(
                  value: 'balanced',
                  label: Text('Balanced'),
                  icon: Icon(Icons.schedule),
                ),
                ButtonSegment(
                  value: 'intense',
                  label: Text('Intense'),
                  icon: Icon(Icons.directions_run),
                ),
              ],
              selected: {_pace},
              onSelectionChanged: (selected) {
                setState(() => _pace = selected.first);
              },
            ),
            const SizedBox(height: 32),
            
            // Create button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRoute,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Generate Route',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBudgetLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Budget-friendly';
      case 2:
        return 'Budget-friendly';
      case 3:
        return 'Moderate';
      case 4:
        return 'Upscale';
      case 5:
        return 'Luxury';
      default:
        return '';
    }
  }

  Future<void> _createRoute() async {
    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final request = RouteGenerationRequest(
      city: _cityController.text.trim(),
      country: _countryController.text.trim().isNotEmpty
          ? _countryController.text.trim()
          : null,
      interests: _selectedInterests,
      budgetLevel: _budgetLevel,
      pace: _pace,
    );

    final route = await ref.read(routesProvider.notifier).createRoute(request);

    setState(() => _isLoading = false);

    if (route != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route "${route.title}" created!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create route. Please try again.')),
      );
    }
  }
}
