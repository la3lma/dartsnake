import 'dart:math';


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