import 'package:flutter/material.dart';

import '../services/ui_scale.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UiScale ui = UiScale.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(ui.s(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: ui.s(56),
                  color: colors.primary,
                ),
                SizedBox(height: ui.s(24)),
                Text(
                  'Seite nicht gefunden',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: ui.s(8)),
                Text(
                  'Die angeforderte Seite ist leider nicht verfügbar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: ui.s(24)),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil<void>(
                      Navigator.defaultRouteName,
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Zur Startseite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
