import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/domain/entities/runner.dart';
import 'package:legion/domain/usecases/runners/get_runners_usecase.dart';
import 'package:legion/domain/usecases/runners/set_runner_enabled_usecase.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_event.dart';
import 'package:legion/presentation/screens/admin/bloc/runners_admin_state.dart';

class RunnersAdminBloc extends Bloc<RunnersAdminEvent, RunnersAdminState> {
  final GetRunnersUseCase getRunnersUseCase;
  final SetRunnerEnabledUseCase setRunnerEnabledUseCase;

  RunnersAdminBloc({
    required this.getRunnersUseCase,
    required this.setRunnerEnabledUseCase,
  }) : super(const RunnersAdminState()) {
    on<RunnersAdminLoadRequested>(_onLoad);
    on<RunnersAdminSetEnabledRequested>(_onSetEnabled);
    on<RunnersAdminClearError>(_onClearError);
  }

  Future<void> _onLoad(
    RunnersAdminLoadRequested event,
    Emitter<RunnersAdminState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final runners = await getRunnersUseCase();
      emit(state.copyWith(isLoading: false, runners: runners, error: null));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSetEnabled(
    RunnersAdminSetEnabledRequested event,
    Emitter<RunnersAdminState> emit,
  ) async {
    try {
      await setRunnerEnabledUseCase(event.address, event.enabled);
      final runners = state.runners.map((r) => r.address == event.address
        ? Runner(address: r.address, enabled: event.enabled)
        : r
      ).toList();
      emit(state.copyWith(runners: runners));
    } catch (e) {
      emit(state.copyWith(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onClearError(
    RunnersAdminClearError event,
    Emitter<RunnersAdminState> emit,
  ) {
    emit(state.copyWith(error: null));
  }
}
