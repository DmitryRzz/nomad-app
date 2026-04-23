import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/sunset_theme.dart';
import '../models/trip.dart';

class TripStatsScreen extends StatelessWidget {
  final Trip trip;

  const TripStatsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final allActivities = trip.days.expand((d) => d.activities).toList();
    final completed = allActivities.where((a) => a.completed).length;
    final skipped = allActivities.where((a) => a.skipped).length;
    final pending = allActivities.length - completed - skipped;
    
    final categoryStats = _buildCategoryStats(allActivities);
    final dailyProgress = _buildDailyProgress(trip.days);

    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'Trip Stats',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            gradient: LinearGradient(colors: [Colors.white, SunsetColors.sunsetYellow]),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Overall progress circle
                _buildProgressCircle(completed, allActivities.length),
                const SizedBox(height: 32),
                
                // Stats cards
                Row(
                  children: [
                    _buildStatCard('Completed', completed, SunsetColors.sunsetYellow, Icons.check_circle),
                    const SizedBox(width: 12),
                    _buildStatCard('Pending', pending, SunsetColors.sunsetBlue, Icons.schedule),
                    const SizedBox(width: 12),
                    _buildStatCard('Skipped', skipped, SunsetColors.textMuted, Icons.close),
                  ],
                ),
                const SizedBox(height: 32),

                // Category breakdown
                _buildSectionTitle('By Category'),
                const SizedBox(height: 16),
                ...categoryStats.entries.map((entry) {
                  return _buildCategoryBar(
                    entry.key,
                    entry.value['count'] as int,
                    entry.value['completed'] as int,
                    entry.value['color'] as Color,
                    allActivities.length,
                  );
                }).toList(),
                const SizedBox(height: 32),

                // Daily progress
                _buildSectionTitle('Daily Progress'),
                const SizedBox(height: 16),
                ...dailyProgress.map((day) => _buildDayProgressBar(day)).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(int completed, int total) {
    final percent = total > 0 ? completed / total : 0.0;
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.05)),
            ),
            CircularProgressIndicator(
              value: percent,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$completed / $total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Expanded(
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
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int completed, Color color, int total) {
    final percent = count > 0 ? completed / count : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '$completed/$count',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgressBar(Map<String, dynamic> day) {
    final percent = day['percent'] as double;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Day ${day['day']}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent >= 1 ? SunsetColors.sunsetYellow : Colors.white,
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(percent * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: percent >= 1 ? SunsetColors.sunsetYellow : Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCategoryStats(List<TripActivity> activities) {
    final stats = <String, Map<String, dynamic>>{};
    final colors = {
      'sightseeing': SunsetColors.sunsetBlue,
      'food': SunsetColors.sunsetRed,
      'transport': SunsetColors.sunsetYellow,
      'rest': const Color(0xFF2D6A4F),
      'shopping': SunsetColors.sunsetPink,
      'entertainment': const Color(0xFF9B59B6),
    };

    for (final activity in activities) {
      final cat = activity.category;
      if (!stats.containsKey(cat)) {
        stats[cat] = {'count': 0, 'completed': 0, 'color': colors[cat] ?? SunsetColors.textMuted};
      }
      stats[cat]!['count'] = (stats[cat]!['count'] as int) + 1;
      if (activity.completed) {
        stats[cat]!['completed'] = (stats[cat]!['completed'] as int) + 1;
      }
    }

    return stats;
  }

  List<Map<String, dynamic>> _buildDailyProgress(List<TripDay> days) {
    return days.map((day) {
      final total = day.activities.length;
      final completed = day.activities.where((a) => a.completed).length;
      return {
        'day': day.dayNumber,
        'date': DateFormat('MMM d').format(day.date),
        'percent': total > 0 ? completed / total : 0.0,
      };
    }).toList();
  }
}
