import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// --- Game Entities ---

enum Team { supporters, opponents }
enum UnitType { minion, soldier, tank, boss }

class GameUnit {
  String id;
  Team team;
  UnitType type;
  double x; // 0.0 (Left) to 1.0 (Right)
  double hp;
  double maxHp;
  double damage;
  double speed;
  double range; // Attack range
  bool isAttacking = false;
  Color color;

  GameUnit({
    required this.id,
    required this.team,
    required this.type,
    required this.x,
    required this.hp,
    required this.damage,
    required this.speed,
    required this.color,
    this.range = 0.05, // 5% of screen width
  }) : maxHp = hp;
}

// --- Game Screen ---

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  // Game State
  List<GameUnit> _units = [];
  double _baseHealthSupporters = 1000;
  double _baseHealthOpponents = 1000;
  final double _maxBaseHealth = 1000;
  
  bool _isGameOver = false;
  Team? _winner;

  // Simulation State (For testing without real API)
  String _lastEventText = "Waiting for interactions...";

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_isGameOver) return;

    setState(() {
      _updateUnits();
      _checkWinCondition();
    });
  }

  void _updateUnits() {
    // 1. Move Units & Reset Attack State
    for (var unit in _units) {
      unit.isAttacking = false;
      
      // Default movement direction
      double moveDir = (unit.team == Team.supporters) ? 1 : -1;
      
      // Look for enemies in range
      GameUnit? target = _findTarget(unit);

      if (target != null) {
        // Attack!
        unit.isAttacking = true;
        target.hp -= unit.damage * 0.1; // Damage per tick
      } else {
        // Move forward if no enemy and not at base
        bool atEnemyBase = (unit.team == Team.supporters && unit.x >= 0.95) ||
                           (unit.team == Team.opponents && unit.x <= 0.05);
        
        if (atEnemyBase) {
          unit.isAttacking = true; // Attacking base
          if (unit.team == Team.supporters) {
            _baseHealthOpponents -= unit.damage * 0.1;
          } else {
            _baseHealthSupporters -= unit.damage * 0.1;
          }
        } else {
          unit.x += unit.speed * moveDir;
        }
      }
    }

    // 2. Remove Dead Units
    _units.removeWhere((unit) => unit.hp <= 0);
  }

  GameUnit? _findTarget(GameUnit attacker) {
    // Simple linear search for closest enemy in range
    GameUnit? closestEnemy;
    double closestDist = 100.0;

    for (var other in _units) {
      if (other.team != attacker.team) {
        double dist = (attacker.x - other.x).abs();
        if (dist <= attacker.range && dist < closestDist) {
          // Check if enemy is in front (not behind)
          bool isFront = (attacker.team == Team.supporters && other.x > attacker.x) ||
                         (attacker.team == Team.opponents && other.x < attacker.x);
          
          if (isFront) {
            closestDist = dist;
            closestEnemy = other;
          }
        }
      }
    }
    return closestEnemy;
  }

  void _checkWinCondition() {
    if (_baseHealthSupporters <= 0) {
      _isGameOver = true;
      _winner = Team.opponents;
    } else if (_baseHealthOpponents <= 0) {
      _isGameOver = true;
      _winner = Team.supporters;
    }
  }

  // --- Spawning Logic ---

  void _spawnUnit(Team team, UnitType type) {
    if (_isGameOver) return;

    double startX = (team == Team.supporters) ? 0.05 : 0.95;
    // Add some random jitter to prevent stacking perfectly
    double jitter = _random.nextDouble() * 0.02; 
    startX += (team == Team.supporters) ? jitter : -jitter;

    double hp = 100;
    double damage = 1;
    double speed = 0.002;
    Color color = Colors.white;
    double range = 0.05;

    switch (type) {
      case UnitType.minion: // From Likes
        hp = 50;
        damage = 2;
        speed = 0.003;
        color = (team == Team.supporters) ? Colors.cyanAccent : Colors.pinkAccent;
        break;
      case UnitType.soldier: // From Comments
        hp = 150;
        damage = 5;
        speed = 0.002;
        color = (team == Team.supporters) ? Colors.blue : Colors.red;
        break;
      case UnitType.tank: // From Shares
        hp = 400;
        damage = 3;
        speed = 0.001;
        color = (team == Team.supporters) ? Colors.indigo : Colors.brown;
        break;
      case UnitType.boss: // From Gifts
        hp = 1000;
        damage = 15;
        speed = 0.001;
        range = 0.1;
        color = Colors.amber;
        break;
    }

    setState(() {
      _units.add(GameUnit(
        id: DateTime.now().microsecondsSinceEpoch.toString() + _random.nextInt(1000).toString(),
        team: team,
        type: type,
        x: startX,
        hp: hp,
        damage: damage,
        speed: speed,
        color: color,
        range: range,
      ));
    });
  }

  // --- Simulation Controls ---
  // In a real app, these would be triggered by a WebSocket or API listener
  
  void _simulateEvent(String eventType, Team team) {
    setState(() {
      _lastEventText = "${team == Team.supporters ? 'Supporter' : 'Opponent'} sent $eventType!";
    });

    switch (eventType) {
      case 'LIKE':
        _spawnUnit(team, UnitType.minion);
        break;
      case 'COMMENT':
        _spawnUnit(team, UnitType.soldier);
        break;
      case 'SHARE':
        _spawnUnit(team, UnitType.tank);
        break;
      case 'GIFT':
        _spawnUnit(team, UnitType.boss);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Battlefield Background
          Positioned.fill(
            child: Column(
              children: [
                // Top Status Bar
                Container(
                  height: 100,
                  color: Colors.grey[900],
                  padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHealthBar(Team.supporters, _baseHealthSupporters),
                      const Text("VS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      _buildHealthBar(Team.opponents, _baseHealthOpponents),
                    ],
                  ),
                ),
                // Battle Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(horizontal: BorderSide(color: Colors.white10)),
                      image: const DecorationImage(
                        image: NetworkImage('https://placeholder.com/battlefield'), // Placeholder or solid color
                        fit: BoxFit.cover,
                        opacity: 0.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Center Line
                        Center(child: Container(width: 2, color: Colors.white10)),
                        
                        // Bases
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: Container(color: Colors.blue.withOpacity(0.2), child: const Center(child: Icon(Icons.shield, color: Colors.cyan))),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: Container(color: Colors.red.withOpacity(0.2), child: const Center(child: Icon(Icons.shield, color: Colors.pink))),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Control Hint
                Container(
                  height: 60,
                  color: Colors.grey[900],
                  alignment: Alignment.center,
                  child: Text(
                    _lastEventText,
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // 2. Units Layer
          Positioned.fill(
            top: 100,
            bottom: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: _units.map((unit) {
                    // Vertical position is random or based on ID to spread them out visually
                    // We hash the ID to get a consistent Y position for the unit
                    double yPos = (int.parse(unit.id.substring(unit.id.length - 3)) % 80) / 100.0;
                    
                    return AnimatedAlign(
                      duration: const Duration(milliseconds: 0), // Real-time
                      alignment: Alignment(
                        (unit.x * 2) - 1, // Convert 0..1 to -1..1
                        (yPos * 1.6) - 0.8, // Spread vertically
                      ),
                      child: _buildUnitWidget(unit),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // 3. Game Over Overlay
          if (_isGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _winner == Team.supporters ? "SUPPORTERS WIN!" : "OPPONENTS WIN!",
                      style: TextStyle(
                        color: _winner == Team.supporters ? Colors.cyan : Colors.pink,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _units.clear();
                          _baseHealthSupporters = _maxBaseHealth;
                          _baseHealthOpponents = _maxBaseHealth;
                          _isGameOver = false;
                          _winner = null;
                        });
                      },
                      child: const Text("RESTART BATTLE"),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("EXIT", style: TextStyle(color: Colors.white54)),
                    )
                  ],
                ),
              ),
            ),

          // 4. Simulation Controls (Draggable or Bottom Sheet)
          // For now, fixed at bottom for easy testing
          if (!_isGameOver)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("SIMULATION PANEL (Streamer Controls)", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSimButton("Like", Colors.cyan, () => _simulateEvent('LIKE', Team.supporters)),
                          _buildSimButton("Comment", Colors.blue, () => _simulateEvent('COMMENT', Team.supporters)),
                          const SizedBox(width: 20),
                          const Text("VS", style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 20),
                          _buildSimButton("Like", Colors.pink, () => _simulateEvent('LIKE', Team.opponents)),
                          _buildSimButton("Comment", Colors.red, () => _simulateEvent('COMMENT', Team.opponents)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSimButton("Gift 🎁", Colors.amber, () => _simulateEvent('GIFT', Team.supporters)),
                          const SizedBox(width: 60),
                          _buildSimButton("Gift 🎁", Colors.amber, () => _simulateEvent('GIFT', Team.opponents)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitWidget(GameUnit unit) {
    double size = 30;
    IconData icon = Icons.person;
    
    switch (unit.type) {
      case UnitType.minion:
        size = 20;
        icon = Icons.favorite;
        break;
      case UnitType.soldier:
        size = 30;
        icon = Icons.person;
        break;
      case UnitType.tank:
        size = 40;
        icon = Icons.shield;
        break;
      case UnitType.boss:
        size = 60;
        icon = Icons.star;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // HP Bar
        Container(
          width: size,
          height: 4,
          color: Colors.grey,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: unit.hp / unit.maxHp,
            child: Container(color: unit.team == Team.supporters ? Colors.cyan : Colors.pink),
          ),
        ),
        // Unit Icon
        Icon(icon, color: unit.color, size: size),
      ],
    );
  }

  Widget _buildHealthBar(Team team, double health) {
    return Column(
      children: [
        Text(
          team == Team.supporters ? "SUPPORTERS" : "OPPONENTS",
          style: TextStyle(
            color: team == Team.supporters ? Colors.cyan : Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 120,
          height: 15,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white24),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (health / _maxBaseHealth).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: team == Team.supporters ? Colors.cyan : Colors.pink,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        Text("${health.toInt()} HP", style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildSimButton(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
