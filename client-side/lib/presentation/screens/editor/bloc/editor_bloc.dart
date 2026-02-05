import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/log/logs.dart';
import 'package:skeleton/domain/usecases/chat/get_models_usecase.dart';
import 'package:skeleton/domain/usecases/editor/transform_text_usecase.dart';
import 'package:skeleton/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:skeleton/presentation/screens/editor/bloc/editor_event.dart';
import 'package:skeleton/presentation/screens/editor/bloc/editor_state.dart';
import 'package:skeleton/presentation/utils/request_logout_on_unauthorized.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final AuthBloc authBloc;
  final GetModelsUseCase getModelsUseCase;
  final TransformTextUseCase transformTextUseCase;

  EditorBloc({
    required this.authBloc,
    required this.getModelsUseCase,
    required this.transformTextUseCase,
  }) : super(const EditorState()) {
    on<EditorStarted>(_onStarted);
    on<EditorInputChanged>(_onInputChanged);
    on<EditorModelChanged>(_onModelChanged);
    on<EditorTransformPressed>(_onTransformPressed);
    on<EditorClearError>(_onClearError);
  }

  Future<void> _onStarted(
    EditorStarted event,
    Emitter<EditorState> emit,
  ) async {
    Logs().d('EditorBloc: старт, загрузка моделей');
    try {
      final models = await getModelsUseCase();
      emit(
        state.copyWith(
          models: models,
          selectedModel: models.isNotEmpty ? models.first : null,
        ),
      );
    } catch (e) {
      Logs().w('EditorBloc: не удалось загрузить модели', e);
    }
  }

  void _onInputChanged(EditorInputChanged event, Emitter<EditorState> emit) {
    emit(state.copyWith(inputText: event.text));
  }

  void _onModelChanged(EditorModelChanged event, Emitter<EditorState> emit) {
    emit(state.copyWith(selectedModel: event.model));
  }

  Future<void> _onTransformPressed(
    EditorTransformPressed event,
    Emitter<EditorState> emit,
  ) async {
    final input = state.inputText.trim();
    if (input.isEmpty) {
      emit(state.copyWith(error: 'Введите текст', clearError: false));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final out = await transformTextUseCase(
        text: input,
        model: state.selectedModel,
      );
      emit(state.copyWith(isLoading: false, outputText: out));
    } catch (e) {
      Logs().e('EditorBloc: ошибка transform', e);
      requestLogoutIfUnauthorized(e, authBloc);
      emit(state.copyWith(isLoading: false, error: 'Ошибка обработки текста'));
    }
  }

  void _onClearError(EditorClearError event, Emitter<EditorState> emit) {
    emit(state.copyWith(clearError: true));
  }
}
