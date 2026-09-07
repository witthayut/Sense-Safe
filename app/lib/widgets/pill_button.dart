import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The rounded "pill" button used throughout the mockups.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = true,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: filled
          ? ElevatedButton.icon(
              onPressed: disabled ? null : onPressed,
              icon: _leading(Colors.white),
              label: _text(Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sageDark,
                disabledBackgroundColor: AppColors.sageSoft,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: disabled ? null : onPressed,
              icon: _leading(AppColors.sageDark),
              label: _text(AppColors.sageDark),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.sageDark,
                side: const BorderSide(color: AppColors.sageDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
    );
  }

  Widget _leading(Color color) {
    if (loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return icon == null ? const SizedBox.shrink() : Icon(icon, size: 20);
  }

  Widget _text(Color color) => Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      );
}
