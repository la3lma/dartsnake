import 'dart:html';
import 'dart:math';
import 'package:game_loop/game_loop_html.dart';

GameLoopHtml gameLoop;
CanvasRenderingContext2D canvas;

const int WIDTH = 640;
const int HEIGHT = 480;
const num width = 10;
const num height = 10;
num initialPauseInMillis = 400;
num pauseInMillis = initialPauseInMillis;
num tailIncreaseInterval = 5000;


String gold_color = "#FFD700";
String white_color = "#FFFFFF";

void renderSquare(final Coord c, final String color) {
   canvas.fillStyle = color;
   canvas.fillRect(width * c.getX(), height * c.getY(), width, height);
}

class Gold {
  Coord location;
  Snake snake;
  num points = 5;

  Gold(final Snake s) {
    this.snake = s;
    setNewLocation();
  }

  Coord getLocation() {
    return location;
  }


  Coord newRandomCoordNotOnSnake() {
    Coord newLoc;
    do {
      newLoc = snake.newRandomCoord();
    } while (snake.containsCoord(newLoc));
    return newLoc;
  }

  /**
     * Set the location to a random point within the
     * canvas, but not anywhere on the snake.
     */
  void setNewLocation() {
    location = newRandomCoordNotOnSnake();
  }

  void gameAction() {
    if (location.equals(snake.head())) {
      snake.addPoints(points + snake.length());
      setNewLocation();
    }
  }
}

/**
 * An immutable 2D coordinate.
 */
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


  bool equals(Coord other) {
    return ((other.x == x) && (other.y == y));
  }

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  /**
   * Assume a square width with x and height y, check if
   * if the Coord c is inside (including border) of that
   * square.
   */
  bool isInside(Coord c) {
    return (c.x >= 0 && c.y >= 0 && c.x <= x && c.y <= y);
  }
}

class Snake {
  int maxSize = 3;
  List<Coord> coords = new List();

  Coord pen;

  int points = 5;

  Random rnd  = new Random();

  bool running = true;

  Snake(int w, int h) {

    pen = new Coord(w,h);

    coords.add(newRandomCoord());
    assert(coords.length == 1);
  }

  Coord newRandomCoord() {
    return new Coord(rnd.nextInt(width), rnd.nextInt(height));
  }

  void addPoints(num delta) {
    points += delta;
  }


  void showPoints() {
    var pts = querySelector("#points");
    pts.text = "Points: ${points}";
  }

  List<Coord> getCoords() {
    return coords;
  }

  // Detect if we're outside the playing board.
  bool isInsidePen(Coord coord) {
    return pen.isInside(coord);
  }


  void stopGame() {
    running = false;
  }

  bool isRunning() {
    return running;
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

    newHead.add(direction);

    if (!isInsidePen(newHead)) {
      collisionWithCanvas();
      return;
    }

    if (containsCoord(newHead)) {
      collisionWithTail();
      return;
    }

    // If we're not at max length, then grow length
    if (coords.length == maxSize) {
      coords.removeAt(0);
    }
    coords.add(newHead);

    assert(coords.length >= oldLength);
  }

  void increaseTail() {
    maxSize += 1;
  }
}


class SnakeState extends GameLoopHtmlState {
  String name;
  Snake snake;
  int speed;
  int tailClock;
  int increaseSpeed;

  Random rand = new Random();

  static Coord right = new Coord(1, 0);
  static Coord left = new Coord(-1, 0);
  static Coord up = new Coord(0, -1);
  static Coord down = new Coord(0, 1);

  Coord direction;

  Gold gold;

  SnakeState(String n) {
    this.name = n;

    this.direction = randomDirection();
    int cwidth = canvas.canvas.width;
    int cheight = canvas.canvas.height;

    int cowidth = (cwidth / width).round();
    int coheight = (cheight / width).round();

    this.snake = new Snake(cowidth, coheight);

    // Clear canvas
    var gc = canvas.canvas.getContext('2d');
    canvas.fillStyle = white_color;
    canvas.fillRect(0, 0, cwidth, cheight);

    this.gold = new Gold(this.snake);
    this.speed = 10;
    this.tailClock = 100;
    this.increaseSpeed = tailClock * tailClock;
  }


  Coord randomDirection() {
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

  Coord getDirectionFromKeyboardEvent(KeyboardEvent e) {
    final int keyCode = e.keyCode;
    switch (keyCode) {
      case 39:
        return right;
      case 37:
        return left;
      case 38:
        return up;
      case 40:
        return down;
      default:
        return null;
    }
  }

  Gold getGold() {
    return gold;
  }

  bool tailTurnFilter(Coord c, Coord dir) {
    return ((c == up && dir != down) || (c == down && dir != up) || (c == left
        && dir != right) || (c == right && dir != left));
  }

  onKeyDown(KeyboardEvent event) {
    event.preventDefault();
    Coord d = getDirectionFromKeyboardEvent(event);
    if (d != null && tailTurnFilter(d, direction)) {
      direction = d;
    }
  }

  onRender(GameLoopHtml gameLoop) {

    canvas.clearRect(0, 0, WIDTH, HEIGHT);
    canvas.fillStyle = "rgb(255,165,0)";
    canvas.fillRect(0, 0, WIDTH, HEIGHT);
    canvas.font = "italic bold 24px sans-serif";
    canvas.strokeText("Inside snake pen", 0, 100);

    canvas.fillRect(0, 0, 20, 20);
    renderSquare(gold.getLocation(), gold_color);

    snake.getCoords().forEach((c) => renderSquare(c, white_color));
    snake.showPoints();
  }


  void onFullScreenChange(GameLoop gameLoop) {
    // IGNORED
  }

  void onPointerLockChange(GameLoop gameLoop) {
    // IGNORED
  }

  void onResize(GameLoop gameLoop) {
    // IGNORED
  }

  void onTouchEnd(GameLoop gameLoop, GameLoopTouch touch) {
    // IGNORED
  }

  void onTouchStart(GameLoop gameLoop, GameLoopTouch touch) {
    // IGNORED
  }

  void onUpdate(GameLoop gameLoop) {
    if (!snake.isRunning()) {
      gameLoop.stop();
      return;
    }

    if ((gameLoop.frame % speed) == 0) {
      snake.move(direction);
      gold.gameAction();
    }

    if ((gameLoop.frame % tailClock) == 0) {
      snake.increaseTail();
    }

    if ((gameLoop.frame % increaseSpeed) == 0) {
      if (speed > 0) {
        speed -= 1;
      }
    }
  }
}


void newGame() {
  CanvasElement element = querySelector(".game-element");
  gameLoop = new GameLoopHtml(element);
  canvas = element.context2D;

  gameLoop.state = new SnakeState("snake");
  gameLoop.start();
}

ButtonElement newGameButton;

main() {
  newGameButton = querySelector('#newGame');
  newGameButton.onClick.listen((e) => newGame());
  newGame();
}
