import 'package:equatable/equatable.dart';

/// Outcome of an operation that can fail. Repositories return this instead of
/// throwing, so callers are forced by the compiler to handle both branches.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

enum FailureType { network, unauthorized, badRequest, server, unknown }

final class Failure extends Equatable {
  const Failure(this.type, [this.message]);

  final FailureType type;

  /// Server-provided message, if any. UI text for [type] lives in l10n.
  final String? message;

  @override
  List<Object?> get props => [type, message];
}
