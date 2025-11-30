import 'package:flutter/material.dart';

class HomeOverviewPage extends StatelessWidget {
  const HomeOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: textTheme.titleLarge?.copyWith(
              color: const Color(0xFFF7ECE1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use this hub to keep track of your day on campus.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9FB3C6),
            ),
          ),
          const SizedBox(height: 20),

          // Row of quick overview cards
          Row(
            children: const [
              Expanded(
                child: _HomeSectionCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Schedule',
                  description: 'See your classes and upcoming assignments.',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HomeSectionCard(
                  icon: Icons.timer_outlined,
                  title: 'Study Timer',
                  description: 'Use a focus timer while you work.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _HomeSectionCard(
                  icon: Icons.fastfood_outlined,
                  title: 'Food',
                  description: 'Find a spot to grab a snack or coffee.',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _HomeSectionCard(
                  icon: Icons.map_outlined,
                  title: 'Campus Map',
                  description: 'Quickly locate your next building.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Today\'s tips',
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF759FBC),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const _TipCard(
            title: 'Batch your work',
            body:
            'Group similar tasks together (e.g., readings, coding, quizzes) and use the timer to stay focused.',
          ),
          const SizedBox(height: 8),
          const _TipCard(
            title: 'Leave buffer time',
            body:
            'Plan a 5–10 minute buffer when moving between buildings so you’re not rushing between classes.',
          ),
        ],
      ),
    );
  }
}

class _HomeSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HomeSectionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme base = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3036),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF759FBC), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: base.bodyLarge?.copyWith(
                    color: const Color(0xFFF7ECE1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: base.bodyMedium?.copyWith(
                    color: const Color(0xFF9FB3C6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String body;

  const _TipCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme base = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF343A40),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: base.bodyLarge?.copyWith(
              color: const Color(0xFFF7ECE1),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: base.bodyMedium?.copyWith(
              color: const Color(0xFF9FB3C6),
            ),
          ),
        ],
      ),
    );
  }
}
