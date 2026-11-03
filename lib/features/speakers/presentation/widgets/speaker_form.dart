import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_button.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';
import '../../../../core/widgets/atoms/app_text_field.dart';
import '../../../../core/widgets/molecules/app_social_field.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';
import '../../../organizations/presentation/widgets/organization_picker_field.dart';
import '../../domain/entities/speaker_entity.dart';
import '../providers/speaker_providers.dart';

class SpeakerForm extends ConsumerStatefulWidget {
  const SpeakerForm({super.key, this.speaker, required this.onSaved});

  final SpeakerEntity? speaker;
  final ValueChanged<SpeakerEntity> onSaved;

  @override
  ConsumerState<SpeakerForm> createState() => _SpeakerFormState();
}

class _SpeakerFormState extends ConsumerState<SpeakerForm> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _professionController;
  late final TextEditingController _emailController;
  final _specialtiesController = TextEditingController();
  late final TextEditingController _instagramController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _tiktokController;
  final _specialtiesFocus = FocusNode();

  late final List<String> _specialties;
  String? _organizationsError;

  bool get _isEditing => widget.speaker != null;

  @override
  void initState() {
    super.initState();
    final speaker = widget.speaker;
    _nameController = TextEditingController(text: speaker?.name);
    _professionController = TextEditingController(text: speaker?.profession);
    _emailController = TextEditingController(text: speaker?.email);
    _instagramController = TextEditingController(text: speaker?.instagram);
    _linkedinController = TextEditingController(text: speaker?.linkedin);
    _tiktokController = TextEditingController(text: speaker?.tiktok);
    _specialties = [...?speaker?.specialties];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _specialtiesController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _tiktokController.dispose();
    _specialtiesFocus.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || _emailPattern.hasMatch(email)) return null;
    return 'Ingresa un correo válido.';
  }

  void _commitSpecialties() {
    final pending = _specialtiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_specialties.contains(s));
    if (pending.isEmpty) {
      _specialtiesController.clear();
      return;
    }
    setState(() {
      _specialties.addAll(pending);
      _specialtiesController.clear();
    });
  }

  void _submit() {
    _commitSpecialties();
    final isValid = _formKey.currentState?.validate() ?? false;
    final selectedOrganizations = ref.read(
      speakerSelectedOrganizationsProvider(widget.speaker),
    );
    setState(() {
      _organizationsError = selectedOrganizations.isEmpty
          ? 'Selecciona al menos una organización.'
          : null;
    });
    if (!isValid || _organizationsError != null) return;

    ref
        .read(speakerFormControllerProvider(widget.speaker).notifier)
        .submit(
          name: _nameController.text,
          profession: _professionController.text,
          specialties: List.of(_specialties),
          organizationIds: selectedOrganizations.toList(),
          email: _emailController.text,
          instagram: _instagramController.text,
          linkedin: _linkedinController.text,
          tiktok: _tiktokController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = speakerFormControllerProvider(widget.speaker);

    ref.listen<SpeakerFormState>(formProvider, (_, next) {
      if (next is SpeakerFormSuccess) {
        widget.onSaved(next.speaker);
      } else if (next is SpeakerFormError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    final isLoading = ref.watch(formProvider) is SpeakerFormLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'INFORMACIÓN'),
          const SizedBox(height: 16),
          const Text('NOMBRE', style: AppTextStyles.label),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            hintText: 'Ej. Laura López',
            validator: _requiredValidator,
            semanticsLabel: 'Nombre del speaker',
          ),
          const SizedBox(height: 16),
          const Text('PROFESIÓN', style: AppTextStyles.label),
          const SizedBox(height: 8),
          AppTextField(
            controller: _professionController,
            hintText: 'Ej. Ingeniera de software',
            validator: _requiredValidator,
            semanticsLabel: 'Profesión del speaker',
          ),
          const SizedBox(height: 16),
          const Text('CORREO', style: AppTextStyles.label),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            hintText: 'Ej. laura@correo.com',
            keyboardType: TextInputType.emailAddress,
            readOnly: _isEditing,
            prefixIcon: Icons.mail_outline,
            validator: _emailValidator,
            semanticsLabel: 'Correo del speaker',
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 6),
            const Text(
              'Con este correo el speaker podrá editar su perfil al iniciar '
              'sesión.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          const Text('ESPECIALIDADES', style: AppTextStyles.label),
          const SizedBox(height: 8),
          if (_specialties.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final specialty in _specialties)
                  _SpecialtyChip(
                    label: specialty,
                    onDeleted: () =>
                        setState(() => _specialties.remove(specialty)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          _SpecialtiesInput(
            controller: _specialtiesController,
            focusNode: _specialtiesFocus,
            onSubmitted: () {
              _commitSpecialties();
              _specialtiesFocus.requestFocus();
            },
          ),
          const SizedBox(height: 28),
          const AppSectionHeader(title: 'ORGANIZACIÓN'),
          const SizedBox(height: 16),
          const Text(
            'ASOCIAR A UNA ORGANIZACIÓN EXISTENTE',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 10),
          _OrganizationSelector(
            speaker: widget.speaker,
            errorText: _organizationsError,
            onChanged: () => setState(() => _organizationsError = null),
          ),
          const SizedBox(height: 28),
          const AppSectionHeader(title: 'REDES SOCIALES'),
          const SizedBox(height: 16),
          AppSocialField(
            controller: _instagramController,
            hintText: 'Instagram',
            icon: Icons.camera_alt_outlined,
            color: AppColors.socialInstagram,
            semanticsLabel: 'Instagram del speaker',
          ),
          const SizedBox(height: 10),
          AppSocialField(
            controller: _linkedinController,
            hintText: 'LinkedIn',
            icon: Icons.work_outline,
            color: AppColors.socialLinkedin,
            semanticsLabel: 'LinkedIn del speaker',
          ),
          const SizedBox(height: 10),
          AppSocialField(
            controller: _tiktokController,
            hintText: 'TikTok',
            icon: Icons.music_note_outlined,
            color: AppColors.socialTikTok,
            semanticsLabel: 'TikTok del speaker',
          ),
          const SizedBox(height: 32),
          AppButton(
            label: _isEditing ? 'Guardar cambios' : 'Crear speaker',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _SpecialtiesInput extends StatelessWidget {
  const _SpecialtiesInput({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Especialidades del speaker',
      textField: true,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: const InputDecoration(
          hintText: 'Escribe y presiona Enter...',
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationSelector extends ConsumerWidget {
  const _OrganizationSelector({
    required this.speaker,
    required this.errorText,
    required this.onChanged,
  });

  final SpeakerEntity? speaker;
  final String? errorText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionProvider = speakerSelectedOrganizationsProvider(speaker);
    final selected = ref.watch(selectionProvider);
    final organizationsAsync = ref.watch(organizationsListProvider);

    return organizationsAsync.when(
      data: (organizations) {
        if (organizations.isEmpty) {
          return const Text(
            'Primero crea una organización en el módulo de organizaciones.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          );
        }
        return OrganizationPickerField(
          organizations: organizations,
          selectedIds: selected,
          multiple: true,
          errorText: errorText,
          onToggle: (id) {
            ref.read(selectionProvider.notifier).toggle(id);
            onChanged();
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text(
        'No se pudieron cargar las organizaciones.',
        style: TextStyle(fontSize: 14, color: AppColors.error),
      ),
    );
  }
}
