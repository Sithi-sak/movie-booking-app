import 'package:flutter/material.dart';
import 'package:movie_booking_app/theme/app_theme.dart';
import 'package:movie_booking_app/views/screen_control/screen_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie App',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const ScreenController(),
    );
  }
}
