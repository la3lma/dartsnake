import 'dart:html';
import 'dart:math';
import 'package:game_loop/game_loop_html.dart';

GameLoopHtml gameLoop;


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

  Random rnd = new Random();

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

  Coord randomCoordInside() {
    return new Coord(rnd.nextInt(getX()), rnd.nextInt(getY()));
  }

  Coord operator /(Coord c) {
      return new Coord(
          (x / c.x).round(),
          (y / c.y).round());
  }
}

class Snake {
  int maxSize = 3;
  List<Coord> coords = new List();

  Coord snakepen;

  int points = 5;

  bool running = true;

  Snake(Coord grid) {

    snakepen = grid;

    coords.add(newRandomCoord());
    assert(coords.length == 1);
  }

  Coord newRandomCoord() {
    return snakepen.randomCoordInside();
  }

  void addPoints(num delta) {
    points += delta;
  }

  int getPoints() {
    return points;
  }

  List<Coord> getCoords() {
    return coords;
  }

  /**
   * Detect if we're outside the playing board.
   */
  bool isInsidePen(Coord coord) {
    return snakepen.isInside(coord);
  }

  void stopGame() {
    running = false;
  }

  bool isRunning() {
    return running;
  }

  void collisionWithTail() {
    stopGame();
  }

  void collisionWithCanvas() {
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

abstract class GridRenderer {
  CanvasRenderingContext2D canvas;

  void renderGridBlock(final Coord c, final String color);

  void fillCanvas(String color);
}

class GridRenderer2D extends GridRenderer {
  CanvasRenderingContext2D canvas;

  static Coord snakePenSizeInPixels = new Coord(640, 480);
  static Coord gridBlockSizeInPixels = new Coord(10, 10);

  GridRenderer2D(CanvasRenderingContext2D c) {
    this.canvas = c;
  }


  void renderGridBlock(final Coord c, final String color) {
    canvas.fillStyle = color;
    canvas.fillRect(gridBlockSizeInPixels.getX() * c.getX(),
        gridBlockSizeInPixels.getY() * c.getY(), gridBlockSizeInPixels.getX(),
        gridBlockSizeInPixels.getY());
  }

  void fillCanvas(String color) {
    canvas.fillStyle = color;
    canvas.fillRect(0, 0, snakePenSizeInPixels.getX(),
    snakePenSizeInPixels.getY());
  }
}

class SnakeState extends GameLoopHtmlState {

  GridRenderer renderer;

  CanvasRenderingContext2D canvas;

  static Coord snakePenSizeInPixels = new Coord(640, 480);
  static Coord gridBlockSizeInPixels = new Coord(10, 10);

  num initialPauseInMillis = 400;
  num pauseInMillis;
  num tailIncreaseInterval = 5000;

  String gold_color = "#FFD700";
  String white_color = "#FFFFFF";
  String background_color = "rgb(255,165,0)";

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

  SnakeState(String n, CanvasRenderingContext2D c) {
    this.name = n;
    this.canvas = c;

    renderer = new GridRenderer2D(c);

    this.pauseInMillis = initialPauseInMillis;

    this.direction = randomDirection();
    Coord canvasSize = new Coord(
                        canvas.canvas.width,
                        canvas.canvas.height);

    // How many grid blocks will fit into a canvas?
    // Get answer as a coordinate giving number in
    // horizontal and vertical dimensions through
    // operator overloading.
    Coord grid = canvasSize / gridBlockSizeInPixels ;

    this.snake = new Snake(grid);

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

  /**
   * Reversing direction into the tail is a very easy, but also
   * very annoying way for a snake to die, so we avoid that.
   */
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

    renderer.fillCanvas(background_color);
    renderer.renderGridBlock(gold.getLocation(), gold_color);
    snake.getCoords().forEach((c) => renderer.renderGridBlock(c, white_color));


    var pts = querySelector("#points");
    pts.text = "Points: ${snake.getPoints()}";
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
  gameLoop.state = new SnakeState("snake", element.context2D);
  gameLoop.start();
}

ButtonElement newGameButton;

main() {
  newGameButton = querySelector('#newGame');
  newGameButton.onClick.listen((e) => newGame());
  newGame();
}
