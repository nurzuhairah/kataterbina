import 'dart:ui'; // for ImageFilter
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spin_screen.dart';
import 'home_screen.dart';

class UsernameScreen extends StatefulWidget {
  final AudioPlayer? audioPlayer;

  const UsernameScreen({super.key, this.audioPlayer});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final AudioPlayer _clickPlayer = AudioPlayer();

  // store only filenames here (no "assets/profiles/" prefix)
  final List<String> _profiles = [
    '1.png',
    '2.jpeg',
    '3.png',
    '4.jpeg',
    '5.png',
    '6.jpeg',
    '7.png',
  ];

  int _selectedProfileIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _clickPlayer.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _playClickSound() async {
    try {
      await _clickPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (_) {}
  }

  Future<void> proceed() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan nama anda")),
      );
      return;
    }

    final usernameLower = username.toLowerCase(); // normalize for uniqueness
    widget.audioPlayer?.stop();
    final selectedProfile = _profiles[_selectedProfileIndex]; // e.g. "1.png"

    try {
      // Case-insensitive check using the stored lowercase username
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLower', isEqualTo: usernameLower)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama ini sudah digunakan! Sila pilih lain.")),
        );
        return;
      }

      // Save user with auto-id; store only filename in 'profile'
      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'usernameLower': usernameLower,
        'profile': selectedProfile, // save "1.png"
        'score': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _playClickSound();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SpinScreen(username: username)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  void _previousProfile() {
    _playClickSound();
    if (_selectedProfileIndex > 0) {
      setState(() {
        _selectedProfileIndex--;
        _pageController.animateToPage(
          _selectedProfileIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _nextProfile() {
    _playClickSound();
    if (_selectedProfileIndex < _profiles.length - 1) {
      setState(() {
        _selectedProfileIndex++;
        _pageController.animateToPage(
          _selectedProfileIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final backgroundImage = isTablet ? 'assets/bg_tablet2.png' : 'assets/bg_phone2.png';

    const maxSquareSize = 300.0;
    final squareSize = [
      screenWidth * 0.6,
      screenHeight * 0.4,
      maxSquareSize
    ].reduce((value, element) => value < element ? value : element);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover),
            ),
          ),

          // blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.blueAccent, Colors.cyanAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Pilih Gambar Profil Anda",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // carousel of profile assets (we build asset path here)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(icon: const Icon(Icons.arrow_left, size: 40, color: Colors.white), onPressed: _previousProfile),
                  SizedBox(
                    width: squareSize,
                    height: squareSize,
                    child: PageView.builder(
                      itemCount: _profiles.length,
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _selectedProfileIndex = index),
                      itemBuilder: (context, index) {
                        bool isSelected = index == _selectedProfileIndex;
                        final assetPath = "assets/profiles/${_profiles[index]}";
                        return Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: isSelected ? Border.all(color: Colors.blue, width: 4) : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(aspectRatio: 1, child: Image.asset(assetPath, fit: BoxFit.cover)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.arrow_right, size: 40, color: Colors.white), onPressed: _nextProfile),
                ]),

                const SizedBox(height: 20),
                const Text("Masukkan Nama Anda...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 20),

                // username input
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    labelText: "Nama",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: proceed,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Text("Mulakan Permainan"),
                ),
              ]),
            ),
          ),

          // back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                _playClickSound();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
