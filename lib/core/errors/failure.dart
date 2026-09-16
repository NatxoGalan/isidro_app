abstract class Failure {}
class ServerFailure extends Failure {
  final String message;
  ServerFailure(this.message);
}
class CacheFailure extends Failure {
  final String message;
  CacheFailure(this.message);
}
class ValidationFailure extends Failure {
  final String message;
  ValidationFailure(this.message);
}
class EmptyFailure extends Failure {}
