import 'package:equatable/equatable.dart';

class ServerInfo extends Equatable {
  final String hostname;
  final String os;
  final String arch;
  final int cpuCores;
  final int memoryTotalMb;
  final List<String> models;

  const ServerInfo({
    this.hostname = '',
    this.os = '',
    this.arch = '',
    this.cpuCores = 0,
    this.memoryTotalMb = 0,
    this.models = const [],
  });

  @override
  List<Object?> get props => [hostname, os, arch, cpuCores, memoryTotalMb, models];
}
