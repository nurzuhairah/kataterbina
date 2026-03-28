import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/storage_service.dart';
import '../services/word_checker.dart';

class PlayScreen extends StatefulWidget {
  final String username;
  final String chosenWord;
  final String? profile; // optional profile picture

  const PlayScreen({
    super.key,
    required this.username,
    required this.chosenWord,
    this.profile,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  final StorageService _storage = StorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Set<String> submittedWords = {};
  int totalScore = 0;
  int secondsLeft = 90;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsLeft > 0) {
          secondsLeft--;
        } else {
          timer.cancel();
          submitScore();
        }
      });
    });
  }

  Future<void> playWrongSound() async {
    await _audioPlayer.play(AssetSource("sounds/wrong.wav"));
  }

  void showTemporaryPopup(String message, {Color color = Colors.red}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void addWord() {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    final wordLower = word.toLowerCase();

    if (submittedWords.contains(wordLower)) {
      showTemporaryPopup("⚠️ '$word' Sudah Termasuk!", color: Colors.orange);
      _wordController.clear();
      _wordFocusNode.requestFocus();
      return;
    }

    if (!WordChecker.isValid(word, widget.chosenWord)) {
      playWrongSound();
      showTemporaryPopup("❌ '$word' Tidak Bisa Digunakan!");
      _wordController.clear();
      _wordFocusNode.requestFocus();
      return;
    }

    // ✅ Correct score logic
    int score;
    if (word.length <= 2) {
      score = 1; // short word
    } else if (word.length <= 4) {
      score = 2; // medium word
    } else {
      score = 3; // long word
    }

    setState(() {
      submittedWords.add(wordLower);
      totalScore += score;
      _wordController.clear();
    });

    showTemporaryPopup("✅ '$word' Diterima! +$score points", color: Colors.green);
    _wordFocusNode.requestFocus();
  }

  void submitScore() async {
    _timer?.cancel();

    await _storage.saveScore(
      widget.username,
      totalScore,
      profile: widget.profile,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⏰ Masa telah tamat!"),
        content: Text("${widget.username} mendapatkan $totalScore mata point!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wordController.dispose();
    _wordFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isTablet ? "assets/bg_tablet2.png" : "assets/bg_phone2.png",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Timer
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "⏳ $secondsLeft s",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Chosen word
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.chosenWord,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              // Word input
              TextField(
                controller: _wordController,
                focusNode: _wordFocusNode,
                autofocus: true,
                onSubmitted: (_) {
                  addWord();
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  hintText: "Masukkan kata",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Tambah",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "⭐ Jumlah Mata: $totalScore",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Word list
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    children: submittedWords
                        .map(
                          (w) => ListTile(
                            title: Text(
                              w,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
