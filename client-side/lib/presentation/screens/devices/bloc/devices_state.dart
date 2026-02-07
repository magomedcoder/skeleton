import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/device.dart';

sealed class DevicesState extends Equatable {
  const DevicesState();

  @override
  List<Object?> get props => [];
}

class DevicesInitial extends DevicesState {
  const DevicesInitial();
}

class DevicesLoading extends DevicesState {
  const DevicesLoading();
}

class DevicesLoaded extends DevicesState {
  final List<Device> devices;

  const DevicesLoaded(this.devices);

  @override
  List<Object?> get props => [devices];
}

class DevicesError extends DevicesState {
  final String message;

  const DevicesError(this.message);

  @override
  List<Object?> get props => [message];
}

class DevicesRevoking extends DevicesState {
  final List<Device> devices;
  final int revokingDeviceId;

  const DevicesRevoking(this.devices, this.revokingDeviceId);

  @override
  List<Object?> get props => [devices, revokingDeviceId];
}

class DevicesRevokeFailed extends DevicesState {
  final List<Device> devices;
  final String message;

  const DevicesRevokeFailed(this.devices, this.message);

  @override
  List<Object?> get props => [devices, message];
}
