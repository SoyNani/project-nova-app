import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_providers.dart';

/// Pide confirmación y cancela el evento. Devuelve `true` si se canceló.
Future<bool> confirmAndCancelEvent(
  BuildContext context,
  WidgetRef ref,
  EventEntity event,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancelar evento'),
      content: Text(
        '"${event.name}" dejará de aparecer en el inicio y el cronograma. '
        'Podrás verlo y restaurarlo en "Eventos cancelados".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Cancelar evento',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final restore = ref.read(restoreEventProvider);
  final result = await ref.read(cancelEventProvider)(event);

  return result.match(
    (failure) {
      _showError(messenger, failure.message);
      return false;
    },
    (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Evento cancelado.'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => restore(_asCancelled(event)),
            ),
          ),
        );
      return true;
    },
  );
}

Future<bool> restoreCancelledEvent(
  BuildContext context,
  WidgetRef ref,
  EventEntity event,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(restoreEventProvider)(event);
  return result.match(
    (failure) {
      _showError(messenger, failure.message);
      return false;
    },
    (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Evento restaurado.')));
      return true;
    },
  );
}

void _showError(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
}

EventEntity _asCancelled(EventEntity event) {
  return EventEntity(
    id: event.id,
    name: event.name,
    description: event.description,
    startAt: event.startAt,
    endAt: event.endAt,
    organizationId: event.organizationId,
    organizationName: event.organizationName,
    city: event.city,
    address: event.address,
    speakerIds: event.speakerIds,
    speakerNames: event.speakerNames,
    createdBy: event.createdBy,
    isCancelled: true,
  );
}
