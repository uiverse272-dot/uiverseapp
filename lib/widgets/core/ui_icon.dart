import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon set from `assets/icons/` (24 grid, stroke 1.8, round caps/joins — §7).
enum Ui {
  arrowLeft('arrow_left'),
  arrowRight('arrow_right'),
  bookmark('bookmark'),
  bookmarkFilled('bookmark_filled'),
  check('check'),
  chevron('chevron'),
  close('close'),
  code('code'),
  compass('compass'),
  copy('copy'),
  dots('dots'),
  external('external'),
  filter('filter'),
  grid('grid'),
  home('home'),
  layers('layers'),
  layout('layout'),
  monitor('monitor'),
  moon('moon'),
  palette('palette'),
  phone('phone'),
  plus('plus'),
  search('search'),
  sparkle('sparkle'),
  sun('sun'),
  upload('upload'),
  user('user');

  const Ui(this.file);
  final String file;
  String get asset => 'assets/icons/$file.svg';
}

/// Renders a [Ui] icon tinted with [color] (defaults to the ambient text colour).
class UiIcon extends StatelessWidget {
  const UiIcon(this.icon, {super.key, this.size = 16, this.color, this.semanticLabel, this.turns = 0});

  final Ui icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Rotation in full turns (0.5 = 180°, used for "expand" chevrons).
  final double turns;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? DefaultTextStyle.of(context).style.color ?? IconTheme.of(context).color!;
    Widget svg = SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
    if (turns != 0) svg = RotationTransition(turns: AlwaysStoppedAnimation(turns), child: svg);
    return svg;
  }
}
