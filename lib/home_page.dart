import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/highscore.dart';
import 'package:snake_game/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SnakeDirection { UP, RIGHT, DOWN, LEFT }

class _HomePageState extends State<HomePage> {
  int totalNumberOfSquares = 100;
  int rowSize = 10;
  var currentDirection = SnakeDirection.RIGHT;
  int currentScore = 0;
  bool isStarted = false;
  TextEditingController _controller = TextEditingController();
  List<String> docIDs = [];
  late Future? letsgetDocIDs;

  List<int> snakePos = [
    0,
    1,
    2,
  ];
  int foodPos = 55;

  void startGame() {
    isStarted = true;
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        moveSnake();
        if (snakePos.last == foodPos) {
          eatFood();
        } else {
          snakePos.removeAt(0);
        }
        if (gameOver()) {
          timer.cancel();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Center(child: Text('Game Over')),
                content: Container(
                  height: 100,
                  child: Column(
                    children: [
                      Text('Score: ' + currentScore.toString()),
                      TextField(
                        controller: _controller,
                        decoration:
                            InputDecoration(hintText: 'Enter your username'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Center(
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        submitScore();
                        newGame();
                      },
                      child: Text('Submit'),
                      color: Colors.pink,
                    ),
                  )
                ],
              );
            },
          );
        }
      });
    });
  }

  void moveSnake() {
    switch (currentDirection) {
      case SnakeDirection.RIGHT:
        if (snakePos.last % rowSize == 9) {
          snakePos.add(snakePos.last + 1 - 10);
        } else {
          snakePos.add(snakePos.last + 1);
        }
      case SnakeDirection.LEFT:
        if (snakePos.last % rowSize == 0) {
          snakePos.add(snakePos.last + rowSize - 1);
        } else {
          snakePos.add(snakePos.last - 1);
        }
      case SnakeDirection.UP:
        if (snakePos.last < rowSize) {
          snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
        } else {
          snakePos.add(snakePos.last - rowSize);
        }
      case SnakeDirection.DOWN:
        if (snakePos.last > totalNumberOfSquares - rowSize) {
          snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
        } else {
          snakePos.add(snakePos.last + rowSize);
        }
    }
  }

  void eatFood() {
    currentScore++;
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  bool gameOver() {
    List<int> snakeBody = snakePos.sublist(0, snakePos.length - 1);
    return snakeBody.contains(snakePos.last);
  }

  void newGame() async {
    docIDs = [];
    await getDocIDs();
    setState(() {
      currentDirection = SnakeDirection.RIGHT;
      currentScore = 0;

      snakePos = [
        0,
        1,
        2,
      ];
      foodPos = 55;
      isStarted = false;
    });
  }

  void submitScore() {
    var database = FirebaseFirestore.instance;
    database
        .collection('tops')
        .add({'name': _controller.text.trim(), 'score': currentScore});
    _controller.clear();
  }

  @override
  void initState() {
    letsgetDocIDs = getDocIDs();
    super.initState();
  }

  Future getDocIDs() async {
    await FirebaseFirestore.instance
        .collection('tops')
        .orderBy('score', descending: true)
        .limit(5)
        .get()
        .then((snapshot) {
      snapshot.docs.forEach((document) {
        docIDs.add(document.reference.id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: screenWidth > 428 ? 428 : screenWidth,
        child: Column(
          children: [
            Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.only(top: 30, left: 90),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60.0),
                          child: Text(
                            'Score: ' + currentScore.toString(),
                            style: GoogleFonts.oswald(fontSize: 30),
                          ),
                        ),
                      ),
                      Expanded(
                          child: isStarted
                              ? Container()
                              : FutureBuilder(
                                  future: letsgetDocIDs,
                                  builder: (context, snapshot) {
                                    return ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: docIDs.length,
                                      itemBuilder: (context, index) {
                                        return Highscore(docID: docIDs[index]);
                                      },
                                    );
                                  },
                                ))
                    ],
                  ),
                )),
            Expanded(
                flex: 3,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0 &&
                        currentDirection != SnakeDirection.UP) {
                      currentDirection = SnakeDirection.DOWN;
                    } else if (details.delta.dy < 0 &&
                        currentDirection != SnakeDirection.DOWN) {
                      currentDirection = SnakeDirection.UP;
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 0 &&
                        currentDirection != SnakeDirection.LEFT) {
                      currentDirection = SnakeDirection.RIGHT;
                    } else if (details.delta.dx < 0 &&
                        currentDirection != SnakeDirection.RIGHT) {
                      currentDirection = SnakeDirection.LEFT;
                    }
                  },
                  child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: totalNumberOfSquares,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: rowSize),
                      itemBuilder: (context, index) {
                        if (snakePos.contains(index)) {
                          return SnakePixel();
                        } else if (foodPos == index) {
                          return FoodPixel();
                        } else {
                          return BlankPixel();
                        }
                      }),
                )),
            Expanded(
                flex: 1,
                child: Container(
                  child: Center(
                    child: MaterialButton(
                      color: !isStarted ? Colors.pink : Colors.grey,
                      onPressed: !isStarted ? startGame : () {},
                      child: Text('PLAY'),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
