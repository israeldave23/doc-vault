import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
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
    final dateText = DateFormat.yMMMd().format(document.expiryDate);
    final remainingText = daysRemainingLabel(document.daysRemaining);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: onTap != null,
          label: '${document.title}, ${category.label}, '
              '${status.label}, $remainingText, expires $dateText',
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: status.colorFor(context), width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.control),
                            ),
                            child: Icon(category.icon,
                                size: 20, color: scheme.onSecondaryContainer),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(category.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant))),
                          Icon(Icons.north_east_rounded,
                              size: 18, color: scheme.onSurfaceVariant),
                        ]),
                        const SizedBox(height: 14),
                        Text(document.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(status: status, compact: true),
                            Text(remainingText,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: scheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('Expires $dateText',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
