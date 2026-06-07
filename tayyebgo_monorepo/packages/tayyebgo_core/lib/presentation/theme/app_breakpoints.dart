abstract class AppBreakpoints {
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1280;
  static const double wide = 1440;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet && width < wide;
  static bool isWide(double width) => width >= wide;
}
