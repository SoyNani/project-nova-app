sealed class SpeakerFailure {
  const SpeakerFailure(this.message);
  final String message;
}

class SpeakerNotFound extends SpeakerFailure {
  const SpeakerNotFound() : super('Speaker no encontrado.');
}

class SpeakerUnknownError extends SpeakerFailure {
  const SpeakerUnknownError(super.message);
}
