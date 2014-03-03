import 'dart:html';
import 'dart:async';
import 'dart:math';

// XXX This should be a class
//     it should also be on github.
//     Todo:  - Arrays with collision detection [check]
//            - Get the background color of the canvas to facilitate proper overwriting?
//                -- Naah, just figure out the coords of the backtround and paint it in the
//                   appropriate color.[Check]
//            - Detecting collisions on the walls.
//                o Determining what the coords of the walls are as a function of
//                  canvas size.[Check]
//            - Adding movement to the tail[Check]
//            - Add gold that can be converted into points [check].
//            - Showing the score.
//            - Crazy music.
//            - Psychedelic colors to keep the mind off balance.
//            - Doing it all in 3D (starting off in the plane, then
//               tilting the view into the plane, and rotating the plane
//               while the game is going on.

num x = 10;
num y = 10;
num width = 10;
num height = 10;
num initialPauseInMillis = 400;
num pauseInMillis = initialPauseInMillis;
num tailIncreaseInterval = 5000;


class Coord {
  String name;
  int x;
  int y;

  Coord(int x, int y) {
    this.x = x;
    this.y = y;
    name = "";
  }

  void add(Coord c) {
    x += c.x;
    y += c.y;
  }

  Coord copy() {
    return new Coord(x, y);
  }

  void paint(color) {
    print("Paointing $color");
    CanvasElement canvas = querySelector("#myCanvas");
    var gc = canvas.getContext('2d');
    gc.fillStyle = color;
    gc.fillRect(width * x, height * y, width, height);
  }


  void paintBlack() {
    paint("#000000");
  }


  void paintWhite() {
    paint("#FFFFFF");
  }

  bool equals(Coord other) {
    return ((other.x == x) && (other.y == y));
  }
}

class Snake {
  int maxSize = 3;
  List<Coord> coords = new List();

  int cwidth;
  int cheight;

  int cowidth;
  int coheight;

  int points = 5;

  Snake() {
    // XXX Layering violation
    CanvasElement canvas = querySelector("#myCanvas");
    coords.add(new Coord(10, 10));
    cwidth = canvas.width;
    cheight = canvas.height;

    cowidth = (cwidth / width).round();
    coheight = (cheight / width).round();
    clearCanvas();
    assert(coords.length == 1);
  }

  void addPoints(num delta) {
    points += delta;
  }

  void showData() {
    showPoints();
    showDirection();
  }

  void showPoints() {
    var pts = querySelector("#points");
    pts.text = "Points: ${points}";
  }

  void showDirection() {
    var pts = querySelector("#direction");
    pts.text = "Direction: ${direction.name}";
  }

  // Detect if we're outside the canvas.
  bool isOnCanvas(Coord coord) {
    return (coord.x >= 0 && coord.y >= 0 && coord.x <= cowidth && coord.y <=
        coheight);
  }

  void clearCanvas() {
    final CanvasElement canvas = querySelector("#myCanvas");
    var gc = canvas.getContext('2d');
    gc.fillStyle = "#FFFFFF";
    gc.fillRect(0, 0, cwidth, cheight);
  }

  void collisionWithTail() {
    print("Collision with tail detected.");
    stopGame();
  }


  void collisionWithCanvas() {
    print("Collision with canvas detected.");
    stopGame();
  }

  bool containsCoord(final Coord c) {
    for (int i = 0; i < coords.length - 1; i++) {
      final current = coords[i];
      if (current.equals(c)) {
        return true;
      }
    }
    return false;
  }

  Coord head() {
    return coords.elementAt(coords.length - 1);
  }

  num length() {
    return coords.length;
  }

