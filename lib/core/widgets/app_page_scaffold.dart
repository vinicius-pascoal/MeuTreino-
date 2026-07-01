import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'app_background.dart';
import 'app_bottom_nav_bar.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomAction;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    this.actions,
    this.floatingActionButton,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: AppBackground(
        child: SafeArea(bottom: false, child: body),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottomAction != null)
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppThemeColors.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppThemeColors.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: bottomAction!,
                ),
              ),
            ),
          AppBottomNavBar(currentIndex: currentIndex),
        ],
      ),
    );
  }
}
