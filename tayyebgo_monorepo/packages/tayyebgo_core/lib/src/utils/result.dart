sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull =>
      switch (this) { Success(:final data) => data, _ => null };

  String? get errorOrNull =>
      switch (this) { Failure(:final message) => message, _ => null };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message) onFailure,
  }) =>
      switch (this) {
        Success(:final data) => onSuccess(data),
        Failure(:final message) => onFailure(message),
      };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;

  const Failure(this.message, {this.error});

  @override
  String toString() => 'Failure($message)';
}

typedef VoidResult = Result<void>;
extension VoidSuccess on Result<void> {
  static VoidResult ok() => const Success<void>(null);
}
