import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/build_calendar_month.dart';

final buildCalendarMonthProvider = Provider<BuildCalendarMonth>((ref) {
  return const BuildCalendarMonth();
});
