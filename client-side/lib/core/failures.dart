sealed class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}
