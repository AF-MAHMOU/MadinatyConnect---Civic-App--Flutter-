import 'package:flutter/material.dart';
import '../main.dart';

class DarkModeHelper {
  static Widget addDarkModeToggle(Widget screen) {
    if (screen is Scaffold) {
      AppBar? appBar = screen.appBar as AppBar?;
      if (appBar != null && appBar.actions != null) {
        appBar.actions!.add(
          Builder(
            builder: (BuildContext builderContext) {
              return IconButton(
                icon: Icon(
                  Theme.of(builderContext).brightness == Brightness.dark
                      ? Icons.wb_sunny
                      : Icons.nights_stay,
                ),
                onPressed: () {
                  _toggleTheme(builderContext);
                },
              );
            },
          ),
        );
      }
      return screen;
    }
    return screen;
  }

  static void _toggleTheme(BuildContext context) {
    MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
    if (appState != null) {
      appState.setState(() {
        appState.themeMode =
            appState.themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
      });
    }
  }
}
