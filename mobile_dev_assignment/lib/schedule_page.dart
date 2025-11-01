import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DaySchedule {
  final String weekday;
  final List<Session> classes; // SQL-backed Session objects
  final List<Assignment> assignments; // SQL-backed Assignment objects
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
  final DatabaseProvider _dbp = DatabaseProvider();

  @override
  void initState() {
    super.initState();
    _days = const [];
    _initDbAndLoad();
  }

  Future<void> _initDbAndLoad() async {
    // ensure DB is open
    await _dbp.database;

    // insert test data (ignoring conflicts so repeated hot reload won't fail)
    try {
      await _dbp.insertCourse(Course(courseCode: 'DBSYS101', title: 'Database Systems'));
      await _dbp.insertCourse(Course(courseCode: 'MOBDEV201', title: 'Mobile Development'));
      await _dbp.insertCourse(Course(courseCode: 'SDA101', title: 'Software Design & Analysis'));
      await _dbp.insertCourse(Course(courseCode: 'SDA201', title: 'Scientific Data Analysis'));
      await _dbp.insertCourse(Course(courseCode: 'PWK101', title: 'Programming Workshop'));
      await _dbp.insertCourse(Course(courseCode: 'SDI101', title: 'Software Dev & Integration'));

      // Locations (we let insertLocation ignore duplicates)
      final locSci2460 = await _dbp.insertLocation(Location(buildingName: 'SCI', room: '2460'));
      final locEng120 = await _dbp.insertLocation(Location(buildingName: 'ENG', room: '120'));
      final locSci1502 = await _dbp.insertLocation(Location(buildingName: 'SCI', room: '1502'));
      final locSci110 = await _dbp.insertLocation(Location(buildingName: 'SCI', room: '110'));
      final locEng220 = await _dbp.insertLocation(Location(buildingName: 'ENG', room: '220'));

      // Sessions (course_code, type, section, startMin, endMin, locationId or building/room, weekdays 0=Mon..6=Sun)
      await _dbp.insertSession(Session(
        courseCode: 'DBSYS101',
        type: 'lecture',
        section: 'A',
        startMin: hhmmToMinutes('14:10'),
        endMin: hhmmToMinutes('15:30'),
        locationId: locSci2460,
        weekdays: [0],
      ));

      await _dbp.insertSession(Session(
        courseCode: 'MOBDEV201',
        type: 'lecture',
        section: 'A',
        startMin: hhmmToMinutes('14:10'),
        endMin: hhmmToMinutes('15:30'),
        locationId: locSci2460,
        weekdays: [4],
      ));

      await _dbp.insertSession(Session(
        courseCode: 'SDA101',
        type: 'lecture',
        section: 'A',
        startMin: hhmmToMinutes('10:00'),
        endMin: hhmmToMinutes('11:20'),
        locationId: locEng120,
        weekdays: [1],
      ));

      await _dbp.insertSession(Session(
        courseCode: 'SDA201',
        type: 'lecture',
        section: 'A',
        startMin: hhmmToMinutes('13:00'),
        endMin: hhmmToMinutes('14:20'),
        locationId: locSci1502,
        weekdays: [1],
      ));

      await _dbp.insertSession(Session(
        courseCode: 'PWK101',
        type: 'workshop',
        section: 'W1',
        startMin: hhmmToMinutes('09:00'),
        endMin: hhmmToMinutes('09:50'),
        locationId: locSci110,
        weekdays: [2],
      ));

      await _dbp.insertSession(Session(
        courseCode: 'SDI101',
        type: 'lecture',
        section: 'A',
        startMin: hhmmToMinutes('11:30'),
        endMin: hhmmToMinutes('12:50'),
        locationId: locEng220,
        weekdays: [3],
      ));

      // Assignments: choose due dates that fall on the intended weekdays in 2025
      // Mobile Dev – A3 (Monday) -> 2025-09-22
      await _dbp.insertAssignment(Assignment(
        courseCode: 'MOBDEV201',
        title: 'Mobile Dev – A3',
        dueDatetime: '2025-09-22 23:59',
        submissionLocation: 'D2L',
      ));

      // Env Sci – Quiz 3 (Tuesday) -> 2025-09-23
      await _dbp.insertAssignment(Assignment(
        courseCode: 'SDA101',
        title: 'Env Sci – Quiz 3',
        dueDatetime: '2025-09-23 23:59',
        submissionLocation: 'D2L',
      ));

      // HCI Reflection (Wednesday) -> 2025-09-24
      await _dbp.insertAssignment(Assignment(
        courseCode: 'PWK101',
        title: 'HCI Reflection',
        dueDatetime: '2025-09-24 23:59',
        submissionLocation: 'D2L',
      ));

      // API mock (Friday) -> 2025-09-26
      await _dbp.insertAssignment(Assignment(
        courseCode: 'MOBDEV201',
        title: 'API mock',
        dueDatetime: '2025-09-26 23:59',
        submissionLocation: 'Postman',
      ));
    } catch (e) {
      // ignore insertion errors (unique constraints) during repeated runs
    }

    // Build DaySchedule objects reading back from the DB
    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // classesByDay: query sessions for each weekday
    final Map<int, List<Session>> classesByDay = {};
    for (int wd = 0; wd < 7; wd++) {
      final sessions = await _dbp.getSessionsByWeekday(wd);
      classesByDay[wd] = sessions;
    }

    // assignmentsByDay: query all assignments and place them by their due date's weekday
    final db = await _dbp.database;
    final rows = await db.query('assignments');
    final Map<int, List<Assignment>> assignmentsByDay = {};
    for (final r in rows) {
      final a = Assignment.fromMap(r);
      DateTime dt;
      try {
        dt = DateTime.parse(a.dueDatetime);
      } catch (_) {
        dt = DateTime.now();
      }
      final wd = dt.weekday - 1; // DateTime.weekday: 1=Mon..7=Sun -> convert to 0..6
      assignmentsByDay.putIfAbsent(wd, () => []);
      assignmentsByDay[wd]!.add(a);
    }

    // Build final list for Monday..Friday (keep all weekdays but UI will show those with content)
    final List<DaySchedule> built = [];
    for (int wd = 0; wd <= 6; wd++) {
      final classes = classesByDay[wd] ?? [];
      final assignments = assignmentsByDay[wd] ?? [];
      if (classes.isEmpty && assignments.isEmpty) continue; // skip empty days for compactness
      built.add(DaySchedule(weekday: weekdayNames[wd], classes: classes, assignments: assignments));
    }

    setState(() {
      _days = built;
    });
  }

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
            _SessionSection(label: 'Classes', sessions: day.classes, leading: const Icon(Icons.class_outlined)),
          if (day.assignments.isNotEmpty)
            _AssignmentSection(label: 'Assignments', items: day.assignments, leading: const Icon(Icons.assignment_outlined)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SessionSection extends StatelessWidget {
  final String label;
  final List<Session> sessions;
  final Widget leading;
  const _SessionSection({required this.label, required this.sessions, required this.leading});

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
          ...sessions.map((s) {
            final title = s.courseTitle ?? s.courseCode;
            final timeRange = minutesTo12HourRange(s.startMin, s.endMin);
            final loc = (s.locationBuilding != null && s.locationBuilding!.isNotEmpty)
                ? (s.locationRoom == null || s.locationRoom!.isEmpty ? s.locationBuilding! : '${s.locationBuilding!} ${s.locationRoom!}')
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF343A40), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined, color: const Color(0xFF9FB3C6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: base.bodyLarge?.copyWith(color: const Color(0xFFF7ECE1), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$timeRange  •  $loc', style: base.bodyMedium?.copyWith(color: const Color(0xFF9FB3C6))),
                    ]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _AssignmentSection extends StatelessWidget {
  final String label;
  final List<Assignment> items;
  final Widget leading;
  const _AssignmentSection({required this.label, required this.items, required this.leading});

  String _formatMonthDay(DateTime dt) {
    const mnames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${mnames[dt.month - 1]} ${dt.day}';
  }

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
          ...items.map((a) {
            DateTime dt;
            try {
              dt = DateTime.parse(a.dueDatetime);
            } catch (_) {
              dt = DateTime.now();
            }
            final pretty = 'Due: ${_formatMonthDay(dt)}';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF343A40), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: const Color(0xFF9FB3C6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.title, style: base.bodyLarge?.copyWith(color: const Color(0xFFF7ECE1), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$pretty  •  ${a.submissionLocation ?? ''}', style: base.bodyMedium?.copyWith(color: const Color(0xFF9FB3C6))),
                    ]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ---
// Dart / Flutter code for SQLite schema and helpers for courses, sessions, session_days,
// locations (split into building + room), and assignments. (unchanged from your file, with small tweaks)

/// Models
class Course {
  final String courseCode;
  final String? title;

  Course({required this.courseCode, this.title});

  Map<String, dynamic> toMap() {
    return {
      'course_code': courseCode,
      'title': title,
    };
  }

  static Course fromMap(Map<String, dynamic> m) => Course(
    courseCode: m['course_code'] as String,
    title: m['title'] as String?,
  );
}

/// Location now has id, buildingName and room
class Location {
  final int? id;
  final String buildingName;
  final String? room;

  Location({this.id, required this.buildingName, this.room});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'building_name': buildingName,
    'room': room,
  };

  static Location fromMap(Map<String, dynamic> m) => Location(
    id: m['id'] as int?,
    buildingName: m['building_name'] as String,
    room: m['room'] as String?,
  );

  /// Convenience readable name
  String displayName() => room == null || room!.isEmpty ? buildingName : '$buildingName ${room!}';
}

class Assignment {
  final int? id;
  final String courseCode;
  final String title;
  final String dueDatetime; // ISO-8601: 'YYYY-MM-DD HH:MM'
  final String? submissionLocation; // where to submit (text)

  Assignment({this.id, required this.courseCode, required this.title, required this.dueDatetime, this.submissionLocation});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'course_code': courseCode,
      'title': title,
      'due_datetime': dueDatetime,
      'submission_location': submissionLocation,
    };
  }

  static Assignment fromMap(Map<String, dynamic> m) => Assignment(
    id: m['id'] as int?,
    courseCode: m['course_code'] as String,
    title: m['title'] as String,
    dueDatetime: m['due_datetime'] as String,
    submissionLocation: m['submission_location'] as String?,
  );
}

class Session {
  final int? id;
  final String courseCode;
  final String type; // e.g. "lecture", "lab"
  final String? section;
  final int startMin; // minutes from midnight
  final int endMin; // minutes from midnight
  final int? locationId; // optional FK to locations.id
  final String? locationBuilding; // convenience when reading
  final String? locationRoom; // convenience when reading
  final List<int> weekdays; // 0=Mon .. 6=Sun
  final String? courseTitle; // optional: populated when queries join courses

  Session({
    this.id,
    required this.courseCode,
    required this.type,
    this.section,
    required this.startMin,
    required this.endMin,
    this.locationId,
    this.locationBuilding,
    this.locationRoom,
    required this.weekdays,
    this.courseTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'course_code': courseCode,
      'type': type,
      'section': section,
      'start_min': startMin,
      'end_min': endMin,
      'location_id': locationId,
    };
  }

  static Session fromMap(Map<String, dynamic> m, List<int> days) => Session(
    id: m['id'] as int?,
    courseCode: m['course_code'] as String,
    type: m['type'] as String,
    section: m['section'] as String?,
    startMin: m['start_min'] as int,
    endMin: m['end_min'] as int,
    locationId: m['location_id'] as int?,
    locationBuilding: m['building_name'] as String?,
    locationRoom: m['room'] as String?,
    weekdays: days,
    courseTitle: m['course_title'] as String?,
  );
}

/// Database provider (singleton)
class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  Database? _db;

  // bump version to 2 (kept) — migrations handle prior schemas
  static const int _dbVersion = 2;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'schedule.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        // enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE courses (
        course_code TEXT PRIMARY KEY,
        title TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_name TEXT NOT NULL,
        room TEXT,
        UNIQUE(building_name, room)
      );
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_code TEXT NOT NULL,
        type TEXT NOT NULL,
        section TEXT,
        start_min INTEGER NOT NULL,
        end_min INTEGER NOT NULL,
        location_id INTEGER,
        FOREIGN KEY(course_code) REFERENCES courses(course_code) ON DELETE CASCADE,
        FOREIGN KEY(location_id) REFERENCES locations(id) ON DELETE SET NULL,
        UNIQUE(course_code, type, section, start_min, end_min, location_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE session_days (
        session_id INTEGER NOT NULL,
        weekday INTEGER NOT NULL,
        PRIMARY KEY (session_id, weekday),
        FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_code TEXT NOT NULL,
        title TEXT NOT NULL,
        due_datetime TEXT NOT NULL,
        submission_location TEXT,
        FOREIGN KEY(course_code) REFERENCES courses(course_code) ON DELETE CASCADE
      );
    ''');

    // helpful indexes
    await db.execute('CREATE INDEX idx_sessions_course ON sessions(course_code);');
    await db.execute('CREATE INDEX idx_session_days_weekday ON session_days(weekday);');
    await db.execute('CREATE INDEX idx_assignments_course ON assignments(course_code);');
  }

  /// CRUD helpers

  // Courses
  Future<void> insertCourse(Course course) async {
    final db = await database;
    await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Course?> getCourse(String courseCode) async {
    final db = await database;
    final res = await db.query('courses', where: 'course_code = ?', whereArgs: [courseCode]);
    if (res.isEmpty) return null;
    return Course.fromMap(res.first);
  }

  // Locations
  Future<int> insertLocation(Location loc) async {
    final db = await database;
    return await db.insert('locations', loc.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Location?> getLocationByBuildingAndRoom(String building, String? room) async {
    final db = await database;
    final res = await db.query('locations', where: 'building_name = ? AND (room IS ? OR room = ?)', whereArgs: [building, room, room]);
    if (res.isEmpty) return null;
    return Location.fromMap(res.first);
  }

  Future<int> _ensureLocationInTxnWithBuilding(Transaction txn, String building, String? room) async {
    final rows = await txn.query('locations', where: 'building_name = ? AND (room IS ? OR room = ?)', whereArgs: [building, room, room]);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return await txn.insert('locations', {'building_name': building, 'room': room});
  }

  // Sessions (inserts session + its days atomically). Supports providing locationBuilding/locationRoom or locationId.
  Future<int> insertSession(Session s) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      int? locId = s.locationId;
      if (locId == null && (s.locationBuilding != null && s.locationBuilding!.isNotEmpty)) {
        locId = await _ensureLocationInTxnWithBuilding(txn, s.locationBuilding!, s.locationRoom);
      }

      final sessionMap = s.toMap();
      sessionMap['location_id'] = locId;

      final sessionId = await txn.insert('sessions', sessionMap, conflictAlgorithm: ConflictAlgorithm.abort);
      for (final d in s.weekdays) {
        await txn.insert('session_days', {'session_id': sessionId, 'weekday': d}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return sessionId;
    });
  }

  Future<void> updateSession(Session s) async {
    if (s.id == null) throw ArgumentError('Session.id is required for update');
    final db = await database;
    await db.transaction((txn) async {
      int? locId = s.locationId;
      if (locId == null && (s.locationBuilding != null && s.locationBuilding!.isNotEmpty)) {
        locId = await _ensureLocationInTxnWithBuilding(txn, s.locationBuilding!, s.locationRoom);
      }

      final map = s.toMap();
      map['location_id'] = locId;

      await txn.update('sessions', map, where: 'id = ?', whereArgs: [s.id]);
      // replace days: delete existing and re-insert
      await txn.delete('session_days', where: 'session_id = ?', whereArgs: [s.id]);
      for (final d in s.weekdays) {
        await txn.insert('session_days', {'session_id': s.id, 'weekday': d}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('session_days', where: 'session_id = ?', whereArgs: [sessionId]);
      await txn.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
    });
  }

  /// Assignments CRUD
  Future<int> insertAssignment(Assignment a) async {
    final db = await database;
    return await db.insert('assignments', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAssignment(Assignment a) async {
    if (a.id == null) throw ArgumentError('Assignment.id required for update');
    final db = await database;
    await db.update('assignments', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteAssignment(int id) async {
    final db = await database;
    await db.delete('assignments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Assignment>> getAssignmentsForCourse(String courseCode) async {
    final db = await database;
    final rows = await db.query('assignments', where: 'course_code = ?', whereArgs: [courseCode], orderBy: 'due_datetime');
    return rows.map((r) => Assignment.fromMap(r)).toList();
  }

  /// Queries returning sessions with location building+room included
  Future<List<Session>> getSessionsByWeekday(int weekday) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.*, l.building_name, l.room, c.title AS course_title FROM sessions s
      LEFT JOIN locations l ON s.location_id = l.id
      LEFT JOIN courses c ON s.course_code = c.course_code
      JOIN session_days d ON s.id = d.session_id
      WHERE d.weekday = ?
      ORDER BY s.start_min
    ''', [weekday]);

    List<Session> out = [];
    for (final row in rows) {
      final sessionId = row['id'] as int;
      final dayRows = await db.query('session_days', where: 'session_id = ?', whereArgs: [sessionId]);
      final days = dayRows.map((r) => r['weekday'] as int).toList();
      out.add(Session.fromMap(row, days));
    }
    return out;
  }

  Future<List<Session>> getSessionsForCourse(String courseCode) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.*, l.building_name, l.room, c.title AS course_title FROM sessions s
      LEFT JOIN locations l ON s.location_id = l.id
      LEFT JOIN courses c ON s.course_code = c.course_code
      WHERE s.course_code = ?
      ORDER BY s.start_min
    ''', [courseCode]);

    List<Session> out = [];
    for (final row in rows) {
      final sessionId = row['id'] as int;
      final dayRows = await db.query('session_days', where: 'session_id = ?', whereArgs: [sessionId]);
      final days = dayRows.map((r) => r['weekday'] as int).toList();
      out.add(Session.fromMap(row, days));
    }
    return out;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT s.*, l.building_name, l.room, c.title AS course_title FROM sessions s LEFT JOIN locations l ON s.location_id = l.id LEFT JOIN courses c ON s.course_code = c.course_code ORDER BY s.course_code, s.start_min');
    List<Session> out = [];
    for (final row in rows) {
      final sessionId = row['id'] as int;
      final dayRows = await db.query('session_days', where: 'session_id = ?', whereArgs: [sessionId]);
      final days = dayRows.map((r) => r['weekday'] as int).toList();
      out.add(Session.fromMap(row, days));
    }
    return out;
  }

  /// Locations query
  Future<List<Location>> getAllLocations() async {
    final db = await database;
    final rows = await db.query('locations', orderBy: 'building_name, room');
    return rows.map((r) => Location.fromMap(r)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}

/// Utility: time string <-> minutes
int hhmmToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) throw FormatException('Time must be HH:MM');
  final h = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  return h * 60 + m;
}

String minutesToHhmm(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String _format12Hour(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final period = h >= 12 ? 'pm' : 'am';
  var hour12 = h % 12;
  if (hour12 == 0) hour12 = 12;
  return '${hour12}:${m.toString().padLeft(2, '0')}$period';
}

String minutesTo12HourRange(int start, int end) => '${_format12Hour(start)}–${_format12Hour(end)}';

/// Example usage (for quick testing)
///
/// final dbp = DatabaseProvider();
/// await dbp.insertCourse(Course(courseCode: 'CSCI101', title: 'Intro to CS'));
/// // create or ensure location
/// final locId = await dbp.insertLocation(Location(buildingName: 'Engineering Building', room: '201'));
/// final sessionId = await dbp.insertSession(Session(
///   courseCode: 'CSCI101',
///   type: 'lecture',
///   section: 'A',
///   startMin: hhmmToMinutes('09:00'),
///   endMin: hhmmToMinutes('10:30'),
///   locationId: locId,
///   weekdays: [0, 2], // Monday and Wednesday
/// ));
///
/// // Add an assignment tied to the course (class)
/// await dbp.insertAssignment(Assignment(
///   courseCode: 'CSCI101',
///   title: 'Homework 1',
///   dueDatetime: '2025-11-10 23:59',
///   submissionLocation: 'Canvas',
/// ));