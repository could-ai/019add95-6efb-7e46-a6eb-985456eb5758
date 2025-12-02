import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title with TikTok style glitch effect colors
              Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(-2, -2),
                    child: const Text(
                      'TIKTOK\nRUNNER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF25F4EE), // Cyan
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(2, 2),
                    child: const Text(
                      'TIKTOK\nRUNNER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFE2C55), // Red
                      ),
                    ),
                  ),
                  const Text(
                    'TIKTOK\nRUNNER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Collect Hearts ❤️ Avoid Haters 😡',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 60),
              
              // Play Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/game');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFE2C55).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Text(
                    'START LIVE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
