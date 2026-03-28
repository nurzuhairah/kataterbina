import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'play_screen.dart';

class SpinScreen extends StatefulWidget {
  final String username;

  const SpinScreen({super.key, required this.username});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends State<SpinScreen> {
  final List<String> words = [
    "Radio Televisyen Brunei",
    "Teknologi dan Maklumat",
    "Badudun Kuala Belait",
    "Aplikasi Penstriman RTBGo",
    "Sentiasa Bersama Biskita",
  ];

  final StreamController<int> controller = StreamController<int>();
  final AudioPlayer tickPlayer = AudioPlayer();

  int selected = 0;
  bool isSpinning = false;
  Timer? tickTimer;

  @override
  void dispose() {
    controller.close();
    tickPlayer.dispose();
    tickTimer?.cancel();
    super.dispose();
  }

  void playTickSound() async {
    try {
      await tickPlayer.setSource(AssetSource('sounds/tick.wav'));
      await tickPlayer.resume();
    } catch (e) {
      print("Error playing tick: $e");
    }
  }

  Future<void> saveChosenWord(String chosenWord) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: widget.username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'chosenWord': chosenWord});
        print("✅ Saved $chosenWord for ${widget.username}");
      } else {
        // if no user found, create new
        await FirebaseFirestore.instance.collection('users').add({
          'username': widget.username,
          'chosenWord': chosenWord,
        });
        print("✅ Created new user ${widget.username} with $chosenWord");
      }
    } catch (e) {
      print("❌ Firestore error: $e");
    }
  }

  void spinWheel() {
    if (isSpinning) return;

    setState(() => isSpinning = true);

    tickTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!isSpinning) {
        timer.cancel();
      } else {
        playTickSound();
      }
    });

    selected = Random().nextInt(words.length);
    controller.add(selected);

    Future.delayed(const Duration(seconds: 5), () async {
      setState(() => isSpinning = false);

      await tickPlayer.stop();
      tickTimer?.cancel();

      // ✅ Save chosen word to Firestore
      await saveChosenWord(words[selected]);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "🎉 Hasil!",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            content: Text(
              "Anda mendapatkan:\n\n${words[selected]}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayScreen(
                        username: widget.username,
                        chosenWord: words[selected],
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Mulakan Permainan",
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final backgroundImage =
        isTablet ? 'assets/bg_tablet2.png' : 'assets/bg_phone2.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                "🎨 Pilih Perkataan Anda",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FortuneWheel(
                      selected: controller.stream,
                      animateFirst: false,
                      duration: const Duration(seconds: 5),
                      indicators: const <FortuneIndicator>[
                        FortuneIndicator(
                          alignment: Alignment.topCenter,
                          child: TriangleIndicator(
                            color: Colors.redAccent,
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ],
                      items: [
                        for (int i = 0; i < words.length; i++)
                          FortuneItem(
                            style: const FortuneItemStyle(
                              color: Color(0xFF3C1053),
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                            child: Text(
                              words[i],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black54,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade600,
                            Colors.black
                          ],
                          center: Alignment.topLeft,
                          radius: 0.9,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: spinWheel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                ),
                child: const Text("Putar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
