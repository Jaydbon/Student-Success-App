import 'package:flutter/material.dart';

class ScheduleItem {
  final String title;
  final String timeOrDue;
  final String location;
  final bool isAssignment;
  const ScheduleItem({
    required this.title,
    required this.timeOrDue,
    required this.location,
    this.isAssignment = false,
  });
}

class DaySchedule {
  final String weekday;
  final List<ScheduleItem> classes;
  final List<ScheduleItem> assignments;
  const DaySchedule({
    required this.weekday,
    this.classes = const [],
    this.assignments = const [],
  });
  int get classCount => classes.length;
  int get assignmentCount => assignments.length;
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late List<DaySchedule> _days;

  @override
  void initState() {
    super.initState();
    _days = _fakeWeek();
  }

  List<DaySchedule> _fakeWeek() => const [
    DaySchedule(
      weekday: 'Monday',
      classes: [
        ScheduleItem(title: 'Database Systems', timeOrDue: '2:10–3:30pm', location: 'SCI-2460'),
      ],
      assignments: [
        ScheduleItem(title: 'Mobile Dev – A3', timeOrDue: 'Due: Sep 20', location: 'D2L', isAssignment: true),
      ],
    ),
    DaySchedule(
      weekday: 'Tuesday',
      classes: [
        ScheduleItem(title: 'Software Design & Analysis', timeOrDue: '10:00–11:20am', location: 'ENG-120'),
        ScheduleItem(title: 'Scientific Data Analysis', timeOrDue: '1:00–2:20pm', location: 'SCI-1502'),
      ],
      assignments: [
        ScheduleItem(title: 'Env Sci – Quiz 3', timeOrDue: 'Due: Sep 25', location: 'D2L', isAssignment: true),
      ],
    ),
    DaySchedule(
      weekday: 'Wednesday',
      classes: [ScheduleItem(title: 'Programming Workshop', timeOrDue: '9:00–9:50am', location: 'SCI-110')],
      assignments: [ScheduleItem(title: 'HCI Reflection', timeOrDue: 'Due: Sep 25', location: 'D2L', isAssignment: true)],
    ),
    DaySchedule(
      weekday: 'Thursday',
      classes: [ScheduleItem(title: 'Software Dev & Integration', timeOrDue: '11:30–12:50pm', location: 'ENG-220')],
    ),
    DaySchedule(
      weekday: 'Friday',
      classes: [ScheduleItem(title: 'Mobile Development', timeOrDue: '2:10–3:30pm', location: 'SCI-2460')],
      assignments: [ScheduleItem(title: 'API mock', timeOrDue: 'Due: Sep 28', location: 'Postman', isAssignment: true)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _DayCard(day: _days[i]),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DaySchedule day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A3036),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        collapsedIconColor: const Color(0xFF759FBC),
        iconColor: const Color(0xFF759FBC),
        title: Text(
          day.weekday,
          style: base.titleLarge?.copyWith(color: const Color(0xFFF7ECE1), fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${day.classCount} Class${day.classCount == 1 ? '' : 'es'} • '
              '${day.assignmentCount} Assignment${day.assignmentCount == 1 ? '' : 's'}',
          style: base.bodyMedium?.copyWith(color: const Color(0xFF9FB3C6)),
        ),
        children: [
          if (day.classes.isNotEmpty)
            _Section(label: 'Classes', items: day.classes, leading: const Icon(Icons.class_outlined)),
          if (day.assignments.isNotEmpty)
            _Section(label: 'Assignments', items: day.assignments, leading: const Icon(Icons.assignment_outlined)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<ScheduleItem> items;
  final Widget leading;
  const _Section({required this.label, required this.items, required this.leading});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            leading,
            const SizedBox(width: 8),
            Text(label, style: base.titleMedium?.copyWith(color: const Color(0xFF759FBC))),
          ]),
          const SizedBox(height: 8),
          ...items.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF343A40), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(e.isAssignment ? Icons.check_circle_outline : Icons.schedule_outlined,
                    color: const Color(0xFF9FB3C6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title,
                        style: base.bodyLarge?.copyWith(
                            color: const Color(0xFFF7ECE1), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${e.timeOrDue}  •  ${e.location}',
                        style: base.bodyMedium?.copyWith(color: const Color(0xFF9FB3C6))),
                  ]),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
