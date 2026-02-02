import 'package:equatable/equatable.dart';

class GpuInfo extends Equatable {
  final String name;
  final int temperatureC;
  final int memoryTotalMb;
  final int memoryUsedMb;
  final int utilizationPercent;

  const GpuInfo({
    required this.name,
    this.temperatureC = 0,
    this.memoryTotalMb = 0,
    this.memoryUsedMb = 0,
    this.utilizationPercent = 0,
  });

  @override
  List<Object?> get props => [name, temperatureC, memoryTotalMb, memoryUsedMb, utilizationPercent];
}
