import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_event.dart';
import 'package:legion/presentation/screens/devices/widgets/devices_content.dart';

class ProfileDevicesWidget extends StatefulWidget {
  const ProfileDevicesWidget({super.key});

  @override
  State<ProfileDevicesWidget> createState() => _ProfileDevicesWidgetState();
}

class _ProfileDevicesWidgetState extends State<ProfileDevicesWidget> {
  late final DevicesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = di.sl<DevicesBloc>()..add(const DevicesLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: DevicesContent(),
      ),
    );
  }
}
