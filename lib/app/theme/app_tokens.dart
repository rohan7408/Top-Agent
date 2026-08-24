import 'package:flutter/material.dart';

/// Shared measurements for the compact, data-first agency interface.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const content = 13.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

abstract final class AppRadii {
  static const xs = 2.0;
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 8.0;

  static const small = BorderRadius.all(Radius.circular(sm));
  static const medium = BorderRadius.all(Radius.circular(md));
  static const large = BorderRadius.all(Radius.circular(lg));
}

abstract final class AppBorders {
  static const hairline = 1.0;
  static const emphasis = 2.0;
}

abstract final class AppSizes {
  static const minTouchTarget = 44.0;
  static const compactTableHeader = 30.0;
  static const compactSectionBar = 30.0;
  static const compactInfoRow = 34.0;
  static const compactListRow = 59.0;
  static const positionBadge = 31.0;
  static const statusHeader = 80.0;
  static const navigationBar = 62.0;
  static const navigationShell = 76.0;
  static const nextWeekButton = 68.0;
}

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 180);
}

abstract final class AppType {
  static const bodyFamily = 'sans-serif';
  static const displayFamily = 'sans-serif-condensed';
  static const dataFamily = 'monospace';
}