  Coord tail() {
    return coords.elementAt(0);
  }
  void move(final Coord direction) {

    if (coords.length < 1) {
      return;
    }

    var oldLength = coords.length;

    // Calculate new candidate head and tail coords
    final Coord tailCoord = tail();
    assert(tailCoord != null);
    final Coord headCoord = head();
    assert(headCoord != null);

    final Coord newHead = headCoord.copy();
    assert(newHead != null);
    print("length = ${coords.length}");
    newHead.add(direction);

    print("head.x = ${newHead.x} head.y=${newHead.y}");
    if (!isOnCanvas(newHead)) {
      collisionWithCanvas();
      return;
    }

    if (containsCoord(newHead)) {
      collisionWithTail();
      return;
    }

    // If we're not at max length, then grow length
    if (coords.length == maxSize) {
      print("Maintaining  tail");
      coords.removeAt(0);
      /// Nuke tail.
      tailCoord.paintWhite();
    } else {
      print("Growing tail");
    }
    print("Tail length = ${coords.length}");
    coords.add(newHead);

    assert(coords.length >= oldLength);

    newHead.paintBlack();
  }
}

class Gold {
  Random rnd;
  Coord location;
  Snake snake;
  num points = 5;

  Gold(final Snake s) {
    snake = s;
    rnd = new Random();
    setNewLocation();
  }

  /**
     * Show the gold
     */
  void show() {
    location.paint("#FFD700");
  }

  /**
     * Set the location to a random point within the
     * canvas, but not anywhere on the snake.
     */
  void setNewLocation() {
    Coord newLoc;
    do {
      newLoc = new Coord(rnd.nextInt(snake.cowidth), rnd.nextInt(snake.coheight)
          );
    } while (snake.containsCoord(newLoc));
    location = newLoc;
    show();
  }

  void gameAction() {
    if (location.equals(snake.head())) {
      snake.addPoints(points + snake.length());
      setNewLocation();
    }
  }
}

Snake snake;
Gold gold;

Random rand = new Random(47);

void randomDirection() {
  int dir = rand.nextInt(4);
  switch (dir) {
    case 0:
        return left;
      case 1:
        return right;
      case 2:
        return up;
      default:
        return down;
  }
}

void randomizeDirection() {
  direction = randomDirection();
}


void newGame() {
  print("Starting new game");
  stopStreams();
  pauseInMillis = initialPauseInMillis;
  snake = new Snake();
  snake.clearCanvas();
  gold = new Gold(snake);
  randomizeDirection();

  startUpdates(pauseInMillis, tailIncreaseInterval);
  print("New game started");
}


ButtonElement newGameButton;
void main() {
  up.name = "up";
  down.name ="down";
  left.name ="left";
  right.name="right";

  newGameButton = querySelector('#newGame');
  newGameButton.onClick.listen((e) => newGame());
  window.onKeyDown.listen(handleKeyDown);
  newGame();
}


Stream stream;
Stream stream2;
Stream stream3;

// NOP
void stopGame() {
  stopStreams();
}

void stopStreams() {
  print("Stop scheduling");
}


void startUpdates(final int movementInterval, final int tailIncreaseInterval) {

  stream = new Stream.periodic(new Duration(milliseconds: movementInterval),
      movement);
  stream.listen((ignorethis) {}, cancelOnError: true);

  stream2 = new Stream.periodic(new Duration(milliseconds: tailIncreaseInterval
      ), increaseTailLength);
  stream2.listen((ignorethis) {}, cancelOnError: true);

  stream3 = new Stream.periodic(new Duration(milliseconds: movementInterval),
      showData);
  stream3.listen((ignorethis) {}, cancelOnError: true);
}

// XXX Badly named
void increaseTailLength(param) {
  snake.maxSize += 1;
  pauseInMillis = max(pauseInMillis - 2, 350);
  stream = new Stream.periodic(new Duration(milliseconds: pauseInMillis),
      movement);
  stream.listen((ignorethis) {}, cancelOnError: true);
}


void showData(param) {
  snake.showData();
}


void movement(param) {
  print("movement");
  snake.move(direction);
  gold.gameAction();
}


Coord right = new Coord(1, 0);
Coord left = new Coord(-1, 0);
Coord up = new Coord(0, -1);
Coord down = new Coord(0, 1);

Coord direction = right;

void handleKeyDown(e) {
  final int keyCode = e.keyCode;

  switch (keyCode) {
    case 39:
      if (direction != left) {
        direction = right;
      }
      break;
    case 37:
      if (direction != right) {
        direction = left;
      }
      break;
    case 38:
      if (direction != down) {
        direction = up;
      }
      break;
    case 40:
      if (direction != up) {
        direction = down;
      }
      break;
  }
}
