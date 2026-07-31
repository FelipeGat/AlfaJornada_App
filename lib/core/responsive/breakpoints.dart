import 'package:flutter/widgets.dart';

const double kBreakpointMedium = 600;
const double kBreakpointExpanded = 840;

enum WindowSize { compact, medium, expanded }

WindowSize windowSizeFromWidth(double width) {
  if (width >= kBreakpointExpanded) return WindowSize.expanded;
  if (width >= kBreakpointMedium) return WindowSize.medium;
  return WindowSize.compact;
}

extension WindowSizeX on BuildContext {
  WindowSize get windowSize =>
      windowSizeFromWidth(MediaQuery.sizeOf(this).width);

  bool get isTabletWidth => windowSize != WindowSize.compact;

  bool get isExpandedWidth => windowSize == WindowSize.expanded;
}

int responsiveCrossAxisCount(
  BuildContext context, {
  required int compact,
  required int medium,
  required int expanded,
}) {
  switch (context.windowSize) {
    case WindowSize.compact:
      return compact;
    case WindowSize.medium:
      return medium;
    case WindowSize.expanded:
      return expanded;
  }
}
