import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OrganizationLocationPicker extends StatefulWidget {
  const OrganizationLocationPicker({
    super.key,
    required this.position,
    required this.onLocationChanged,
  });

  final LatLng position;
  final ValueChanged<LatLng> onLocationChanged;

  @override
  State<OrganizationLocationPicker> createState() =>
      _OrganizationLocationPickerState();
}

class _OrganizationLocationPickerState
    extends State<OrganizationLocationPicker> {
  GoogleMapController? _mapController;

  LatLng? _pickedByUser;

  @override
  void didUpdateWidget(OrganizationLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.position;
    if (position != oldWidget.position && position != _pickedByUser) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updatePosition(LatLng position) {
    _pickedByUser = position;
    widget.onLocationChanged(position);
  }

  Future<void> _recenter() async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(widget.position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.position,
                zoom: 14,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: _updatePosition,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('organization-location'),
                  position: widget.position,
                  draggable: true,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueCyan,
                  ),
                  onDragEnd: _updatePosition,
                ),
              },
            ),
          ),
          const Positioned(top: 12, left: 12, child: _HintChip()),
          Positioned(
            bottom: 12,
            right: 12,
            child: _RecenterButton(onPressed: _recenter),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Toca o arrastra el pin para ajustar',
            style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.my_location, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
