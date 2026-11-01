import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/utils/expiry_status.dart';
import '../models/document.dart';
import 'status_chip.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document, this.onTap});

  final Document document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = DocumentCategory.byKey(document.category);
    final status = document.status;
    final statusColor = status.colorFor(context);
    final dateText = DateFormat.yMMMd().format(document.expiryDate);
    final remainingText = daysRemainingLabel(document.daysRemaining);
    final semanticLabel = '${document.title}, ${category.label}, '
        '${status.label}, $remainingText, expires $dateText';

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: scheme.surface,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryIcon(icon: category.icon, color: statusColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            document.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                category.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 14,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires $dateText',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusChip(status: status, compact: true),
                              Text(
                                remainingText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: scheme.outline, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      );
}
