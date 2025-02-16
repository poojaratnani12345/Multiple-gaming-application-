import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_combo_game/Services/High_score.dart';
import 'package:multi_combo_game/page/dianosaur_game/dinosaur.dart';
import 'cactus.dart';
import 'cloud.dart';
import 'game_object.dart';
import 'ground.dart';
import 'constants.dart';

class DianoserGame extends StatelessWidget {
  const DianoserGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return const MaterialApp(
      title: 'Dinosaur',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


final FirebaseFirestore _firestore = FirebaseFirestore.instance;


class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  Dinosaur dinosaur = Dinosaur();
  double runVelocity = initialVelocity;
  double runDistance = 0;
  double highScore = 0; // High score tracking
  bool hackMode = false;
  bool isGameStarted = false;
  bool isGameOver = false; // Game over flag
  
// Controllers for settings
final TextEditingController gravityController = TextEditingController(text: gravity.toString());
final TextEditingController accelerationController = TextEditingController(text: acceleration.toString());
final TextEditingController dayNightOffsetController = TextEditingController(text: dayNightOffest.toString());
final TextEditingController jumpVelocityController = TextEditingController(text: jumpVelocity.toString());
final TextEditingController runVelocityController = TextEditingController(text: initialVelocity.toString());

  late AnimationController worldController;
  Duration lastUpdateCall = const Duration();

  List<Cactus> cacti = [Cactus(worldLocation: const Offset(200, 0))];

  List<Ground> ground = [
    Ground(worldLocation: const Offset(0, 0)),
    Ground(worldLocation: Offset(groundImageModel.imageWidth / 10, 0))
  ];

  List<Cloud> clouds = [
    Cloud(worldLocation: const Offset(100, 20)),
    Cloud(worldLocation: const Offset(200, 10)),
    Cloud(worldLocation: const Offset(350, -10)),
  ];

  @override
  void initState() {
    super.initState();
    worldController = AnimationController(vsync: this, duration: const Duration(days: 99));
    worldController.addListener(_update);
    _loadHighScore(); // Load saved high score from the database
  }


String getCurrentUserId() {
  final User? user = FirebaseAuth.instance.currentUser;
  return user != null ? user.uid : "";
}



 void _die() async {
  setState(() {
    isGameOver = true;
    highScore = max(highScore, runDistance);
    worldController.stop();
  });

  String userId = "CURRENT_USER_ID"; // Get the current user's ID
  onGameEnd(userId); // Update play count

  await HighScoreService().updateHighScore("DinosaurGame", highScore.toInt());

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('score submitted successfully!'),
    ),
  );
}




void _newGame() {
  setState(() {
    isGameStarted = true;
    isGameOver = false;
    runDistance = 0;
    runVelocity = initialVelocity;
    dinosaur.state = dinosaurState.running;
    dinosaur.dispY = 0;
    worldController.reset();

    cacti = [
      Cactus(worldLocation: const Offset(200, 0)),
      Cactus(worldLocation: const Offset(300, 0)),
      Cactus(worldLocation: const Offset(450, 0)),
    ];

    ground = [
      Ground(worldLocation: const Offset(0, 0)),
      Ground(worldLocation: Offset(groundImageModel.imageWidth / 10, 0))
    ];

    clouds = [
      Cloud(worldLocation: const Offset(100, 20)),
      Cloud(worldLocation: const Offset(200, 10)),
      Cloud(worldLocation: const Offset(350, -15)),
      Cloud(worldLocation: const Offset(500, 10)),
      Cloud(worldLocation: const Offset(550, -10)),
    ];

    worldController.forward();

    // Get the current user ID
    String userId = getCurrentUserId();

    if (userId.isNotEmpty) {
      // Update play count for the current user
      updateGamePlayCount(userId, 'DinosaurGame');
    } else {
      print("User is not authenticated");
    }
  });
}


void _loadHighScore() async {
  String userId = getCurrentUserId(); // Ensure you're getting the correct user ID

  if (userId.isEmpty) {
    print("User is not authenticated.");
    return; // No user is logged in, skip fetching the high score
  }

  try {
    // Fetch saved high score (if any) from the Firestore
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      // If the document exists, fetch the high score from the document
      var data = userDoc.data() as Map<String, dynamic>;
      int? savedHighScore = data['DinosaurGame_high_score'];

      if (savedHighScore != null) {
        setState(() {
          highScore = savedHighScore.toDouble();
        });
      } else {
        print("High score not found for user: $userId");
      }
    } else {
      print("User document does not exist in Firestore");
    }
  } catch (e) {
    print("Error fetching high score: $e");
  }
}

