import 'package:equatable/equatable.dart';

class Runner extends Equatable {
  final String address;
  final bool enabled;

  const Runner({required this.address, required this.enabled});

  @override
  List<Object?> get props => [address, enabled];
}
