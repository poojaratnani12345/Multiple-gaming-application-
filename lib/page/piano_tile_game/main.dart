// ignore_for_file: unused_local_variable

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_combo_game/Services/High_score.dart';
import 'package:multi_combo_game/page/piano_tile_game/line.dart';
import 'package:multi_combo_game/page/piano_tile_game/line_divider.dart';
import 'package:multi_combo_game/page/piano_tile_game/note.dart';
import 'package:multi_combo_game/page/piano_tile_game/song_provider.dart';

class Piano extends StatefulWidget {
  @override
  _PianoState createState() => _PianoState();
}

class _PianoState extends State<Piano> with SingleTickerProviderStateMixin {
  AudioPlayer player = AudioPlayer();
  List<Note> notes = initNotes();
  AnimationController? animationController;
  int currentNoteIndex = 0;
  int points = 0;
  int highScore = 0; // High score variable for piano game
  bool hasStarted = false;
  bool isPlaying = true;

  late HighScoreService highScoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    highScoreService = HighScoreService();
    _loadHighScore("piano"); // Load the high score for piano tile game
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && isPlaying) {
        if (notes[currentNoteIndex].state != NoteState.tapped) {
          // Game over
          setState(() {
            isPlaying = false;
            notes[currentNoteIndex].state = NoteState.missed;
            player.play(AssetSource('music/piano_tile/gameover.mp3'));
          });
          animationController!.reverse().then((_) => _showFinishDialog());
        } else if (currentNoteIndex == notes.length - 5) {
          // Song finished
          _showFinishDialog();
        } else {
          setState(() => ++currentNoteIndex);
          animationController!.forward(from: 0);
        }
      }
    });
  }

  // Function to get the current user ID
  String getCurrentUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null ? user.uid : "default_user_id"; // Replace with your logic
  }

  // Function to update play count in Firestore
  void updateGamePlayCount(String userId, String gameName) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);

    try {
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'playcount': 1,
          'gamesPlayed': {
            gameName: 1,
          },
        });
        print("Document created with playcount = 1 for $gameName");
      } else {
        await userRef.update({
          'playcount': FieldValue.increment(1),
          'gamesPlayed.$gameName': FieldValue.increment(1),
        });
        print("Play count updated for $gameName and global playcount incremented.");
      }
    } catch (error) {
      print("Failed to update play count: $error");
    }
  }

  // Load high score for piano game
// Load high score for piano game
Future<void> _loadHighScore(String game) async {
  String userId = getCurrentUserId(); // Get the current user's ID

  try {
    var scores = await highScoreService.getUserHighScores(userId);
    print("Fetched scores for user $userId: $scores");

    if (scores != null && scores.containsKey('piano_tile_high_score')) {
      setState(() {
        highScore = scores['piano_tile_high_score'];
      });
      print("High score loaded: $highScore");
    } else {
      print("No high score found for piano_tile.");
      setState(() {
        highScore = 0;
      });
    }
  } catch (e) {
    print("Error loading high score for piano_tile: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Image.asset(
            'assets/images/piano_tile/background.jpg',
            fit: BoxFit.cover,
          ),
          Row(
            children: <Widget>[
              _drawLine(0),
              LineDivider(),
              _drawLine(1),
              LineDivider(),
              _drawLine(2),
              LineDivider(),
              _drawLine(3),
              LineDivider(),
              _drawLine(4),
            ],
          ),
          _drawPoints(),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      hasStarted = false;
      isPlaying = true;
      notes = initNotes();
      points = 0;
      currentNoteIndex = 0;
    });
    animationController!.reset();
  }

Future<void> _showFinishDialog() async {
  if (points > highScore) {
    highScore = points; // Update the high score if the current score is higher
    String userId = getCurrentUserId();
    // Pass the game name 'piano_tile' to update the high score for the Piano game
    await highScoreService.updateHighScore('piano_tile', highScore); // Save to Firestore
  }

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color.fromARGB(255, 208, 223, 235),
        elevation: 0,
        title: Text("Score: $points\nHigh Score: $highScore"),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text("RESTART"),
          ),
        ],
      );
    },
  );
}

  void _onTap(Note note) {
    bool areAllPreviousTapped = notes
        .sublist(0, note.orderNumber)
        .every((n) => n.state == NoteState.tapped);
    if (areAllPreviousTapped) {
      if (!hasStarted) {
        setState(() {
          hasStarted = true;
          isPlaying = true;

          // Update the play count when the user starts playing
          String userId = getCurrentUserId();
          if (userId.isNotEmpty) {
            updateGamePlayCount(userId, 'PianoGame');
          }
        });
        animationController!.forward();
      }
      _playNote(note);
      setState(() {
        note.state = NoteState.tapped;
        ++points;
      });
    }
  }

  Widget _drawLine(int lineNumber) {
    return Expanded(
      child: Line(
        lineNumber: lineNumber,
        currentNotes: notes.sublist(currentNoteIndex, currentNoteIndex + 5),
        onTileTap: _onTap,
        animation: animationController!,
      ),
    );
  }

  Widget _drawPoints() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: Text(
          "$points",
          style: const TextStyle(color: Colors.red, fontSize: 60),
        ),
      ),
    );
  }

  void _playNote(Note note) {
    final soundMap = {
      0: 'a.wav',
      1: 'c.wav',
      2: 'e.wav',
      3: 'f.wav',
      4: 'g.mp3',
    };

    if (soundMap.containsKey(note.line)) {
      player.play(AssetSource('music/piano_tile/${soundMap[note.line]}'));
    }
  }
}
