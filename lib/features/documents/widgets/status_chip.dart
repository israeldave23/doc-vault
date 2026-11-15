import 'package:flutter/material.dart';

import '../../../core/utils/expiry_status.dart';

/// Semantic status capsule.
///
/// A tint plus a hairline in the status colour, rather than a saturated fill,
/// so a list of documents stays calm and the eye goes to the countdown first.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final ExpiryStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.colorFor(context);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11.5 : 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
