import 'package:flutter/material.dart';

class RoleSelectionPlaceholder extends StatelessWidget {
  const RoleSelectionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Phase 1 Complete\nRole Selection Coming Next",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