void updateGamePlayCount(String userId, String gameName) async {
  // Reference to the user's document in the "users" collection
  DocumentReference userRef = _firestore.collection('users').doc(userId);

  try {
    // Check if the document exists
    DocumentSnapshot docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      // If the document does not exist, create it with the playcount set to 1
      await userRef.set({
        'playcount': 1,
        'gamesPlayed': {
          gameName: 1
        }
      });
      print("Document created with playcount = 1 for $gameName");
    } else {
      // If the document exists, update the playcount and the specific game's play count
      await userRef.update({
        'playcount': FieldValue.increment(1), // Increment the playcount
        'gamesPlayed.$gameName': FieldValue.increment(1) // Increment the game-specific play count
      });
      print("Play count updated for $gameName and global playcount incremented.");
    }
  } catch (error) {
    print("Failed to update play count: $error");
  }
}

  _update() {
    try {
      double elapsedTimeSeconds;
      dinosaur.update(lastUpdateCall, worldController.lastElapsedDuration);
      try {
        elapsedTimeSeconds = (worldController.lastElapsedDuration! - lastUpdateCall).inMilliseconds / 1000;
      } catch (_) {
        elapsedTimeSeconds = 0;
      }

      runDistance += runVelocity * elapsedTimeSeconds;
      if (runDistance < 0) runDistance = 0;

      Size screenSize = MediaQuery.of(context).size;

      Rect dinosaurRect = dinosaur.getRect(screenSize, runDistance);
      for (Cactus cactus in cacti) {
        Rect obstacleRect = cactus.getRect(screenSize, runDistance);
        if (!hackMode && dinosaurRect.overlaps(obstacleRect.deflate(30))) {
          _die();
        }

        if (obstacleRect.right < 0) {
          var offsetX = runDistance + 150 + MediaQuery.of(context).size.width / worlToPixelRatio;

          setState(() {
            cacti.remove(cactus);
            cacti.add(Cactus(worldLocation: Offset(offsetX, 0)));
          });
        }
      }

      for (Ground groundlet in ground) {
        if (groundlet.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            ground.remove(groundlet);
            ground.add(
              Ground(
                worldLocation: Offset(
                  ground.last.worldLocation.dx + groundImageModel.imageWidth / 10,
                  0,
                ),
              ),
            );
          });
        }
      }

      for (Cloud cloud in clouds) {
        if (cloud.getRect(screenSize, runDistance).right < 0) {
          setState(() {
            clouds.remove(cloud);
            clouds.add(
              Cloud(
                worldLocation: Offset(
                  clouds.last.worldLocation.dx + Random().nextInt(200) + MediaQuery.of(context).size.width / worlToPixelRatio,
                  Random().nextInt(50) - 25.0,
                ),
              ),
            );
          });
        }
      }

      lastUpdateCall = worldController.lastElapsedDuration!;
    } catch (e) {
      print("Got Error: $e");
    }
  }

void _showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Game Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gravityController,
              decoration: const InputDecoration(labelText: "Gravity"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: accelerationController,
              decoration: const InputDecoration(labelText: "Acceleration"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: dayNightOffsetController,
              decoration: const InputDecoration(labelText: "Day/Night Offset"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: jumpVelocityController,
              decoration: const InputDecoration(labelText: "Jump Velocity"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: runVelocityController,
              decoration: const InputDecoration(labelText: "Run Velocity"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog without saving
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Update settings based on user input
                gravity = int.tryParse(gravityController.text) ?? gravity;
                acceleration = double.tryParse(accelerationController.text) ?? acceleration;
                dayNightOffest = int.tryParse(dayNightOffsetController.text) ?? dayNightOffest;
                jumpVelocity = double.tryParse(jumpVelocityController.text) ?? jumpVelocity;
                runVelocity = double.tryParse(runVelocityController.text) ?? initialVelocity;
              });
              Navigator.pop(context); // Close the dialog
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}


  @override
void dispose() {
  worldController.dispose();
  gravityController.dispose();
  accelerationController.dispose();
  dayNightOffsetController.dispose();
  jumpVelocityController.dispose();
  runVelocityController.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    List<Widget> children = [];

    for (GameObject object in [...clouds, ...ground, ...cacti, dinosaur]) {
      children.add(
        AnimatedBuilder(
          animation: worldController,
          builder: (context, _) {
            Rect objectRect = object.getRect(screenSize, runDistance);
            return Positioned(
              left: objectRect.left,
              top: objectRect.top,
              width: objectRect.width,
              height: objectRect.height,
              child: object.render(),
            );
          },
        ),
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 5000),
        color: (runDistance ~/ dayNightOffest) % 2 == 0 ? Colors.white : Colors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!isGameOver && dinosaur.state != dinosaurState.dead) {
              dinosaur.jump();
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...children,
              Positioned(
                left: screenSize.width / 2 - 30,
                top: 100,
                child: AnimatedBuilder(
                  animation: worldController,
                  builder: (context, _) {
                    return Text(
                      'Score: ${runDistance.toInt()}',
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0 ? Colors.black : Colors.white,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: screenSize.width / 2 - 30,
                top: 150,
                child: AnimatedBuilder(
                  animation: worldController,
                  builder: (context, _) {
                    return Text(
                      'High Score: ${highScore.toInt()}',
                      style: TextStyle(
                        color: (runDistance ~/ dayNightOffest) % 2 == 0 ? Colors.black : Colors.white,
                      ),
                    );
                  },
                ),
              ),
              if (isGameOver)
                Positioned(
                  left: screenSize.width / 2 - 75,
                  top: screenSize.height / 2 - 50,
                  child: const Text(
                    'Game Over',
                    style: TextStyle(fontSize: 30, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              Positioned(
                left: screenSize.width / 2 - 75,
                bottom: 50,
                child: AnimatedOpacity(
                  opacity: isGameStarted && !isGameOver ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: _newGame,
                    child: const Text("play"),
                  ),
                ),
              ),
              // Add your settings button here
              Positioned(
                right: 20,
                top: 50,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Color.fromARGB(255, 16, 147, 156)),
                  onPressed: () => _showSettingsDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void onGameEnd(String userId) {
  HighScoreService().updateGamePlayCount(userId, 'DinosaurGame'); // Pass the actual user ID
  }
}
