
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/expiry_status.dart';
import '../models/document.dart';
import 'status_chip.dart';

/// One row in the vault.
///
/// Status is carried by a single 3px rail and one capsule; the category glyph
/// stays neutral so colour only ever means "how urgent is this".
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
    final remainingText = _countdown(document.daysRemaining);
    final semanticLabel = '${document.title}, ${category.label}, '
        '${status.label}, $remainingText, expires $dateText';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: onTap != null,
          label: semanticLabel,
          excludeSemantics: true,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: statusColor, width: 3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryGlyph(icon: category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            category.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Expires $dateText',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(status: status, compact: true),
                          Text(
                            remainingText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Omits the repeated status word so an expired row reads "Expired · 41 days
/// ago" rather than "Expired · Expired 41 days ago".
String _countdown(int daysRemaining) {
  if (daysRemaining < 0) {
    final past = -daysRemaining;
    return past == 1 ? '1 day ago' : '$past days ago';
  }
  return daysRemainingLabel(daysRemaining);
}

class _CategoryGlyph extends StatelessWidget {
  const _CategoryGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Icon(icon, color: scheme.onSurfaceVariant, size: 18),
    );
  }
}
