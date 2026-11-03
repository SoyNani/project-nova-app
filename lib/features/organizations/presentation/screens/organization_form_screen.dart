import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/atoms/app_button.dart';
import '../../../../core/widgets/atoms/app_text_field.dart';
import '../../../../core/widgets/molecules/app_top_bar.dart';
import '../../domain/entities/organization_entity.dart';
import '../providers/organization_providers.dart';
import '../widgets/organization_location_picker.dart';

const _defaultLatitude = 7.1193;
const _defaultLongitude = -73.1227;

class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.existing});

  final OrganizationEntity? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState
    extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _departmentController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _cityController = TextEditingController(text: existing?.city ?? '');
    _departmentController = TextEditingController(
      text: existing?.department ?? '',
    );
    _addressController = TextEditingController(text: existing?.address ?? '');
    _latController = TextEditingController(
      text: (existing?.latitude ?? _defaultLatitude).toString(),
    );
    _lngController = TextEditingController(
      text: (existing?.longitude ?? _defaultLongitude).toString(),
    );
  }

  bool _isLocating = false;
  String? _locateMessage;
  bool _locateFailed = false;

  LatLng get _position => LatLng(
    double.tryParse(_latController.text) ?? _defaultLatitude,
    double.tryParse(_lngController.text) ?? _defaultLongitude,
  );

  void _onLocationChanged(LatLng position) {
    setState(() {
      _latController.text = position.latitude.toString();
      _lngController.text = position.longitude.toString();
    });
  }
  
  Future<void> _locateAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty || _isLocating) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final query = [
      address,
      _cityController.text.trim(),
      _departmentController.text.trim(),
      'Colombia',
    ].where((part) => part.isNotEmpty).join(', ');

    setState(() {
      _isLocating = true;
      _locateMessage = null;
    });
    try {
      final results = await Geocoding().locationFromAddress(
        query,
        locale: const Locale('es', 'CO'),
      );
      if (!mounted) return;
      if (results.isEmpty) throw StateError('Sin resultados');
      final first = results.first;
      _onLocationChanged(LatLng(first.latitude, first.longitude));
      setState(() {
        _locateFailed = false;
        _locateMessage =
            'Dirección ubicada. Si no es el punto exacto, toca o arrastra '
            'el pin en el mapa.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locateFailed = true;
        _locateMessage =
            'No encontramos esa dirección. Revisa la ciudad o marca el '
            'lugar directamente en el mapa.';
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }
    return null;
  }

  String? _coordinateValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido.';
    if (double.tryParse(value.trim()) == null) return 'Debe ser un número.';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(organizationFormControllerProvider.notifier);
    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());

    if (widget.isEditing) {
      controller.submitUpdate(
        OrganizationEntity(
          id: widget.existing!.id,
          name: _nameController.text.trim(),
          city: _cityController.text.trim(),
          department: _departmentController.text.trim(),
          address: _addressController.text.trim(),
          latitude: lat,
          longitude: lng,
          eventsCount: widget.existing!.eventsCount,
        ),
      );
    } else {
      controller.submitCreate(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        department: _departmentController.text.trim(),
        address: _addressController.text.trim(),
        latitude: lat,
        longitude: lng,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(organizationFormControllerProvider, (previous, next) {
      if (next is OrganizationFormSuccess) {
        Navigator.of(context).pop();
      } else if (next is OrganizationFormError) {
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

    final formState = ref.watch(organizationFormControllerProvider);
    final isLoading = formState is OrganizationFormLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: widget.isEditing ? 'Editar organización' : 'Nueva organización',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOMBRE DE LA ORGANIZACIÓN',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  hintText: 'Ej. Colegio San José',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEPARTAMENTO',
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _departmentController,
                            hintText: 'Ej. Santander',
                            validator: _requiredValidator,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CIUDAD', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _cityController,
                            hintText: 'Ej. Bucaramanga',
                            validator: _requiredValidator,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('DIRECCIÓN', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _addressController,
                  hintText: 'Ej. Cra 27 # 45-12',
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _locateAddress(),
                  suffixIcon: _isLocating
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Ubicar en el mapa',
                          icon: const Icon(
                            Icons.travel_explore,
                            color: AppColors.primary,
                          ),
                          onPressed: _locateAddress,
                        ),
                ),
                if (_locateMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _locateMessage!,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      fontSize: 12,
                      color: _locateFailed
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('UBICACIÓN EN EL MAPA', style: AppTextStyles.label),
                const SizedBox(height: 8),
                OrganizationLocationPicker(
                  position: _position,
                  onLocationChanged: _onLocationChanged,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LATITUD', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _latController,
                            hintText: '7.1193',
                            readOnly: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: _coordinateValidator,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LONGITUD', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _lngController,
                            hintText: '-73.1227',
                            readOnly: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: _coordinateValidator,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: widget.isEditing
                      ? 'Guardar cambios'
                      : 'Crear organización',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
