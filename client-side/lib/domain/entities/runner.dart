import 'package:equatable/equatable.dart';
import 'package:skeleton/domain/entities/gpu_info.dart';
import 'package:skeleton/domain/entities/server_info.dart';

class Runner extends Equatable {
  final String address;
  final bool enabled;
  final bool connected;
  final List<GpuInfo> gpus;
  final ServerInfo? serverInfo;

  const Runner({
    required this.address,
    required this.enabled,
    this.connected = false,
    this.gpus = const [],
    this.serverInfo,
  });

  @override
  List<Object?> get props => [address, enabled, connected, gpus, serverInfo];
}
