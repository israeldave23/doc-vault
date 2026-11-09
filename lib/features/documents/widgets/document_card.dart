import 'package:shadcn_flutter/shadcn_flutter.dart';
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
      onTap: onTap,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Button(
          style: const ButtonStyle.outline(),
          onPressed: onTap,
          enabled: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.title,
                      style: theme.typography.medium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.foreground,
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
                        Text(category.label,
                            style: theme.typography.small.copyWith(
                              color: scheme.mutedForeground,
                            )),
                        Text('Expires $dateText',
                            style: theme.typography.small.copyWith(
                              color: scheme.mutedForeground,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(status: status, compact: true),
                        Text(remainingText,
                            style: theme.typography.xSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronRight,
                  color: scheme.mutedForeground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
