import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_date_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/atoms/app_button.dart';
import '../../../../core/widgets/atoms/app_filter_chip.dart';
import '../../../../core/widgets/atoms/app_section_header.dart';
import '../../../../core/widgets/atoms/app_text_field.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../../organizations/domain/entities/organization_entity.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';
import '../../../organizations/presentation/widgets/organization_picker_field.dart';
import '../../../speakers/domain/entities/speaker_entity.dart';
import '../../../speakers/presentation/providers/speaker_providers.dart';
import '../providers/event_providers.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.createdBy});

  final String? createdBy;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _organizationError;
  String? _scheduleError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final draft = ref.read(eventDraftProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha del evento',
    );
    if (picked == null) return;
    ref.read(eventDraftProvider.notifier).setDate(picked);
    setState(() => _scheduleError = null);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final draft = ref.read(eventDraftProvider);
    final current = isStart ? draft.startTime : draft.endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: isStart ? 'Hora de inicio' : 'Hora de fin',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      errorInvalidText: 'Ingresa una hora válida',
      builder: (context, child) => Localizations.override(
        context: context,
        locale: const Locale('en'),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        ),
      ),
    );
    if (picked == null) return;
    final notifier = ref.read(eventDraftProvider.notifier);
    isStart ? notifier.setStartTime(picked) : notifier.setEndTime(picked);
    setState(() => _scheduleError = null);
  }

  String? _formatTime(TimeOfDay? time) => time == null
      ? null
      : AppDateFormat.time(DateTime(2000, 1, 1, time.hour, time.minute));

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final draft = ref.read(eventDraftProvider);
    final organizations = ref.read(organizationsListProvider).value ?? const [];
    final speakers = ref.read(speakersListProvider).value ?? const [];

    final organization = _findOrganization(organizations, draft.organizationId);
    final startAt = draft.startAt;
    final endAt = draft.endAt;

    setState(() {
      _organizationError = organization == null
          ? 'Selecciona una organización.'
          : null;
      _scheduleError = startAt == null || endAt == null
          ? 'Elige la fecha y las horas de inicio y fin.'
          : !endAt.isAfter(startAt)
          ? 'La hora de fin debe ser posterior a la de inicio.'
          : null;
    });
    if (!isValid || _organizationError != null || _scheduleError != null) {
      return;
    }

    final selectedSpeakers = [
      for (final id in draft.speakerIds)
        ...speakers.where((speaker) => speaker.id == id),
    ];

    ref
        .read(eventFormControllerProvider.notifier)
        .submit(
          name: _nameController.text,
          description: _descriptionController.text,
          startAt: startAt!,
          endAt: endAt!,
          organizationId: organization!.id,
          organizationName: organization.name,
          city: organization.city,
          address: organization.address,
          speakerIds: [for (final s in selectedSpeakers) s.id],
          speakerNames: [for (final s in selectedSpeakers) s.name],
          createdBy: widget.createdBy,
        );
  }

  static OrganizationEntity? _findOrganization(
    List<OrganizationEntity> organizations,
    String? id,
  ) {
    for (final org in organizations) {
      if (org.id == id) return org;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EventFormState>(eventFormControllerProvider, (_, next) {
      if (next is EventFormSuccess) {
        Navigator.of(context).pop(next.event);
      } else if (next is EventFormError) {
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

    final isLoading =
        ref.watch(eventFormControllerProvider) is EventFormLoading;
    final draft = ref.watch(eventDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Nuevo evento',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(title: 'INFORMACIÓN'),
                    const SizedBox(height: 16),
                    const Text('NOMBRE DEL EVENTO', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _nameController,
                      hintText: 'Ej. Innovación educativa y liderazgo juvenil',
                      validator: _requiredValidator,
                      semanticsLabel: 'Nombre del evento',
                    ),
                    const SizedBox(height: 16),
                    const Text('DESCRIPCIÓN', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _descriptionController,
                      hintText: '¿De qué trata el evento?',
                      minLines: 3,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      semanticsLabel: 'Descripción del evento',
                    ),
                    const SizedBox(height: 28),
                    const AppSectionHeader(title: 'FECHA Y HORARIO'),
                    const SizedBox(height: 16),
                    _PickerTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'FECHA',
                      value: draft.date == null
                          ? null
                          : AppDateFormat.longDate(draft.date!),
                      placeholder: 'Selecciona la fecha',
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule,
                            label: 'INICIO',
                            value: _formatTime(draft.startTime),
                            placeholder: '--:--',
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule_outlined,
                            label: 'FIN',
                            value: _formatTime(draft.endTime),
                            placeholder: '--:--',
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    if (_scheduleError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _scheduleError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const AppSectionHeader(title: 'ORGANIZACIÓN'),
                    const SizedBox(height: 16),
                    const Text(
                      'ASOCIAR A UNA ORGANIZACIÓN EXISTENTE',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 10),
                    _OrganizationSection(
                      selectedId: draft.organizationId,
                      errorText: _organizationError,
                      onSelected: (id) {
                        ref
                            .read(eventDraftProvider.notifier)
                            .selectOrganization(id);
                        setState(() => _organizationError = null);
                      },
                    ),
                    const SizedBox(height: 28),
                    const AppSectionHeader(title: 'SPEAKERS'),
                    const SizedBox(height: 16),
                    _SpeakersSection(
                      selectedIds: draft.speakerIds,
                      onToggle: (id) => ref
                          .read(eventDraftProvider.notifier)
                          .toggleSpeaker(id),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Crear evento',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.calendarColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.calendarColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: value == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationSection extends ConsumerWidget {
  const _OrganizationSection({
    required this.selectedId,
    required this.errorText,
    required this.onSelected,
  });

  final String? selectedId;
  final String? errorText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(organizationsListProvider)
        .when(
          data: (organizations) {
            if (organizations.isEmpty) {
              return const Text(
                'Primero crea una organización en el módulo de organizaciones.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              );
            }
            return OrganizationPickerField(
              organizations: organizations,
              selectedIds: [?selectedId],
              onToggle: onSelected,
              errorText: errorText,
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

class _SpeakersSection extends ConsumerWidget {
  const _SpeakersSection({required this.selectedIds, required this.onToggle});

  final List<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(speakersListProvider)
        .when(
          data: (speakers) {
            if (speakers.isEmpty) {
              return const Text(
                'Aún no hay speakers. Puedes asignarlos más adelante.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final speaker in speakers)
                  AppFilterChip(
                    label: speaker.name,
                    selected: selectedIds.contains(speaker.id),
                    leading: _SpeakerInitials(
                      speaker: speaker,
                      selected: selectedIds.contains(speaker.id),
                    ),
                    onSelected: () => onToggle(speaker.id),
                  ),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text(
            'No se pudieron cargar los speakers.',
            style: TextStyle(fontSize: 14, color: AppColors.error),
          ),
        );
  }
}

class _SpeakerInitials extends StatelessWidget {
  const _SpeakerInitials({required this.speaker, required this.selected});

  final SpeakerEntity speaker;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.navActiveOverlay
            : AppColors.avatarBackground,
      ),
      child: Text(
        speaker.initials,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: selected ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
    );
  }
}
