import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// From + To search card. "From" defaults to the device's current location
/// (shown as a hint) but can be typed/picked, with a button to reset it back.
class RouteSearch extends StatelessWidget {
  const RouteSearch({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.useCurrentLocation,
    required this.loading,
    required this.onOriginChanged,
    required this.onDestChanged,
    required this.onUseMyLocation,
    required this.onSearch,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final bool useCurrentLocation;
  final bool loading;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestChanged;
  final VoidCallback onUseMyLocation;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Connector rail: origin dot ┊ destination pin ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.sageDark, width: 2.5),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line,
                    ),
                  ),
                  const Icon(Icons.place, color: AppColors.danger, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ── The two fields ────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _FieldRow(
                    field: TextField(
                      controller: originController,
                      onChanged: onOriginChanged,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: useCurrentLocation
                            ? 'Current location'
                            : 'Start location',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Use my current location',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.gps_fixed,
                        color: useCurrentLocation
                            ? AppColors.sageDark
                            : AppColors.inkSoft,
                        size: 20,
                      ),
                      onPressed: onUseMyLocation,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _FieldRow(
                    field: TextField(
                      controller: destinationController,
                      onChanged: onDestChanged,
                      onSubmitted: (_) => onSearch(),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Where to?',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                    trailing: Material(
                      color: AppColors.sageDark,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onSearch,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: loading
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row inside the From/To card: a field + a trailing action, with a
/// consistent height so both rows line up with the connector rail.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.trailing});

  final Widget field;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 4),
          trailing,
        ],
      ),
    );
  }
}
