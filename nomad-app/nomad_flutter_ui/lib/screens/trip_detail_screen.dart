import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/sunset_theme.dart';
import '../models/trip.dart';
import 'trip_stats_screen.dart';
import 'cost_breakdown_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late Trip _trip;
  int _selectedDayIndex = 0;
  bool _showCostBreakdown = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Progress bar
              _buildProgressBar(),
              // Tab bar
              _buildTabBar(),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDayByDayView(),
                    _buildCityView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trip.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMM d').format(_trip.startDate)} - ${DateFormat('MMM d, y').format(_trip.endDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Stats button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripStatsScreen(trip: _trip),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart, color: Colors.white),
          ),
          // Cost breakdown toggle
          GestureDetector(
            onTap: () {
              final breakdown = _calculateCostBreakdown();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CostBreakdownScreen(
                    trip: _trip,
                    breakdown: breakdown,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '\$${_trip.totalBudget?.toStringAsFixed(0) ?? '?'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = _trip.progressPercent ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}% ($_trip.completedActivities/${_trip.totalActivities})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= 100 ? SunsetColors.sunsetYellow : Colors.white,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: SunsetColors.sunsetRed,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Day by Day'),
                Tab(text: 'City View'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayByDayView() {
    return Column(
      children: [
        // Day selector
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _trip.days.length,
            itemBuilder: (context, index) {
              final day = _trip.days[index];
              final isSelected = index == _selectedDayIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? SunsetColors.textMuted
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? SunsetColors.sunsetRed : Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('EEE').format(day.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? SunsetColors.textMuted
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Day content
        Expanded(
          child: _buildDayContent(_trip.days[_selectedDayIndex]),
        ),
      ],
    );
  }

  Widget _buildDayContent(TripDay day) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Day theme
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [SunsetColors.sunsetRed, SunsetColors.sunsetYellow],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wb_sunny, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(day.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.theme ?? 'Exploration day',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Activities timeline
        ...day.activities.asMap().entries.map((entry) {
          return _buildActivityCard(entry.value, entry.key == day.activities.length - 1);
        }).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActivityCard(TripActivity activity, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleActivity(activity),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: activity.completed
                        ? SunsetColors.sunsetYellow
                        : activity.skipped
                            ? Colors.grey
                            : Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activity.completed
                          ? SunsetColors.sunsetYellow
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: activity.completed
                      ? const Icon(Icons.check, color: SunsetColors.textDark, size: 18)
                      : activity.skipped
                          ? const Icon(Icons.close, color: Colors.white, size: 18)
                          : Icon(
                              _getCategoryIcon(activity.category),
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: activity.completed
                        ? SunsetColors.sunsetYellow.withOpacity(0.5)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Activity card
          Expanded(
            child: GestureDetector(
              onTap: () => _showActivityDetails(activity),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(activity.category).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _getCategoryColor(activity.category),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (activity.cost != null)
                          Text(
                            '\$${activity.cost!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SunsetColors.sunsetRed,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SunsetColors.textDark,
                      ),
                    ),
                    if (activity.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: SunsetColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: SunsetColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.durationMinutes} min',
                          style: const TextStyle(fontSize: 12, color: SunsetColors.textMuted),
                        ),
                        if (activity.startTime != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: SunsetColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(activity.startTime!),
                            style: const TextStyle(fontSize: 12, color: SunsetColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityView() {
    // Group activities by city/area
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.map, size: 48, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'Map view coming soon',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Interactive map with all your activities',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleActivity(TripActivity activity) {
    setState(() {
      _trip = _trip.copyWith(
        days: _trip.days.map((day) {
          return day.copyWith(
            activities: day.activities.map((a) {
              if (a.id == activity.id) {
                return a.copyWith(
                  completed: !a.completed,
                  skipped: false,
                );
              }
              return a;
            }).toList(),
          );
        }).toList(),
      );
    });
  }

  void _showActivityDetails(TripActivity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: SunsetGradients.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(activity.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(activity.category),
                    color: _getCategoryColor(activity.category),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activity.description != null)
              Text(
                activity.description!,
                style: const TextStyle(color: SunsetColors.textLightMuted, fontSize: 14),
              ),
            const SizedBox(height: 16),
            if (activity.cost != null)
              _buildInfoRow('Cost', '\$${activity.cost!.toStringAsFixed(2)}'),
            _buildInfoRow('Duration', '${activity.durationMinutes} minutes'),
            if (activity.address != null)
              _buildInfoRow('Address', activity.address!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleActivity(activity),
                    icon: Icon(
                      activity.completed ? Icons.undo : Icons.check_circle,
                      color: SunsetColors.sunsetRed,
                    ),
                    label: Text(
                      activity.completed ? 'Mark Incomplete' : 'Mark Complete',
                      style: const TextStyle(color: SunsetColors.sunsetRed, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _trip = _trip.copyWith(
                    days: _trip.days.map((day) {
                      return day.copyWith(
                        activities: day.activities.map((a) {
                          if (a.id == activity.id) {
                            return a.copyWith(skipped: !a.skipped);
                          }
                          return a;
                        }).toList(),
                      );
                    }).toList(),
                  );
                });
                Navigator.pop(context);
              },
              child: Text(
                activity.skipped ? 'Unskip' : 'Skip this activity',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: SunsetColors.textLightMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sightseeing':
        return SunsetColors.sunsetBlue;
      case 'food':
        return SunsetColors.sunsetRed;
      case 'transport':
        return SunsetColors.sunsetYellow;
      case 'rest':
        return const Color(0xFF2D6A4F);
      case 'shopping':
        return SunsetColors.sunsetPink;
      case 'entertainment':
        return const Color(0xFF9B59B6);
      default:
        return SunsetColors.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sightseeing':
        return Icons.camera_alt;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions;
      case 'rest':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.place;
    }
  }

  CostBreakdown _calculateCostBreakdown() {
    double accommodation = 0;
    double food = 0;
    double transport = 0;
    double activities = 0;
    double shopping = 0;
    double other = 0;

    for (final day in _trip.days) {
      for (final activity in day.activities) {
        if (activity.skipped || activity.cost == null) continue;
        switch (activity.category.toLowerCase()) {
          case 'rest':
            accommodation += activity.cost!;
            break;
          case 'food':
            food += activity.cost!;
            break;
          case 'transport':
            transport += activity.cost!;
            break;
          case 'sightseeing':
          case 'entertainment':
            activities += activity.cost!;
            break;
          case 'shopping':
            shopping += activity.cost!;
            break;
          default:
            other += activity.cost!;
        }
      }
    }

    return CostBreakdown(
      accommodation: accommodation,
      food: food,
      transport: transport,
      activities: activities,
      shopping: shopping,
      other: other,
      currency: 'USD',
    );
  }
}

// Extension for TripDay copyWith
extension TripDayExtension on TripDay {
  TripDay copyWith({
    int? dayNumber,
    DateTime? date,
    String? theme,
    List<TripActivity>? activities,
    double? dayBudget,
  }) {
    return TripDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      theme: theme ?? this.theme,
      activities: activities ?? this.activities,
      dayBudget: dayBudget ?? this.dayBudget,
    );
  }
}
