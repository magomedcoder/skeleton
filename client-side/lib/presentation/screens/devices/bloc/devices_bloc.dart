import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/domain/usecases/auth/get_devices_usecase.dart';
import 'package:skeleton/domain/usecases/auth/revoke_device_usecase.dart';
import 'package:skeleton/presentation/screens/devices/bloc/devices_event.dart';
import 'package:skeleton/presentation/screens/devices/bloc/devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  final GetDevicesUseCase getDevicesUseCase;
  final RevokeDeviceUseCase revokeDeviceUseCase;

  DevicesBloc({
    required this.getDevicesUseCase,
    required this.revokeDeviceUseCase,
  }) : super(const DevicesInitial()) {
    on<DevicesLoadRequested>(_onLoadRequested);
    on<DevicesRevokeRequested>(_onRevokeRequested);
  }

  Future<void> _onLoadRequested(
    DevicesLoadRequested event,
    Emitter<DevicesState> emit,
  ) async {
    emit(const DevicesLoading());
    try {
      final devices = await getDevicesUseCase();
      emit(DevicesLoaded(devices));
    } catch (e) {
      emit(DevicesError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRevokeRequested(
    DevicesRevokeRequested event,
    Emitter<DevicesState> emit,
  ) async {
    final current = state;
    final devices = switch (current) {
      DevicesLoaded(devices: final d) => d,
      DevicesRevokeFailed(devices: final d) => d,
      _ => null,
    };
    if (devices == null) return;

    emit(DevicesRevoking(devices, event.device.id));
    try {
      await revokeDeviceUseCase(event.device.id);
      final updated = devices.where((d) => d.id != event.device.id).toList();
      emit(DevicesLoaded(updated));
    } catch (e) {
      emit(
        DevicesRevokeFailed(
          devices,
          e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
