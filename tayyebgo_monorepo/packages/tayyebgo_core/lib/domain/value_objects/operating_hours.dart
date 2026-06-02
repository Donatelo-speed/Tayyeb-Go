class OperatingHours {
  final int dayOfWeek;
  final int openMinutes;
  final int closeMinutes;
  final bool isClosed;

  const OperatingHours({
    required this.dayOfWeek,
    required this.openMinutes,
    required this.closeMinutes,
    this.isClosed = false,
  });

  bool get isOpenNow {
    if (isClosed) return false;
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    if (closeMinutes < openMinutes) {
      return minutesSinceMidnight >= openMinutes ||
          minutesSinceMidnight <= closeMinutes;
    }
    return minutesSinceMidnight >= openMinutes &&
        minutesSinceMidnight <= closeMinutes;
  }

  bool matchesDay(DateTime date) {
    final idx = date.weekday;
    return dayOfWeek == idx;
  }

  String openTimeDisplay() {
    final h = openMinutes ~/ 60;
    final m = openMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String closeTimeDisplay() {
    final h = closeMinutes ~/ 60;
    final m = closeMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'openMinutes': openMinutes,
        'closeMinutes': closeMinutes,
        'isClosed': isClosed,
      };

  factory OperatingHours.fromMap(Map<String, dynamic> m) => OperatingHours(
        dayOfWeek: (m['dayOfWeek'] as num?)?.toInt() ?? 1,
        openMinutes: (m['openMinutes'] as num?)?.toInt() ?? 0,
        closeMinutes: (m['closeMinutes'] as num?)?.toInt() ?? 0,
        isClosed: m['isClosed'] as bool? ?? false,
      );
}