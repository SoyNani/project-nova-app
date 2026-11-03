sealed class AuthFailure {
  const AuthFailure(this.message);
  final String message;
}

class GoogleSignInCancelled extends AuthFailure {
  const GoogleSignInCancelled() : super('Inicio de sesión cancelado.');
}

class UserNotAllowed extends AuthFailure {
  const UserNotAllowed()
      : super('Tu correo no tiene acceso a esta aplicación todavía.');
}

class AuthNetworkError extends AuthFailure {
  const AuthNetworkError()
      : super('No hay conexión. Intenta de nuevo.');
}

class AuthUnknownError extends AuthFailure {
  const AuthUnknownError([String? detail])
      : super(detail ?? 'Ocurrió un error inesperado. Intenta de nuevo.');
}
