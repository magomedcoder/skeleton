import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/data/data_sources/local/user_local_data_source.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._dataSource) : super(_dataSource.getThemeMode());

  final UserLocalDataSource _dataSource;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _dataSource.setThemeMode(mode);
    emit(mode);
  }
}
