import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/utils/expiry_status.dart';
import '../models/document.dart';
import 'encrypted_image_view.dart';
import 'status_chip.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, required this.document, this.onTap});

  final Document document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = DocumentCategory.byKey(document.category);
    final status = document.status;
    final dateText = DateFormat.yMMMd().format(document.expiryDate);
    final hasPhotos = document.imagePaths.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: hasPhotos
                    ? EncryptedImageView(
                        storedPath: document.imagePaths.first,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: status.color),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.label} · $dateText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusChip(status: status, compact: true),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            daysRemainingLabel(document.daysRemaining),
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: status.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
