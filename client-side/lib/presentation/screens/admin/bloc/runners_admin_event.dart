import 'package:equatable/equatable.dart';

sealed class RunnersAdminEvent extends Equatable {
  const RunnersAdminEvent();

  @override
  List<Object?> get props => [];
}

class RunnersAdminLoadRequested extends RunnersAdminEvent {
  const RunnersAdminLoadRequested();
}

class RunnersAdminSetEnabledRequested extends RunnersAdminEvent {
  final String address;
  final bool enabled;

  const RunnersAdminSetEnabledRequested({
    required this.address,
    required this.enabled,
  });

  @override
  List<Object?> get props => [address, enabled];
}

class RunnersAdminClearError extends RunnersAdminEvent {
  const RunnersAdminClearError();
}
