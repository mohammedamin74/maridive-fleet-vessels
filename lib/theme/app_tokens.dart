import 'package:flutter/material.dart';

/// Spacing scale on a 4px base grid. Replaces the ad-hoc EdgeInsets/SizedBox
/// literals that grew screen-by-screen.
///
/// Legacy-value mapping when migrating old code:
///   4 → xxs, 6/8 → xs, 10/12 → sm, 14/16 → md, 20 → lg,
///   24 → xl, 28/32 → xxl, 48 → xxxl.
/// Micro values (2–9px) inside chips and badges may stay literal — tokens
/// set the layout rhythm, they don't redraw every badge.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard page gutter (the classic `EdgeInsets.fromLTRB(20, …)`).
  static const double gutter = lg;
}

/// Pre-built const gaps for the hundreds of `SizedBox(height/width: n)`
/// sites between siblings in Columns and Rows.
abstract final class Gaps {
  static const w4 = SizedBox(width: 4);
  static const w8 = SizedBox(width: 8);
  static const w12 = SizedBox(width: 12);
  static const w16 = SizedBox(width: 16);
  static const w20 = SizedBox(width: 20);
  static const h4 = SizedBox(height: 4);
  static const h8 = SizedBox(height: 8);
  static const h12 = SizedBox(height: 12);
  static const h16 = SizedBox(height: 16);
  static const h20 = SizedBox(height: 20);
  static const h24 = SizedBox(height: 24);
  static const h32 = SizedBox(height: 32);
}

/// Corner-radius scale. Legacy mapping: 10 → sm, 12/13 → md, 14/16 → lg,
/// 18/20 → xl; 20-radius pills → [pill] (or StadiumBorder).
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 18;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Adaptive breakpoints — hand-rolled Material 3 window size classes.
abstract final class AppBreakpoints {
  /// At or above: NavigationRail; below: NavigationBar.
  static const double medium = 600;

  /// At or above: multi-column dashboards, wider grids, taller hero photos.
  static const double expanded = 840;

  /// Readable-measure cap for scrolling content on very wide windows.
  static const double contentMaxWidth = 1080;

  /// Horizontal page padding that centers content at [contentMaxWidth] on
  /// wide viewports and falls back to the standard gutter otherwise.
  static EdgeInsetsDirectional pageGutter(double width) =>
      EdgeInsetsDirectional.symmetric(
        horizontal: width > contentMaxWidth + 2 * AppSpacing.gutter
            ? (width - contentMaxWidth) / 2
            : AppSpacing.gutter,
      );
}
