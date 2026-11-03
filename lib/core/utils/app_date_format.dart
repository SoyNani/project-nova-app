class AppDateFormat {
  AppDateFormat._();

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

  static const _weekdaysLong = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static String time(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hour12:$minutes ${_period(date)}';
  }

  static String timeRange(DateTime start, DateTime end) {
    if (_period(start) == _period(end)) {
      final startText = time(start);
      return '${startText.substring(0, startText.length - 3)} – ${time(end)}';
    }
    return '${time(start)} – ${time(end)}';
  }

  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  static String monthShort(DateTime date) =>
      _months[date.month - 1].toUpperCase();

  static String monthName(DateTime date) {
    final name = _monthsLong[date.month - 1];
    return name[0].toUpperCase() + name.substring(1);
  }

  static String monthNameLower(DateTime date) => _monthsLong[date.month - 1];

  static String dayMonthYear(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String longDate(DateTime date) =>
      '${_weekdaysLong[date.weekday - 1]} ${date.day} de '
      '${_monthsLong[date.month - 1]}';

  static String relativeDay(DateTime date, DateTime now) {
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    return longDate(date);
  }

  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  static String _period(DateTime date) => date.hour < 12 ? 'AM' : 'PM';
}
