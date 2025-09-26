import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:movie_booking_app/views/about_us/about_us_screen.dart';
import 'package:movie_booking_app/views/home/home_screen.dart';
import 'package:movie_booking_app/views/profile/profile_screen.dart';
import 'package:movie_booking_app/theme/app_theme.dart';
import 'package:movie_booking_app/views/ticket_history/ticket_history.dart';

class ScreenController extends StatefulWidget {
  const ScreenController({super.key});

  @override
  State<ScreenController> createState() => _ScreenControllerState();
}

class _ScreenControllerState extends State<ScreenController> {
  int currentScreen = 0;
  void switchScreen(int selectedScreen) {
    setState(() {
      currentScreen = selectedScreen;
    });
  }

  List<Widget> screens = [
    HomeScreen(),
    TicketHistory(),
    AboutUsScreen(),
    ProfileScreen(),
  ];

  List<String> screenTitles = [
    "CineMax",
    "Ticket History",
    "About Us",
    "Profile",
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 10),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF212121).withValues(alpha:0.6),
                    const Color(0xFF212121).withValues(alpha:0.3),
                    const Color(0xFF212121).withValues(alpha:0.2),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha:0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF212121).withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: AppBar(
                  title: Text(
                    screenTitles[currentScreen],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF212121).withValues(alpha:0.5),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: screens[currentScreen],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: NavigationBar(
            backgroundColor: const Color(0xFF212121).withValues(alpha:0.6),
            indicatorColor: AppTheme.primaryRed
            ,
            onDestinationSelected: switchScreen,
            selectedIndex: currentScreen,
            labelTextStyle: WidgetStateProperty.all(
              TextStyle(color: Colors.white),
            ),
            destinations: [
              NavigationDestination(
                selectedIcon: Icon(Icons.home, color: Colors.white),
                icon: Icon(Icons.home, color: Colors.grey),
                label: "Home",
              ),
              NavigationDestination(
                selectedIcon: Icon(
                  Icons.confirmation_number,
                  color: Colors.white,
                ),
                icon: Icon(Icons.confirmation_number, color: Colors.grey),
                label: "Ticket",
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.info, color: Colors.white),
                icon: Icon(Icons.info, color: Colors.grey),
                label: "about us",
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.person, color: Colors.white),
                icon: Icon(Icons.person, color: Colors.grey),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
