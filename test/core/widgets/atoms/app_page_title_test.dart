import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/core/theme/app_colors.dart';
import 'package:nova_app/core/theme/app_text_styles.dart';
import 'package:nova_app/core/widgets/atoms/app_page_title.dart';

void main() {
  testWidgets('usa el estilo del título de Conferencias', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppPageTitle('Perfil'))),
    );

    final text = tester.widget<Text>(find.text('Perfil'));

    expect(text.style?.fontSize, AppTextStyles.greeting.fontSize);
    expect(text.style?.fontWeight, AppTextStyles.greeting.fontWeight);
    expect(text.style?.color, AppColors.textPrimary);
  });
}
