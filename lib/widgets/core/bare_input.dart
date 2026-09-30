import 'package:flutter/material.dart';

/// Undecorated text-field decoration for inputs drawn inside their own box.
///
/// `InputDecoration.collapsed` still inherits `filled` and the enabled/focused
/// borders from the theme's [InputDecorationThemeData], which paints a second
/// box inside the host; this switches all of that off.
InputDecoration bareInput({required String hintText, required TextStyle hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      filled: false,
      hintText: hintText,
      hintStyle: hintStyle,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
