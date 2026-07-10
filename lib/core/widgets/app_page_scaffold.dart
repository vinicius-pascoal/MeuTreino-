import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'app_background.dart';

const double _floatingActionButtonNavOffset = 92;

class AppPageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomAction;
  final Widget? bottomNavigationBar;

  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.actions,
    this.floatingActionButton,
    this.bottomAction,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final floatingActionButtonBottomPadding =
        _floatingActionButtonNavOffset +
        (bottomAction != null ? 76 : 0) +
        (bottomNavigationBar != null ? 92 : 0);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: floatingActionButtonBottomPadding,
              ),
              child: floatingActionButton!,
            ),
      body: AppBackground(
        child: SafeArea(bottom: false, child: body),
      ),
      bottomNavigationBar:
          bottomAction == null && bottomNavigationBar == null
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bottomAction != null)
                      SafeArea(
                        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppThemeColors.surface.withValues(
                              alpha: 0.78,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppThemeColors.outline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: bottomAction!,
                          ),
                        ),
                      ),
                    if (bottomNavigationBar != null) bottomNavigationBar!,
                  ],
                ),
    );
  }
}
