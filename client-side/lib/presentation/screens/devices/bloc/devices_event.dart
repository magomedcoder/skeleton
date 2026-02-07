import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/device.dart';

sealed class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object?> get props => [];
}

class DevicesLoadRequested extends DevicesEvent {
  const DevicesLoadRequested();
}

class DevicesRevokeRequested extends DevicesEvent {
  final Device device;

  const DevicesRevokeRequested(this.device);

  @override
  List<Object?> get props => [device.id];
}
