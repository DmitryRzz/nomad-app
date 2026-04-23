import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/sunset_theme.dart';
import '../models/trip.dart';

class CostBreakdownScreen extends StatelessWidget {
  final Trip trip;
  final CostBreakdown breakdown;

  const CostBreakdownScreen({
    super.key,
    required this.trip,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Accommodation', 'value': breakdown.accommodation, 'color': const Color(0xFF6C5CE7)},
      {'label': 'Food & Dining', 'value': breakdown.food, 'color': SunsetColors.sunsetRed},
      {'label': 'Transport', 'value': breakdown.transport, 'color': SunsetColors.sunsetYellow},
      {'label': 'Activities', 'value': breakdown.activities, 'color': SunsetColors.sunsetBlue},
      {'label': 'Shopping', 'value': breakdown.shopping, 'color': SunsetColors.sunsetPink},
      {'label': 'Other', 'value': breakdown.other, 'color': SunsetColors.textMuted},
    ];

    final total = breakdown.total;

    return Container(
      decoration: const BoxDecoration(gradient: SunsetGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GradientText(
            text: 'Cost Breakdown',
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
                // Total card
                _buildTotalCard(total),
                const SizedBox(height: 32),

                // Breakdown bars
                _buildSectionTitle('By Category'),
                const SizedBox(height: 16),
                ...items.where((i) => (i['value'] as double) > 0).map((item) {
                  return _buildCostBar(
                    item['label'] as String,
                    item['value'] as double,
                    item['color'] as Color,
                    total,
                  );
                }).toList(),
                const SizedBox(height: 32),

                // Per day average
                if (trip.totalDays > 0) ...[
                  _buildSectionTitle('Daily Average'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Per day', total / trip.totalDays),
                  _buildInfoRow('Per person', trip.totalBudget != null && trip.totalBudget! > 0
                      ? total / (trip.totalBudget! / total)
                      : null),
                ],

                // Budget comparison
                if (trip.totalBudget != null) ...[
                  const SizedBox(height: 32),
                  _buildSectionTitle('Budget Status'),
                  const SizedBox(height: 16),
                  _buildBudgetComparison(total, trip.totalBudget!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(
                'Total Estimated Cost',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                breakdown.currency,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostBar(String label, double value, Color color, double total) {
    final percent = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
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
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '\$${value.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetComparison(double spent, double budget) {
    final percent = budget > 0 ? spent / budget : 0.0;
    final remaining = budget - spent;
    final isOverBudget = remaining < 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: const ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent.clamp(0, 1),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? SunsetColors.sunsetRed : SunsetColors.sunsetYellow,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '\$${budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverBudget ? 'Over Budget' : 'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget
                              ? SunsetColors.sunsetRed
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '\$${remaining.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget ? SunsetColors.sunsetRed : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, double? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
}
