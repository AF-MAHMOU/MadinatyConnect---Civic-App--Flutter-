import 'package:flutter/material.dart';
import '../main.dart';

class DarkModeHelper {
  static Widget addDarkModeToggle(Widget screen) {
    return _DarkModeWrapper(child: screen);
  }

  
}

class _DarkModeWrapper extends StatelessWidget {
  final Widget child;

  const _DarkModeWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (child is! Scaffold) {
      return child;
    }

    final scaffold = child as Scaffold;
    final appBar = scaffold.appBar;
    
    if (appBar == null || appBar is! AppBar) {
      return scaffold;
    }
    

    return Scaffold(
      key: scaffold.key,
      appBar: AppBar(
        leading: appBar.leading,
        automaticallyImplyLeading: appBar.automaticallyImplyLeading,
        title: appBar.title,
        actions: [
          ...?appBar.actions,
          Builder(
            builder: (context) {
              final appState = MyApp.of(context);
              return IconButton(
                icon: Icon(
                  appState?.themeMode == ThemeMode.dark
                      ? Icons.wb_sunny
                      : Icons.nightlight_round,
                ),
                onPressed: () {
                  if (appState != null) {
                    appState.setThemeMode(
                      appState.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  }
                },
              );
            },
          ),
        ],
        flexibleSpace: appBar.flexibleSpace,
        bottom: appBar.bottom,
        elevation: appBar.elevation,
        scrolledUnderElevation: appBar.scrolledUnderElevation,
        notificationPredicate: appBar.notificationPredicate,
        shadowColor: appBar.shadowColor,
        surfaceTintColor: appBar.surfaceTintColor,
        shape: appBar.shape,
        backgroundColor: appBar.backgroundColor,
        foregroundColor: appBar.foregroundColor,
        iconTheme: appBar.iconTheme,
        actionsIconTheme: appBar.actionsIconTheme,
        primary: appBar.primary,
        centerTitle: appBar.centerTitle,
        excludeHeaderSemantics: appBar.excludeHeaderSemantics,
        titleSpacing: appBar.titleSpacing,
        toolbarOpacity: appBar.toolbarOpacity,
        bottomOpacity: appBar.bottomOpacity,
        toolbarHeight: appBar.toolbarHeight,
        leadingWidth: appBar.leadingWidth,
        toolbarTextStyle: appBar.toolbarTextStyle,
        titleTextStyle: appBar.titleTextStyle,
        systemOverlayStyle: appBar.systemOverlayStyle,
      ),
      body: scaffold.body,
      floatingActionButton: scaffold.floatingActionButton,
      floatingActionButtonLocation: scaffold.floatingActionButtonLocation,
      floatingActionButtonAnimator: scaffold.floatingActionButtonAnimator,
      persistentFooterButtons: scaffold.persistentFooterButtons,
      drawer: scaffold.drawer,
      endDrawer: scaffold.endDrawer,
      bottomNavigationBar: scaffold.bottomNavigationBar,
      bottomSheet: scaffold.bottomSheet,
      backgroundColor: scaffold.backgroundColor,
      resizeToAvoidBottomInset: scaffold.resizeToAvoidBottomInset,
      primary: scaffold.primary,
      drawerDragStartBehavior: scaffold.drawerDragStartBehavior,
      extendBody: scaffold.extendBody,
      extendBodyBehindAppBar: scaffold.extendBodyBehindAppBar,
      drawerScrimColor: scaffold.drawerScrimColor,
      drawerEdgeDragWidth: scaffold.drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: scaffold.drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: scaffold.endDrawerEnableOpenDragGesture,
      restorationId: scaffold.restorationId,
    );
  }

}
