import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/atoms/app_outline_button.dart';
import '../../../../core/widgets/atoms/app_page_title.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';
import '../../../speakers/domain/entities/speaker_entity.dart';
import '../../../speakers/presentation/providers/speaker_providers.dart';
import '../../../speakers/presentation/widgets/speaker_form.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppPageTitle('Perfil'),
                  const SizedBox(height: 18),
                  _ProfileHeader(user: user),
                  const SizedBox(height: 28),
                  _SpeakerProfileSection(email: user.email),
                  const AppSectionHeader(title: 'CUENTA'),
                  const SizedBox(height: 16),
                  AppOutlineButton(
                    label: 'Cerrar sesión',
                    borderColor: AppColors.error,
                    textColor: AppColors.error,
                    leading: const Icon(
                      Icons.logout,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => ref.read(signOutProvider)(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.heroGradient,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(user.displayName),
            style: AppTextStyles.cardTitle.copyWith(
              color: AppColors.onPrimary,
              fontSize: 30,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle,
        ),
        if (user.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words.first.characters.first + words.last.characters.first)
        .toUpperCase();
  }
}

class _SpeakerProfileSection extends ConsumerStatefulWidget {
  const _SpeakerProfileSection({required this.email});

  final String email;

  @override
  ConsumerState<_SpeakerProfileSection> createState() =>
      _SpeakerProfileSectionState();
}

class _SpeakerProfileSectionState
    extends ConsumerState<_SpeakerProfileSection> {
  SpeakerEntity? _formSpeaker;

  SpeakerEntity _pin(SpeakerEntity speaker) {
    if (_formSpeaker?.id != speaker.id) _formSpeaker = speaker;
    return _formSpeaker!;
  }

  @override
  Widget build(BuildContext context) {
    final speakerAsync = ref.watch(speakerByEmailProvider(widget.email));

    return speakerAsync.when(
      data: (found) {
        if (found == null) {
          _formSpeaker = null;
          return const SizedBox.shrink();
        }
        final speaker = _pin(found);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil de speaker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hay un speaker registrado con tu correo. Puedes actualizar '
              'sus datos aquí.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SpeakerForm(
              key: ValueKey(speaker.id),
              speaker: speaker,
              onSaved: (_) => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Perfil de speaker actualizado.'),
                    backgroundColor: AppColors.success,
                  ),
                ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 28),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 28),
        child: Text(
          'No se pudo verificar si tienes un perfil de speaker.',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
