import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';
import 'package:legion/presentation/cubit/theme/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._dataSource): super(ThemeState(
    themeMode: _dataSource.getThemeMode(),
    accentColorId: _dataSource.getAccentColorId(),
  ));

  final UserLocalDataSource _dataSource;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _dataSource.setThemeMode(mode);
    emit(ThemeState(themeMode: mode, accentColorId: state.accentColorId));
  }

  Future<void> setAccentColorId(int id) async {
    await _dataSource.setAccentColorId(id);
    emit(ThemeState(themeMode: state.themeMode, accentColorId: id));
  }
}
