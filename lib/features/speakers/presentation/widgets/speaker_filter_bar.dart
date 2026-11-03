import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/atoms/app_search_field.dart';
import '../../../../core/widgets/atoms/app_square_icon_button.dart';
import '../providers/speaker_providers.dart';

class SpeakerFilterBar extends ConsumerStatefulWidget {
  const SpeakerFilterBar({super.key});

  @override
  ConsumerState<SpeakerFilterBar> createState() => _SpeakerFilterBarState();
}

class _SpeakerFilterBarState extends ConsumerState<SpeakerFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(speakerSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaceFilter = ref.watch(speakerOrganizationFilterProvider) != null;

    ref.listen<String>(speakerSearchQueryProvider, (previous, next) {
      if (next != _searchController.text) _searchController.text = next;
    });

    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            controller: _searchController,
            hintText: 'Buscar por nombre',
            semanticsLabel: 'Buscar speaker por nombre',
            onChanged: (value) =>
                ref.read(speakerSearchQueryProvider.notifier).update(value),
            onClear: () =>
                ref.read(speakerSearchQueryProvider.notifier).clear(),
          ),
        ),
        const SizedBox(width: 10),
        AppSquareIconButton(
          icon: Icons.tune,
          tooltip: 'Filtros',
          size: 50,
          showDot: hasPlaceFilter,
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
    );
  }
}
