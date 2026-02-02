import 'package:equatable/equatable.dart';

class Runner extends Equatable {
  final String address;
  final bool enabled;
  final bool connected;

  const Runner({
    required this.address,
    required this.enabled,
    this.connected = false,
  });

  @override
  List<Object?> get props => [address, enabled, connected];
}
