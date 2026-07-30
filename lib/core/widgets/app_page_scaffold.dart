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
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: floatingActionButtonBottomPadding,
              ),
              child: floatingActionButton!,
            ),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageIdentifier(title: title, actions: actions),
              Expanded(child: body),
            ],
          ),
        ),
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

class AppPageIdentifier extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const AppPageIdentifier({
    super.key,
    required this.title,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingActions = actions ?? const <Widget>[];

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: AppThemeColors.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailingActions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...trailingActions,
          ],
        ],
      ),
    );
  }
}
