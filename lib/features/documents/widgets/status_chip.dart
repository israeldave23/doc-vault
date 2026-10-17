import 'package:flutter/material.dart';

import '../../../core/utils/expiry_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final ExpiryStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
