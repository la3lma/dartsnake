import 'dart:html';

import 'coord.dart';


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


class GridRenderer3D extends GridRenderer {
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