import 'package:mapsforge_flutter/core.dart';

import '../graphics/position.dart';
import '../mapelements/pointtextcontainer.dart';
import '../mapelements/symbolcontainer.dart';
import '../model/mappoint.dart';
import 'color.dart';
import 'display.dart';
import 'mapcanvas.dart';
import 'mappaint.dart';
import 'mappath.dart';
import 'maprect.dart';
import 'matrix.dart';

abstract class GraphicFactory {
  final SymbolCache symbolCache;

  GraphicFactory(this.symbolCache) : assert(symbolCache != null);

  void dispose() {
    symbolCache.dispose();
  }

  //Bitmap createBitmap(int width, int height, bool isTransparent);

  MapCanvas createCanvas(double width, double height, [String src]);

  int createColor(Color color);

  int createColorSeparate(int alpha, int red, int green, int blue);

  Matrix createMatrix();

  /**
   * Create a single channel bitmap for hillshading, may include a buffer.
   */
//  HillshadingBitmap createMonoBitmap(int width, int height, Uint8List buffer, int padding, BoundingBox area);

  //Paint createPaint();

  MapPaint createPaint();

  MapPaint createPaintFrom(MapPaint from);

  MapPath createPath();

  MapRect createRect(double left, double top, double right, double bottom);

  PointTextContainer createPointTextContainer(Mappoint xy, Display display, int priority, String text, MapPaint paintFront,
      MapPaint paintBack, SymbolContainer symbolContainer, Position position, int maxTextWidth);

//  ResourceBitmap createResourceBitmap(InputStream inputStream, double scaleFactor, int width, int height, int percent);

// TileBitmap createTileBitmap(double tileSize, bool isTransparent, {InputStream inputStream});
//
// InputStream platformSpecificSources(String relativePathPrefix, String src);
//
// ResourceBitmap renderSvg(InputStream inputStream, double scaleFactor, int width, int height, int percent);
}
