import 'package:flutter/material.dart';

bool isNavBarVisible(BuildContext context) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  final viewInsets = MediaQuery.of(context).viewInsets.bottom;

  // Ignore keyboard
  if (viewInsets > 0) return false;

  // Gesture navigation gesture-handle inset is typically <= 34px.
  // 3-button navigation bar is >= 48px.
  return bottomInset >= 48; // threshold chosen from Android spec
}
