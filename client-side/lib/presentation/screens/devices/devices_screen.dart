import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:legion/core/injector.dart' as di;
import 'package:legion/presentation/screens/devices/bloc/devices_bloc.dart';
import 'package:legion/presentation/screens/devices/bloc/devices_event.dart';
import 'package:legion/presentation/screens/devices/widgets/devices_content.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
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
      child: Scaffold(
        appBar: AppBar(title: const Text('Устройства и сессии')),
        body: const DevicesContent(),
      ),
    );
  }
}
