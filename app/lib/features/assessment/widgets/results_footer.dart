import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// "Not a diagnosis" reassurance callout.
class ReassuranceCallout extends StatelessWidget {
  const ReassuranceCallout({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.onSage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.verified_user_outlined,
                  size: 18, color: AppColors.sageDark),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "These results aren't a diagnosis — just your starting "
              'vibration profile. You can fine-tune it anytime.',
              style:
                  TextStyle(fontSize: 13, color: AppColors.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary "Done" CTA with a two-line label.
class ResultsDoneButton extends StatelessWidget {
  const ResultsDoneButton({
    super.key,
    required this.subtitle,
    required this.onPressed,
  });

  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sageDark,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined "Retake the assessment" CTA.
class ResultsRetakeButton extends StatelessWidget {
  const ResultsRetakeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, size: 15, color: AppColors.sageDark),
              SizedBox(width: 8),
              Text(
                'Retake the assessment',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
