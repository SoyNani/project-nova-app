import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/calendar_month.dart';

/// Colores de las ciudades en el calendario: las dos ciudades con más
/// conferencias del mes tienen color propio y el resto comparte el
/// tercero ("Girón / otras").
abstract final class CalendarCityPalette {
  static const List<Color> _colors = [
    AppColors.primaryLight,
    AppColors.institutionsColor,
    AppColors.speakersColor,
  ];

  static Color colorAt(int cityIndex) {
    if (cityIndex < 0) return AppColors.textMuted;
    return _colors[cityIndex.clamp(0, _colors.length - 1)];
  }

  static Color colorOf(CalendarMonth month, String city) =>
      colorAt(month.cityIndexOf(city));

  static List<(Color, String)> legendOf(CalendarMonth month) {
    final cities = month.cities;
    return [
      for (var i = 0; i < cities.length && i < _colors.length; i++)
        (
          _colors[i],
          i == _colors.length - 1 && cities.length > _colors.length
              ? '${cities[i]} / otras'
              : cities[i],
        ),
    ];
  }
}
