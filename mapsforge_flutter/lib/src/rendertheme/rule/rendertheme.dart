import 'package:mapsforge_flutter/src/rendertheme/xml/renderthemebuilder.dart';

import '../../datastore/pointofinterest.dart';
import '../../renderer/polylinecontainer.dart';
import '../../renderer/standardrenderer.dart';
import '../../rendertheme/renderinstruction/hillshading.dart';
import '../../rendertheme/renderinstruction/renderinstruction.dart';
import '../../rendertheme/rule/rule.dart';
import '../rendercallback.dart';
import '../rendercontext.dart';
import 'closed.dart';
import 'matchingcachekey.dart';
import 'negativerule.dart';

/**
 * A RenderTheme defines how ways and nodes are drawn.
 */
class RenderTheme {
  static final int MATCHING_CACHE_SIZE = 1024;

  final double baseStrokeWidth;
  final double baseTextSize;
  final bool hasBackgroundOutside;
  int levels;
  final int mapBackground;
  final int mapBackgroundOutside;
  Map<MatchingCacheKey, List<RenderInstruction>> wayMatchingCache;
  Map<MatchingCacheKey, List<RenderInstruction>> poiMatchingCache;
  final List<Rule> rulesList; // NOPMD we need specific interface
  List<Hillshading> hillShadings = new List(); // NOPMD specific interface for trimToSize

  final Map<int, double> strokeScales = new Map();
  final Map<int, double> textScales = new Map();

  RenderTheme(RenderThemeBuilder renderThemeBuilder)
      : baseStrokeWidth = renderThemeBuilder.baseStrokeWidth,
        baseTextSize = renderThemeBuilder.baseTextSize,
        hasBackgroundOutside = renderThemeBuilder.hasBackgroundOutside,
        mapBackground = renderThemeBuilder.mapBackground,
        mapBackgroundOutside = renderThemeBuilder.mapBackgroundOutside,
        rulesList = new List() {
    this.poiMatchingCache = new Map();
    this.wayMatchingCache = new Map();
  }

  /**
   * Must be called when this RenderTheme gets destroyed to clean up and free resources.
   */
  void destroy() {
    this.poiMatchingCache.clear();
    this.wayMatchingCache.clear();
    for (Rule r in this.rulesList) {
      r.destroy();
    }
  }

  /**
   * @return the number of distinct drawing levels required by this RenderTheme.
   */
  int getLevels() {
    return this.levels;
  }

  /**
   * @return the map background color of this RenderTheme.
   */
  int getMapBackground() {
    return this.mapBackground;
  }

  /**
   * @return the background color that applies to areas outside the map.
   */
  int getMapBackgroundOutside() {
    return this.mapBackgroundOutside;
  }

  /**
   * @return true if map color is defined for outside areas.
   */
  bool hasMapBackgroundOutside() {
    return this.hasBackgroundOutside;
  }

  /**
   * Matches a closed way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  Future matchClosedWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) async {
    matchWay(renderCallback, renderContext, Closed.YES, way);
  }

  /**
   * Matches a linear way with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param way
   */
  void matchLinearWay(RenderCallback renderCallback, final RenderContext renderContext, PolylineContainer way) {
    matchWay(renderCallback, renderContext, Closed.NO, way);
  }

  /**
   * Matches a node with the given parameters against this RenderTheme.
   *
   * @param renderCallback the callback implementation which will be executed on each match.
   * @param renderContext
   * @param poi            the point of interest.
   */
  void matchNode(RenderCallback renderCallback, final RenderContext renderContext, PointOfInterest poi) {
    MatchingCacheKey matchingCacheKey = new MatchingCacheKey(poi.tags, renderContext.job.tile.zoomLevel, Closed.NO);

    List<RenderInstruction> matchingList = this.poiMatchingCache[matchingCacheKey];
    if (matchingList != null) {
      // cache hit
      for (int i = 0, n = matchingList.length; i < n; ++i) {
        matchingList.elementAt(i).renderNode(renderCallback, renderContext, poi);
      }
      return;
    }

    // cache miss
    matchingList = new List<RenderInstruction>();

    for (int i = 0, n = this.rulesList.length; i < n; ++i) {
      this.rulesList.elementAt(i).matchNode(renderCallback, renderContext, matchingList, poi);
    }
    this.poiMatchingCache[matchingCacheKey] = matchingList;
  }

