import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // 👈 for platform detection
import 'username_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Background music
  final AudioPlayer _clickPlayer = AudioPlayer(); // Button click sound
  final List<Bubble> bubbles = [];

  static bool _isMusicPlaying = false; // Prevent multiple background music

  @override
  void initState() {
    super.initState();

    // Initialize bubble animation
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();

    for (int i = 0; i < 30; i++) {
      bubbles.add(Bubble());
    }

    // Play music only once
    if (!_isMusicPlaying) {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('music/background.mp3'));
      _isMusicPlaying = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _clickPlayer.dispose();
    super.dispose(); // Do NOT dispose _audioPlayer to keep music playing
  }

  void _playClickSound() async {
    await _clickPlayer.play(AssetSource('sounds/click.wav'));
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // 👇 Detect desktop
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    // 👇 Decide background image
    final backgroundImage = isDesktop
        ? 'assets/bg_comp.png'
        : (isTablet ? 'assets/bg_tablet.png' : 'assets/bg_phone.png');

    Widget buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            textStyle:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 10,
          ),
          child: const Text("🎮 Main"),
          onPressed: () {
            _playClickSound();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      UsernameScreen(audioPlayer: _audioPlayer)),
            );
          },
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            textStyle:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 10,
          ),
          child: const Text("🏆 Papan Kedudukan"),
          onPressed: () {
            _playClickSound();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          },
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return CustomPaint(
                  painter: BubblePainter(bubbles, _controller.value),
                );
              },
            ),
          ),
          isTablet || isDesktop
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 150),
                    child: buttons,
                  ),
                )
              : Center(child: buttons),
        ],
      ),
    );
  }
}

class Bubble {
  late double x;
  late double y;
  late double radius;
  late double speed;
  final Random random = Random();

  Bubble() {
    x = random.nextDouble();
    y = random.nextDouble();
    radius = 5 + random.nextDouble() * 15;
    speed = 0.1 + random.nextDouble() * 0.5;
  }
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);

    for (var bubble in bubbles) {
      double dx = bubble.x * size.width;
      double dy = (bubble.y - animationValue * bubble.speed) * size.height;
      if (dy < 0) dy += size.height;
      canvas.drawCircle(Offset(dx, dy), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => true;
}
