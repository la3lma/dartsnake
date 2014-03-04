import 'dart:html';
import 'package:game_loop/game_loop_html.dart';

GameLoopHtml gameLoop;
CanvasRenderingContext2D canvas;

const int WIDTH = 640;
const int HEIGHT = 480;

drawText(CanvasRenderingContext2D canvas, String text, String color) {
  canvas.clearRect(0, 0, WIDTH, HEIGHT);
  canvas.fillStyle = color;
  canvas.fillRect(0, 0, WIDTH, HEIGHT);
  canvas.font = "italic bold 24px sans-serif";
  canvas.strokeText(text, 0, 100);
}

// Create a simple state implementing only the handlers you care about
class InitialState extends SimpleHtmlState {
  void onRender(GameLoop gameLoop) {
    print("Render initial_state");
    drawText(canvas, "Initial State", "rgb(255,0,102)");
  }

  void onKeyDown(KeyboardEvent event) {
    event.preventDefault();

    print("Key event");
    print("Switching to $custom_state_1");
    print("Rendering with ${custom_state_1.onRender}}");
    gameLoop.state = custom_state_1;
  }
}
//
// To do this without creating a custom class, just pass your unique handler
// functions in to the `GameLoopHtmlState` constructor.
GameLoopHtmlState initial_state = new InitialState();

// Create a CustomState class with unique state properties


// const num x = 10;
// const num y = 10;
const num width = 10;
const num height = 10;
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


  bool equals(Coord other) {
    return ((other.x == x) && (other.y == y));
  }

  void render(CanvasRenderingContext2D crc) {
    crc.fillStyle = "#FFFFFF";
    crc.fillRect(width * x, height * y, width, height);
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

  bool running = true;

  Snake(CanvasRenderingContext2D crc) {
    coords.add(new Coord(10, 10));


    // XXX All of this will be invalid on canvas resize!
    cwidth = crc.canvas.width;
    cheight = crc.canvas.height;

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
    // final CanvasElement canvas = querySelector("#myCanvas");
    var gc = canvas.canvas.getContext('2d');
    gc.fillStyle = "#FFFFFF";
    gc.fillRect(0, 0, cwidth, cheight);
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
    } else {
      print("Growing tail");
    }
    print("Tail length = ${coords.length}");
    coords.add(newHead);

    assert(coords.length >= oldLength);
  }

  void render(canvas) {
    coords.forEach((c) => c.render(canvas));
  }
}

// Subclassing GameLoopState allows you to organise the state of your game
// without poluting the global state.
class SnakeState extends GameLoopHtmlState {
  String name;
  Snake snake;
  int speed;

  static Coord right = new Coord(1, 0);
  static Coord left = new Coord(-1, 0);
  static Coord up = new Coord(0, -1);
  static Coord down = new Coord(0, 1);

  Coord direction = right;

  SnakeState(String n) {
    this.name = n;
    // XXX Should not be necessary (and is a bogus coupling in any case)
    this.snake = new Snake(canvas);
    this.speed = 10;
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

  bool tailTurnFilter(Coord c, Coord dir) {
    return ((c == up && dir != down) ||
            (c == down && dir != up) ||
            (c == left && dir != right) ||
            (c == right && dir != left));
  }

  onKeyDown(KeyboardEvent event) {
    event.preventDefault();
    print("Key event");
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
    snake.render(canvas);
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
      print("Stopping game");
      gameLoop.stop();
    }

    if ((gameLoop.frame % speed) == 0) {
      snake.move(direction);
    }
  }
}


// Subclassing GameLoopState allows you to organise the state of your game
// without poluting the global state.
class CustomState extends GameLoopHtmlState {
  String name;
  GameLoopHtmlState nextState;

  CustomState(this.name, this.nextState);

  onKeyDown(KeyboardEvent event) {
    event.preventDefault();

    print("Key event");
    gameLoop.state = nextState;
  }

  onRender(GameLoopHtml gameLoop) {
    print("Render $name");
    drawText(canvas, name, "rgb(255,165,0)");

    _renderSquare();
  }

  _renderSquare() {
    canvas.fillRect(0, 0, 20, 20);
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
    // IGNORED
  }
}

CustomState custom_state_1 = new CustomState("Custom State 1", custom_state_2);
CustomState custom_state_2 = new CustomState("Custom State 2", menu_state);

class CanvasMenuState extends MenuState {

  CanvasRenderingContext2D canvas;

  CanvasMenuState(this.canvas, options, [selected = 0]): super(options, selected
      );

  void onRender(GameLoop gameLoop) {
    print("Rendering Menu");
    drawText(canvas, options[selected].text, "rgb(127,255,212)");
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
    // IGNORED
  }
}

CanvasMenuState menu_state = new CanvasMenuState(canvas, [new MenuOption(
    "Start", () {
    gameLoop.state = initial_state;
  }), new MenuOption("Quit", () {
    gameLoop.state = quit_state;
  })]);

class QuitState extends SimpleHtmlState {
  void onRender(GameLoopHtml gameLoop) {
    drawText(canvas, "QUIT!!", "rgb(0,255,127)");
  }

  void onKeyDown(KeyboardEvent event) {
    event.preventDefault();
  }
}
SimpleHtmlState quit_state = new QuitState();

main() {
  CanvasElement element = querySelector(".game-element");
  gameLoop = new GameLoopHtml(element);
  canvas = element.context2D;

  // gameLoop.state = initial_state;
  gameLoop.state = new SnakeState("snake");
  gameLoop.start();
}
