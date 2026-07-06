import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/place_prediction.dart';

/// Dropdown of destination suggestions shown under the search bar.
class PredictionsList extends StatelessWidget {
  const PredictionsList({
    super.key,
    required this.predictions,
    required this.onSelect,
  });

  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < predictions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.line, indent: 48),
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.place_outlined, color: AppColors.sageDark),
              title: Text(
                predictions[i].description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () => onSelect(predictions[i]),
            ),
          ],
        ],
      ),
    );
  }
}
