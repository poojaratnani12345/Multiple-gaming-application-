import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HighScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update high score
  Future<void> updateHighScore(String game, int score, [String? s]) async {
    final user = FirebaseAuth.instance.currentUser; // Get current user
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          '${game}_high_score': score,
        }, SetOptions(merge: true)); // Use merge to avoid overwriting other user data
        print("High score updated for $game: $score");
      } catch (e) {
        print("Error updating high score: $e");
      }
    }
  }

  // Retrieve high scores for a user
  Future<Map<String, dynamic>?> getUserHighScores([String? userId]) async {
    try {
      userId ??= FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        print("User not authenticated.");
        return null;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Error getting user high scores: $e");
      return null;
    }
  }

  // Update game play count
  Future<void> updateGamePlayCount(String userId, String gameName) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);

    try {
      await userRef.set({
        'gamesPlayed': {gameName: FieldValue.increment(1)}
      }, SetOptions(merge: true));
      print("Play count updated for $gameName");
    } catch (e) {
      print("Failed to update play count: $e");
    }
  }

  // Clean up incorrect fields
  Future<void> cleanUpIncorrectFields(String userId) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'raMcZpdt3qf51ooLOXlw6LWdYkE3_high_score': FieldValue.delete(),
      });
      print("Unwanted field removed.");
    } catch (e) {
      print("Failed to clean up fields: $e");
    }
  }
}
