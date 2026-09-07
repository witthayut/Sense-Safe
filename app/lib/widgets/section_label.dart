import 'package:flutter/material.dart';

/// Small uppercase section heading (e.g. "FAVOURITES", "VIBRATION PROFILE").
/// Pulls its style from the shared `textTheme.labelSmall`.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
