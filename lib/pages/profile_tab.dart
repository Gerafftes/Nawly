import 'package:flutter/material.dart';

class ProfileTabContent extends StatelessWidget {
  final Color textColor;
  final Color cardColor;
  final String themeMode;
  final Function(String) onThemeChanged;

  const ProfileTabContent({
    super.key,
    required this.textColor,
    required this.cardColor,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Profil',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Theme', style: TextStyle(color: textColor, fontSize: 16)),
              const SizedBox(width: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(value: 'light', label: Text('Light')),
                  ButtonSegment<String>(value: 'auto', label: Text('System')),
                  ButtonSegment<String>(value: 'dark', label: Text('Dark')),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<String> newSelection) {
                  onThemeChanged(newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF007AFF);
                    }
                    return cardColor;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return textColor;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
