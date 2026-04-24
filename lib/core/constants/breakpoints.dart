// lib/core/constants/breakpoints.dart

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1024;
}

int gridColumns(double width) {
  if (width < 400) return 1;
  if (width < 600) return 2;
  if (width < 900) return 3;
  return 4;
}
