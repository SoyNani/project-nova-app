sealed class OrganizationFailure {
  const OrganizationFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class OrganizationNotFound extends OrganizationFailure {
  const OrganizationNotFound() : super('Organización no encontrada.');
}

class OrganizationHasActiveEvents extends OrganizationFailure {
  const OrganizationHasActiveEvents()
    : super('No se puede eliminar: la organización tiene eventos asociados.');
}

class OrganizationUnknownError extends OrganizationFailure {
  const OrganizationUnknownError(super.message);
}
