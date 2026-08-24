import 'package:flutter/material.dart';

abstract final class AppColors {
  // Executive scouting dossier: graphite, aged paper, sage and brass.
  // The role names below are the canonical design tokens. Legacy aliases are
  // kept because feature screens created before the design-system pass still
  // use them.
  static const midnight = Color(0xFF091419);
  static const navy = Color(0xFF101F25);
  static const panel = Color(0xFF162A31);
  static const panelAlt = Color(0xFF13262C);
  static const surfaceHigh = Color(0xFF1B323A);
  static const slate = Color(0xFF294049);
  static const divider = Color(0xFF20353D);

  static const teal = Color(0xFF79A88F);
  static const amber = Color(0xFFD1A85A);
  static const ratingBlue = Color(0xFF6D98BE);
  static const paper = Color(0xFFF0F2EC);
  static const ink = Color(0xFF102027);
  static const muted = Color(0xFFA6B2B0);
  // Light enough to retain WCAG AA contrast on every raised dark surface.
  static const danger = Color(0xFFE17874);

  static const canvas = midnight;
  static const surface = navy;
  static const surfaceRaised = panel;
  static const surfaceMuted = panelAlt;
  static const surfaceInteractive = surfaceHigh;
  static const borderSubtle = divider;
  static const borderStrong = slate;
  static const primary = teal;
  static const secondary = amber;
  static const textPrimary = paper;
  static const textSecondary = muted;
  static const success = teal;
  static const warning = amber;
  static const info = ratingBlue;
  static const negative = danger;
  static const disabled = slate;
  static const scrim = Color(0xB3091419);
  static const shadow = Color(0x66000000);

  static const successSurface = Color(0xFF172D27);
  static const warningSurface = Color(0xFF312B1D);
  static const dangerSurface = Color(0xFF332326);

  static const transferWindowPanel = Color(0xFF352426);
  static const transferWindowBorder = Color(0xFF694143);
}
