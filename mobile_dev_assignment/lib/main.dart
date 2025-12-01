// main.dart
import 'package:flutter/material.dart';
import 'package:mobile_dev_assignment/timer_page.dart';
import 'schedule_page.dart';
import 'map_page.dart';
import 'home_overview_page.dart';
import 'food_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeData customTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF22272C),
    primaryColor: Color(0xFF759FBC),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF7ECE1)),
      bodyMedium: TextStyle(color: Color(0xFFF7ECE1)),
      titleLarge: TextStyle(color: Color(0xFF759FBC)),
      titleMedium: TextStyle(color: Color(0xFF759FBC)),
    ),
    iconTheme: IconThemeData(color: Color(0xFFF7ECE1)),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF22272C),
      foregroundColor: Color(0xFF759FBC),
      titleTextStyle: TextStyle(color: Color(0xFF759FBC), fontSize: 20),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 184, 13, 13),
      selectedItemColor: Color(0xFF759FBC),
      unselectedItemColor: Color(0xFFF7ECE1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Separate Screens Demo',
      theme: customTheme,
      // start at the home overview route
      initialRoute: '/home_overview',
      routes: {
        // Each route is a separate screen; ScreenScaffold wraps the real page widget
        '/home_overview': (context) => ScreenScaffold(
          title: 'Home',
          routeName: '/home_overview',
          child: const HomeOverviewPage(),
        ),
        '/schedule': (context) => ScreenScaffold(
          title: 'Schedule',
          routeName: '/schedule',
          child: const SchedulePage(),
        ),
        '/timer': (context) => ScreenScaffold(
          title: 'Timer',
          routeName: '/timer',
          child: const TimerPage(),
        ),
        '/food': (context) => ScreenScaffold(
          title: 'Food',
          routeName: '/food',
          child: const FoodPage(),
        ),
        '/map': (context) => ScreenScaffold(
          title: 'Map',
          routeName: '/map',
          child: const MapPage(),
        ),
      },
    );
  }
}

// Maps route names to BottomNavigationBar indices
int routeToIndex(String? route) {
  switch (route) {
    case '/schedule':
      return 0;
    case '/timer':
      return 1;
    case '/home_overview':
      return 2;
    case '/food':
      return 3;
    case '/map':
      return 4;
    default:
      return 2;
  }
}

// Index => route name map used by the BottomNavBar
const List<String> indexToRoute = <String>[
  '/schedule',
  '/timer',
  '/home_overview',
  '/food',
  '/map',
];

// A reusable scaffold wrapper that gives each route its own Scaffold (AppBar + body + bottom nav)
class ScreenScaffold extends StatelessWidget {
  final String title;
  final String routeName;
  final Widget child;

  const ScreenScaffold({
    required this.title,
    required this.routeName,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Note: ModalRoute.of(context)?.settings.name should match routeName when navigated via named routes.
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final selectedIndex = routeToIndex(currentRoute);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromARGB(133, 117, 158, 188),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color.fromARGB(107, 0, 0, 0),
              elevation: 0,
              currentIndex: selectedIndex,
              onTap: (index) {
                final targetRoute = indexToRoute[index];
                // only navigate if not already on that route
                if (ModalRoute.of(context)?.settings.name != targetRoute) {
                  // Replace current route so the stack doesn't grow unnecessarily
                  Navigator.of(context).pushReplacementNamed(targetRoute);
                }
              },
              selectedItemColor: const Color.fromARGB(255, 117, 158, 188),
              unselectedItemColor: const Color(0xFFF7ECE1),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Schedule',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_outlined),
                  label: 'Timer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fastfood_outlined),
                  label: 'Food',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  label: 'Map',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}