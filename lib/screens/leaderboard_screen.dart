import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/storage_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  ImageProvider _profileImageProvider(String profileRaw) {
    // profileRaw can be:
    // - a network URL (startsWith http)
    // - just a filename like "1.png"
    // - the full asset path like "assets/profiles/1.png"
    // We handle all three cases; fallback to asset 'assets/profiles/1.png'
    if (profileRaw.isEmpty) {
      return const AssetImage('assets/profiles/1.png');
    }

    final trimmed = profileRaw.trim();
    if (trimmed.startsWith('http')) {
      return NetworkImage(trimmed);
    }

    // if someone accidentally stored the full asset path already, handle it
    if (trimmed.contains('assets/profiles/')) {
      return AssetImage(trimmed);
    }

    // otherwise, assume it's a filename and prepend the assets path
    return AssetImage('assets/profiles/$trimmed');
  }

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text("🏆 Papan Kedudukan"), centerTitle: true),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(isTablet ? 'assets/bg_tablet2.png' : 'assets/bg_phone2.png'), fit: BoxFit.cover),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: storage.getLeaderboard(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text("Tiada markah direkodkan!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final username = data['username'] ?? 'Unknown';
                final score = data['score'] ?? 0;
                final chosenWord = data['chosenWord'] ?? 'Tiada perkataan';
                final profileRaw = (data['profile'] ?? '').toString();

                final profileImage = _profileImageProvider(profileRaw);

                // highlight top 3
                Color rankColor;
                switch (index) {
                  case 0:
                    rankColor = Colors.amber;
                    break;
                  case 1:
                    rankColor = Colors.grey.shade400;
                    break;
                  case 2:
                    rankColor = Colors.brown.shade300;
                    break;
                  default:
                    rankColor = Colors.blue.shade100;
                }

                return Card(
                  color: rankColor.withOpacity(0.5),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(radius: 25, backgroundImage: profileImage),
                    title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Mata: $score pts", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      Text("Perkataan: $chosenWord", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ]),
                    trailing: Text("#${index + 1}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
