import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save a user's score. Updates only if the new score is higher.
  Future<void> saveScore(String username, int score, {String? profile}) async {
    try {
      // Find the existing document by username
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // ✅ Update existing user document (auto-generated ID)
        final docRef = query.docs.first.reference;
        final previousScore = query.docs.first.data()['score'] ?? 0;

        if (score > previousScore) {
          await docRef.update({
            'score': score,
            'profile': profile ?? query.docs.first.data()['profile'] ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // ❌ If somehow no user exists, create a new one (rare case)
        await _db.collection('users').add({
          'username': username,
          'score': score,
          'profile': profile ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving score: $e");
      rethrow;
    }
  }

  /// Get top users by score (hide 0 points)
  Stream<QuerySnapshot> getLeaderboard() {
    return _db
        .collection('users')
        .where('score', isGreaterThan: 0)
        .orderBy('score', descending: true)
        .limit(20)
        .snapshots();
  }
}
