import 'package:flutter/material.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091524), Color(0xFF07111F), Color(0xFF050B14)],
          ),
        ),
        child: SafeArea(bottom: false, child: body),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottomAction != null)
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: bottomAction!,
            ),
          AppBottomNavBar(currentIndex: currentIndex),
        ],
      ),
    );
  }
}
