import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../widgets/speaker_form.dart';

class SpeakerFormScreen extends StatelessWidget {
  const SpeakerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Nuevo speaker'),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: SpeakerForm(
                onSaved: (_) => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
