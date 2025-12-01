import 'package:flutter/material.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  static const List<_FoodLocation> _foodLocations = [
    _FoodLocation(
      name: 'Tim Hortons',
      location: 'Shawenjigewining Hall (SHA)',
      description:
      'Its a Tims, they got things from donuts to coffee to bagels.',
      hours: 'Mon–Thu · 7:30am – 6:30pm, Fri 7:30am - 4:30pm',
      tags: ['Coffee', 'Snacks', 'Fast Food'],
      isOpenGuess: true,
    ),
    _FoodLocation(
      name: 'Hunters Kitchen',
      location: 'UB (Business Building)',
      description:
      'Coffee, tea, baked goods, and quick grab-and-go items near many lecture halls.',
      hours: 'Mon–Fri · 7:30am – 5:00pm',
      tags: ['Coffee', 'Breakfast', 'Snacks'],
      isOpenGuess: true,
    ),
    _FoodLocation(
      name: 'Burger Factory',
      location: 'In Shoppers Plaza',
      description:
      'They have food ranging from burgers to milkshakes.',
      hours: 'All week 11am - 12am',
      tags: ['Fast Food', 'Drinks'],
      isOpenGuess: true,
    )
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme base = Theme.of(context).textTheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _foodLocations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Food on campus',
                style: base.titleLarge?.copyWith(
                  color: const Color(0xFFF7ECE1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use this list to quickly choose where to grab a drink or a meal between classes.',
                style: base.bodyMedium?.copyWith(
                  color: const Color(0xFF9FB3C6),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        final _FoodLocation place = _foodLocations[index - 1];

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fastfood_outlined,
                    color: Color(0xFF759FBC),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: base.bodyLarge?.copyWith(
                            color: const Color(0xFFF7ECE1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place.location,
                          style: base.bodyMedium?.copyWith(
                            color: const Color(0xFF9FB3C6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OpenPill(isOpen: place.isOpenGuess),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                place.description,
                style: base.bodyMedium?.copyWith(
                  color: const Color(0xFFF7ECE1),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFF9FB3C6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(child: Text(
                    place.hours,
                    style: base.bodyMedium?.copyWith(
                      color: const Color(0xFF9FB3C6),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: place.tags
                    .map(
                      (tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFFF7ECE1),
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: const Color(0xFF343A40),
                    side: const BorderSide(
                      color: Color(0xFF759FBC),
                      width: 0.5,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FoodLocation {
  final String name;
  final String location;
  final String description;
  final String hours;
  final List<String> tags;
  final bool isOpenGuess; // simple flag to show the pill

  const _FoodLocation({
    required this.name,
    required this.location,
    required this.description,
    required this.hours,
    required this.tags,
    required this.isOpenGuess,
  });
}

class _OpenPill extends StatelessWidget {
  final bool isOpen;

  const _OpenPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final Color bg = isOpen ? const Color(0xFF264334) : const Color(0xFF433126);
    final Color fg = isOpen ? const Color(0xFF8CD7A2) : const Color(0xFFF2A38E);
    final String label = isOpen ? 'Likely open' : 'Likely closed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
