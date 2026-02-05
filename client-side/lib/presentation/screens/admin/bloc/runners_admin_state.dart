import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/runner.dart';

class RunnersAdminState extends Equatable {
  static const Object _noChange = Object();

  final bool isLoading;
  final List<Runner> runners;
  final String? error;

  const RunnersAdminState({
    this.isLoading = false,
    this.runners = const [],
    this.error,
  });

  RunnersAdminState copyWith({
    bool? isLoading,
    List<Runner>? runners,
    Object? error = _noChange,
  }) {
    return RunnersAdminState(
      isLoading: isLoading ?? this.isLoading,
      runners: runners ?? this.runners,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [isLoading, runners, error];
}
