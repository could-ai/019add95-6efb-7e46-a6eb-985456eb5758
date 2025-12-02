import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum ItemType { heart, gift, hater, bomb }

class GameItem {
  String id;
  double x; // -1.0 to 1.0
  double y; // -1.0 to 1.0 (starts at -1.5 usually)
  ItemType type;
  double speed;

  GameItem({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    required this.speed,
  });
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  
  // Game State
  double _playerX = 0.0;
  List<GameItem> _items = [];
  int _score = 0;
  bool _isGameOver = false;
  bool _isPlaying = false;
  int _lives = 3;
  
  // Difficulty scaling
  double _baseSpeed = 0.01;
  double _spawnRate = 0.02; // Chance per frame to spawn
  
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _startGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _playerX = 0.0;
      _items.clear();
      _score = 0;
      _lives = 3;
      _isGameOver = false;
      _isPlaying = true;
      _baseSpeed = 0.01;
    });
    _ticker.start();
  }

  void _stopGame() {
    _ticker.stop();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;

    setState(() {
      // 1. Spawn new items
      if (_random.nextDouble() < _spawnRate) {
        _spawnItem();
      }

      // 2. Move items
      for (var item in _items) {
        item.y += item.speed;
      }

      // 3. Remove off-screen items
      _items.removeWhere((item) => item.y > 1.5);

      // 4. Check collisions
      _checkCollisions();
      
      // 5. Increase difficulty slowly
      _baseSpeed += 0.000005;
    });
  }

  void _spawnItem() {
    // Determine type based on probabilities
    double roll = _random.nextDouble();
    ItemType type;
    if (roll < 0.6) {
      type = ItemType.heart; // 60% Hearts
    } else if (roll < 0.7) {
      type = ItemType.gift; // 10% Gifts (Bonus)
    } else if (roll < 0.9) {
      type = ItemType.hater; // 20% Haters
    } else {
      type = ItemType.bomb; // 10% Bombs (Instant kill or big damage)
    }

    _items.add(
      GameItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        x: (_random.nextDouble() * 2) - 1, // -1.0 to 1.0
        y: -1.2, // Start slightly above screen
        type: type,
        speed: _baseSpeed + (_random.nextDouble() * 0.01),
      ),
    );
  }

  void _checkCollisions() {
    // Simple AABB collision or distance check
    // Player is approx at y = 0.8, width approx 0.2 in alignment space
    double playerY = 0.8;
    double hitBoxSize = 0.15; // Rough size of hit area

    List<GameItem> itemsToRemove = [];

    for (var item in _items) {
      // Check vertical proximity
      if ((item.y - playerY).abs() < hitBoxSize) {
        // Check horizontal proximity
        if ((item.x - _playerX).abs() < hitBoxSize) {
          // Collision!
          _handleCollision(item);
          itemsToRemove.add(item);
        }
      }
    }

    _items.removeWhere((item) => itemsToRemove.contains(item));
  }

  void _handleCollision(GameItem item) {
    switch (item.type) {
      case ItemType.heart:
        _score += 100;
        break;
      case ItemType.gift:
        _score += 500;
        break;
      case ItemType.hater:
        _lives--;
        if (_lives <= 0) _stopGame();
        break;
      case ItemType.bomb:
        _lives = 0;
        _stopGame();
        break;
    }
  }

  void _updatePlayerPosition(DragUpdateDetails details, double screenWidth) {
    if (!_isPlaying) return;
    
    // Convert pixel delta to alignment delta (-1 to 1)
    // Screen width corresponds to alignment width of 2.0
    double delta = (details.delta.dx / screenWidth) * 2;
    
    setState(() {
      _playerX += delta;
      // Clamp to screen bounds
      if (_playerX < -1.0) _playerX = -1.0;
      if (_playerX > 1.0) _playerX = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onHorizontalDragUpdate: (details) => 
                _updatePlayerPosition(details, constraints.maxWidth),
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF111111), Colors.black],
                    ),
                  ),
                ),

                // Game Items
                ..._items.map((item) => AnimatedAlign(
                  duration: Duration.zero, // Real-time update
                  alignment: Alignment(item.x, item.y),
                  child: _buildItemWidget(item),
                )),

                // Player
                Align(
                  alignment: Alignment(_playerX, 0.8),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF25F4EE), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25F4EE).withOpacity(0.5),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.black, size: 40),
                  ),
                ),

                // UI Overlay (Score & Lives)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'LIKES: $_score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Color(0xFFFE2C55), blurRadius: 10)
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(3, (index) => Icon(
                            Icons.favorite,
                            color: index < _lives ? const Color(0xFFFE2C55) : Colors.grey.withOpacity(0.3),
                            size: 30,
                          )),
                        )
                      ],
                    ),
                  ),
                ),

                // Game Over Overlay
                if (_isGameOver)
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GAME OVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Total Likes: $_score',
                            style: const TextStyle(
                              color: Color(0xFF25F4EE),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFE2C55),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'EXIT TO MENU',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemWidget(GameItem item) {
    IconData icon;
    Color color;
    double size = 40;

    switch (item.type) {
      case ItemType.heart:
        icon = Icons.favorite;
        color = const Color(0xFFFE2C55); // Red
        break;
      case ItemType.gift:
        icon = Icons.card_giftcard;
        color = Colors.amber; // Gold
        size = 50;
        break;
      case ItemType.hater:
        icon = Icons.mood_bad;
        color = Colors.purpleAccent;
        break;
      case ItemType.bomb:
        icon = Icons.block;
        color = Colors.grey;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.8),
    );
  }
}
