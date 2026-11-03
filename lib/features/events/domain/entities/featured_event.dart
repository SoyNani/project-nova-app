import 'event_entity.dart';

class FeaturedEvent {
  const FeaturedEvent({required this.event, required this.timing});

  final EventEntity event;
  final EventTiming timing;
}
