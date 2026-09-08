import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Results screen header: circular back button, title, and a
/// "What this means?" pill that opens the explainer.
class ResultsHeader extends StatelessWidget {
  const ResultsHeader({
    super.key,
    required this.onBack,
    required this.onExplain,
  });

  final VoidCallback onBack;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Your Results',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          shape:
              const StadiumBorder(side: BorderSide(color: AppColors.sageSoft)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onExplain,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 13, color: AppColors.sageDeep),
                  SizedBox(width: 5),
                  Text(
                    'What this means?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sageDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
