import 'package:flutter/material.dart';
// import 'package:tactinho/tactics_board.dart';
import 'splash_screen.dart';
import 'home_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App Layout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6C41), // Deep green as primary
          primary: const Color(0xFF1E6C41),
          secondary: const Color(0xFFE53935), // Accent red for important actions
          tertiary: const Color(0xFF1565C0), // Blue for information
          background: const Color(0xFFF5F5F5),
          surface: Colors.white,
        ),
        // Custom text theme for better readability
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.w600 , color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16.0),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // int _selectedIndex = 0;
  
  // static const List<Widget> _screens = <Widget>[
  //   HomeScreen(),
  //   TacticsBoard(),
  // ];
  
  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: HomeScreen(),
      // bottomNavigationBar: NavigationBar(
      //   onDestinationSelected: _onItemTapped,
      //   selectedIndex: _selectedIndex,
      //   destinations: const <NavigationDestination>[
      //     NavigationDestination(
      //       icon: Icon(Icons.home_outlined),
      //       selectedIcon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     NavigationDestination(
      //       icon: Icon(Icons.border_clear),
      //       selectedIcon: Icon(Icons.border_all),
      //       label: 'Tactics',
      //     )
      //   ],
      // ),
    );
  }
}