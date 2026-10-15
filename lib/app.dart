import 'package:flutter/material.dart';

import 'data/element_repository.dart';
import 'screens/periodic_table_screen.dart';
import 'theme/app_theme.dart';

class PeriodicTableStudyApp extends StatefulWidget {
  const PeriodicTableStudyApp({super.key});

  @override
  State<PeriodicTableStudyApp> createState() => _PeriodicTableStudyAppState();
}

class _PeriodicTableStudyAppState extends State<PeriodicTableStudyApp> {
  late final ElementRepository _repository = ElementRepository();
  late final Future<void> _loadFuture = _repository.load();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '元素周期表查询与背诵',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }
          return PeriodicTableScreen(repository: _repository);
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '元素数据加载失败\n$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
