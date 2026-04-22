import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String? _currentPlan;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Free',
      'price': 0,
      'period': 'forever',
      'features': [
        '3 routes per month',
        'Basic weather alerts',
        'Standard translation',
        'Community support',
      ],
      'color': Colors.grey,
    },
    {
      'name': 'Pro',
      'price': 9.99,
      'period': 'month',
      'features': [
        'Unlimited routes',
        'Smart Compass AR',
        'Real-time weather adaptation',
        'Priority translation',
        'Split payments',
        'Offline maps',
        '24/7 support',
      ],
      'color': Colors.green,
      'recommended': true,
    },
    {
      'name': 'Team',
      'price': 29.99,
      'period': 'month',
      'features': [
        'Everything in Pro',
        'Up to 5 team members',
        'Shared routes',
        'Group booking discounts',
        'Admin dashboard',
        'API access',
      ],
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentPlan();
  }

  Future<void> _checkCurrentPlan() async {
    // TODO: Check active subscription from backend
    setState(() => _currentPlan = 'Free');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOMAD Pro'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            ..._plans.map((plan) => _buildPlanCard(plan)),
            const SizedBox(height: 24),
            _buildFAQSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upgrade Your Travels',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock AI-powered routes, AR compass, and seamless group payments.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          if (_currentPlan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current plan: $_currentPlan',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isCurrent = _currentPlan == plan['name'];
    final bool isRecommended = plan['recommended'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? plan['color'] : Colors.grey[300]!,
          width: isRecommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isCurrent ? plan['color'].withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: plan['color'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: const Text(
                'RECOMMENDED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: plan['color'],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: plan['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            color: plan['color'],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan['price']}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/${plan['period']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...plan['features'].map<Widget>((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: plan['color'],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrent || _isLoading
                        ? null
                        : () => _subscribe(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan['color'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isCurrent ? 'Current Plan' : 'Get ${plan['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'Can I cancel anytime?',
          'Yes. You can cancel your subscription at any time. Your access continues until the end of the billing period.',
        ),
        _buildFAQItem(
          'What payment methods?',
          'We accept all major credit cards, PayPal, and Apple Pay.',
        ),
        _buildFAQItem(
          'Is there a free trial?',
          'Yes! Pro plan includes a 7-day free trial. No credit card required to start.',
        ),
        _buildFAQItem(
          'Can I switch plans?',
          'Absolutely. You can upgrade or downgrade your plan at any time.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribe(Map<String, dynamic> plan) async {
    if (plan['price'] == 0) return;

    setState(() => _isLoading = true);

    // TODO: Implement Stripe payment flow
    // 1. Create payment intent or subscription
    // 2. Present Stripe payment sheet
    // 3. Confirm payment
    // 4. Update user plan

    await Future.delayed(const Duration(seconds: 2)); // Simulate

    setState(() {
      _isLoading = false;
      _currentPlan = plan['name'];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome to NOMAD ${plan['name']}!'),
          backgroundColor: plan['color'],
        ),
      );
    }
  }
}