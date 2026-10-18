import 'package:flutter/material.dart';

import 'services/ui_scale.dart';

/// Keeps startup work outside build and lets FutureBuilder discard stale results.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key, required this.load});

  final Future<Widget> Function() load;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<Widget> _startup;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _loading = true;
    _startup = Future<Widget>.sync(widget.load).whenComplete(() {
      if (mounted) _loading = false;
    });
    // Retry can fail before the next frame attaches FutureBuilder's listener.
    // Keep that error handled; FutureBuilder still renders the failed result.
    _startup.ignore();
  }

  void _retry() {
    if (_loading) return;
    setState(_start);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return snapshot.requireData;
      }
      final failed =
          snapshot.connectionState == ConnectionState.done && snapshot.hasError;
      return MaterialApp(
        key: const ValueKey('startup-status'),
        title: 'Nawly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
          useMaterial3: true,
        ),
        home: Builder(
          builder: (context) {
            final ui = UiScale.of(context);
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(ui.s(24)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!failed) ...[
                          const CircularProgressIndicator(
                            semanticsLabel: 'Nawly wird gestartet',
                          ),
                          SizedBox(height: ui.s(24)),
                        ],
                        Text(
                          failed
                              ? 'Nawly konnte nicht gestartet werden.'
                              : 'Nawly wird gestartet …',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (failed) ...[
                          SizedBox(height: ui.s(24)),
                          FilledButton(
                            onPressed: _retry,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
