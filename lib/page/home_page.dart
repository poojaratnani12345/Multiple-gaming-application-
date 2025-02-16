import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_combo_game/page/2048_game/home_screen.dart';
import 'package:multi_combo_game/page/ai_tic_tac_toe/home_screen.dart';
import 'package:multi_combo_game/page/dianosaur_game/main.dart';
import 'package:multi_combo_game/page/mini_sweeper/widget/game.dart';
import 'package:multi_combo_game/page/pacman_game/HomePage.dart';
import 'package:multi_combo_game/page/piano_tile_game/main.dart';
import 'package:multi_combo_game/utils/data.dart';
import 'package:multi_combo_game/components/grid_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLiked = false;
  int totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserLikes();
  }

  void _fetchUserLikes() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        totalLikes = userDoc.data()?['likes'] ?? 0;
        isLiked = userDoc.data()?['isLiked'] ?? false;
      });
    }
  }

  void _toggleLike() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    setState(() {
      isLiked = !isLiked;
      totalLikes = isLiked ? totalLikes + 1 : totalLikes - 1;
    });

    DocumentReference userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);

    await userRef.update({
      'likes': totalLikes,
      'isLiked': isLiked,
    });
  }

  void _logout() {
    Get.offAllNamed('/welcome');
  }

  void _incrementPlayCount(String gameName) async {
    DocumentReference userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);

    try {
      DocumentSnapshot docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'playcount': 1,
          'gamesPlayed': {gameName: 1}
        });
      } else {
        await userRef.update({
          'playcount': FieldValue.increment(1),
          'gamesPlayed.$gameName': FieldValue.increment(1),
        });
      }
    } catch (error) {
      print("Failed to update play count: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F51B5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              Column(
                children: [
                  // Welcome Text
                  Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.02),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB0BEC5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Welcome, ${widget.username}",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Game Grid
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0BEC5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: GridView.builder(
                        itemCount: imageList.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: screenWidth * 0.04,
                          mainAxisSpacing: screenHeight * 0.02,
                        ),
                        itemBuilder: (context, index) {
                          return CustomGridTile(
                            imageName: imageList[index],
                            onPressed: () async {
                              switch (index) {
                                  case 0:
                                     _incrementPlayCount('2048_game'); // Pass the game name as a string
                                    Get.to(() => const HomeScreen2048());
                                    break;
                                  case 1:
                                    _incrementPlayCount('AI_Tic_Tac_Toe_game'); // Pass the game name as a string
                                    Get.to(() => const AITicTacToeHomePage());
                                    break;
                                  case 2:
                                    Get.to(() => Piano());
                                    break;
                                  case 3:
                                   _incrementPlayCount('PacMan_game'); // Pass the game name as a string
                                    Get.to(() => const PacManHomePage());
                                    break;
                                  case 4:
                                    Get.to(() => const DianoserGame());
                                    break;
                                  case 5:
                                    _incrementPlayCount('MiniSweeper_game'); // Pass the game name as a string
                                    Get.to(() => MiniSweeperGame());
                                    break;
                               }
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom Image
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: Image.asset(
                      "assets/images/multi_game.png",
                      height: screenHeight * 0.08,
                      width: screenWidth * 0.6,
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),

              // Like & Logout Buttons
              Positioned(
                top: screenHeight * 0.14,
                right: screenWidth * 0.05,
                child: Row(
                  children: [
                    // Like Button
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleLike,
                    ),
                    SizedBox(width: 10),

                    // Logout Button
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
