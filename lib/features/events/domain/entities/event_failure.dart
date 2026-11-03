sealed class EventFailure {
  const EventFailure(this.message);
  final String message;
}

class EventInvalid extends EventFailure {
  const EventInvalid(super.message);
}

class EventUnknownError extends EventFailure {
  const EventUnknownError(super.message);
}
