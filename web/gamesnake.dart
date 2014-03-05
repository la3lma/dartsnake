import 'dart:html';
import 'dart:math';
import 'package:game_loop/game_loop_html.dart';
import 'coord.dart';
import 'renderers.dart';

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



class SnakeState extends GameLoopHtmlState {

  GridRenderer renderer;

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

    renderer = new GridRenderer2D(c);

    this.pauseInMillis = initialPauseInMillis;

    this.direction = randomDirection();
    Coord canvasSize = new Coord(
                        c.canvas.width,
                        c.canvas.height);

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