  /**
   * Scales the stroke width of this RenderTheme by the given factor for a given zoom level
   *
   * @param scaleFactor the factor by which the stroke width should be scaled.
   * @param zoomLevel   the zoom level to which this is applied.
   */
  void scaleStrokeWidth(double scaleFactor, int zoomLevel) {
    if (!strokeScales.containsKey(zoomLevel) || scaleFactor != strokeScales[zoomLevel]) {
      for (int i = 0, n = this.rulesList.length; i < n; ++i) {
        Rule rule = this.rulesList.elementAt(i);
        if (rule.zoomMin <= zoomLevel && rule.zoomMax >= zoomLevel) {
          rule.scaleStrokeWidth(scaleFactor * this.baseStrokeWidth, zoomLevel);
        }
      }
      strokeScales[zoomLevel] = scaleFactor;
    }
  }

  /**
   * Scales the text size of this RenderTheme by the given factor for a given zoom level.
   *
   * @param scaleFactor the factor by which the text size should be scaled.
   * @param zoomLevel   the zoom level to which this is applied.
   */
  void scaleTextSize(double scaleFactor, int zoomLevel) {
    if (!textScales.containsKey(zoomLevel) || scaleFactor != textScales[zoomLevel]) {
      for (int i = 0, n = this.rulesList.length; i < n; ++i) {
        Rule rule = this.rulesList.elementAt(i);
        if (rule.zoomMin <= zoomLevel && rule.zoomMax >= zoomLevel) {
          rule.scaleTextSize(scaleFactor * this.baseTextSize, zoomLevel);
        }
      }
      textScales[zoomLevel] = scaleFactor;
    }
  }

  void addRule(Rule rule) {
    this.rulesList.add(rule);
  }

  void addHillShadings(Hillshading hillshading) {
    this.hillShadings.add(hillshading);
  }

  void complete() {
//    this.rulesList.trimToSize();
//    this.hillShadings.trimToSize();
    for (int i = 0, n = this.rulesList.length; i < n; ++i) {
      this.rulesList.elementAt(i).onComplete();
    }
  }

  void setLevels(int levels) {
    this.levels = levels;
  }

  void matchWay(RenderCallback renderCallback, final RenderContext renderContext, Closed closed, PolylineContainer way) {
    MatchingCacheKey matchingCacheKey = new MatchingCacheKey(way.getTags(), way.getUpperLeft().zoomLevel, closed);

    List<RenderInstruction> matchingList = this.wayMatchingCache[matchingCacheKey];
    if (matchingList != null) {
      // cache hit
      for (int i = 0, n = matchingList.length; i < n; ++i) {
        matchingList.elementAt(i).renderWay(renderCallback, renderContext, way);
      }
      return;
    }

    // cache miss
    matchingList = new List<RenderInstruction>();
    this.rulesList.forEach((rule) {
      //print("testing rule: " + rule.toString());
      rule.matchWay(renderCallback, way, way.getUpperLeft(), closed, matchingList, renderContext);
    });

    this.wayMatchingCache[matchingCacheKey] = matchingList;
  }

  void traverseRules(RuleVisitor visitor) {
    for (Rule rule in this.rulesList) {
      rule.apply(visitor);
    }
  }

  void matchHillShadings(StandardRenderer renderer, RenderContext renderContext) {
    for (Hillshading hillShading in hillShadings) hillShading.render(renderContext, renderer.hillsRenderConfig);
  }

  @override
  String toString() {
    return 'RenderTheme{baseStrokeWidth: $baseStrokeWidth, baseTextSize: $baseTextSize, hasBackgroundOutside: $hasBackgroundOutside, levels: $levels, mapBackground: $mapBackground, mapBackgroundOutside: $mapBackgroundOutside, wayMatchingCache: $wayMatchingCache, poiMatchingCache: $poiMatchingCache, rulesList: $rulesList, hillShadings: $hillShadings, strokeScales: $strokeScales, textScales: $textScales}';
  }
}