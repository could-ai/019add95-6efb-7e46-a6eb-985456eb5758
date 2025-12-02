import 'package:flutter/material.dart';
import 'package:couldai_user_app/screens/menu_screen.dart';
import 'package:couldai_user_app/game/game_screen.dart';

void main() {
  runApp(const TikTokGameApp());
}

class TikTokGameApp extends StatelessWidget {
  const TikTokGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Interactive Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFE2C55), // TikTok Red/Pink
          secondary: Color(0xFF25F4EE), // TikTok Cyan
          surface: Colors.black,
        ),
        useMaterial3: true,
        fontFamily: 'Proxima Nova', // Fallback font usually
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}
