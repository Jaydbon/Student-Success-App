import 'package:flutter/material.dart';
import 'package:mobile_dev_assignment/timer_page.dart';
import 'schedule_page.dart';
import 'map_page.dart';

void main() {
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  final ThemeData customTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF22272C),
    primaryColor: const Color(0xFF759FBC),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF7ECE1)),
      bodyMedium: TextStyle(color: Color(0xFFF7ECE1)),
      titleLarge: TextStyle(color: Color(0xFF759FBC)),
      titleMedium: TextStyle(color: Color(0xFF759FBC)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFF7ECE1)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF22272C),
      foregroundColor: Color(0xFF759FBC),
      titleTextStyle: TextStyle(color: Color(0xFF759FBC), fontSize: 20),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 184, 13, 13),
      selectedItemColor: Color(0xFF759FBC),
      unselectedItemColor: Color(0xFFF7ECE1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: customTheme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  static const List<String> pages = <String>[
    'Schedule',
    'Timer',
    'Home',
    'Food',
    'Map'
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const SchedulePage(), // external file
    const TimerPage(),
    Center(child: Text('Home (coming soon)')),
    Center(child: Text('Food (coming soon)')),
    MapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pages[selectedIndex]),
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        // space around the bar
        decoration: BoxDecoration(
          color: const Color.fromARGB(133, 117, 158, 188),
          // background color
          borderRadius: BorderRadius.circular(30),
          // rounded corners
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
            // let container color show through
            elevation: 0,
            // remove default shadow
            currentIndex: selectedIndex,
            onTap: _onItemTapped,
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
    );
  }
}
