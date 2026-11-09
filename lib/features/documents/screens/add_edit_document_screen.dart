import 'package:flutter/services.dart' show TextCapitalization;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/categories.dart';
import '../../../data/local/secure_image_store.dart';
import '../../profiles/models/profile.dart';
import '../../profiles/providers/profile_providers.dart';
import '../../settings/providers/settings_provider.dart';
import '../../reminders/services/reminder_service.dart';
import '../../pro/models/free_tier.dart';
import '../../pro/widgets/free_tier_gate.dart';
import '../models/document.dart';
import '../providers/document_providers.dart';
import '../widgets/encrypted_image_view.dart';

/// Create a new document or edit an existing one (pass [existing]).
class AddEditDocumentScreen extends ConsumerStatefulWidget {
  const AddEditDocumentScreen({super.key, this.existing});

  final Document? existing;

  @override
  ConsumerState<AddEditDocumentScreen> createState() =>
      _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends ConsumerState<AddEditDocumentScreen> {
  static const int _maxPhotos = 3;
  static const List<String> _slotLabels = <String>['Front', 'Back', 'Page 3'];

  late final TextEditingController _titleController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _notesController;
  late final SecureImageStore _imageStore;

  late String _categoryKey;
  late String _profileId;
  DateTime? _issueDate;
  DateTime? _expiryDate;

  /// Expiry date read from the most recent photo by on-device OCR.
  DateTime? _detectedExpiry;
  late bool _remindersEnabled;
  late List<int> _reminderDays;
  late List<String> _imagePaths;

  /// Tracks photos encrypted during this form session so we can clean them up
  /// if the user exits without saving.
  final List<String> _sessionAddedPaths = <String>[];
  final List<String> _originalImagePaths = <String>[];
  bool _didSave = false;
  bool _isSaving = false;
  bool _isCapturingPhoto = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _imageStore = ref.read(secureImageStoreProvider);
    final doc = widget.existing;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _idNumberController = TextEditingController(text: doc?.idNumber ?? '');
    _notesController = TextEditingController(text: doc?.notes ?? '');
    _categoryKey = doc?.category ?? DocumentCategory.passport.key;
    _profileId = doc?.profileId ?? Profile.selfId;
    _issueDate = doc?.issueDate;
    _expiryDate = doc?.expiryDate;
    _remindersEnabled = doc?.remindersEnabled ?? true;
    _reminderDays = List<int>.of(
      doc?.reminderDaysBefore ??
          ref.read(settingsProvider).defaultReminderDays,
    );
    _imagePaths = List<String>.of(doc?.imagePaths ?? const <String>[]);
    _originalImagePaths.addAll(_imagePaths);
  }

  @override
  void dispose() {
    if (!_didSave && _sessionAddedPaths.isNotEmpty) {
      _imageStore.deleteAll(List<String>.of(_sessionAddedPaths));
    }
    _titleController.dispose();
    _idNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Reminder lead-time choices offered to the user, longest first.
  static const _reminderOptions = <int>[90, 60, 30, 14, 7, 3, 1];

  void _toggleReminderDay(int days, bool selected) {
    if (selected) {
      if (!_reminderDays.contains(days)) _reminderDays.add(days);
    } else {
      // Keep at least one reminder so a document can never go silent by accident.
      if (_reminderDays.length > 1) _reminderDays.remove(days);
    }
  }

  List<int> _sortedReminderDays() =>
      List<int>.of(_reminderDays)..sort((a, b) => b.compareTo(a));

  String _reminderSummary() {
    if (!_remindersEnabled) return 'Reminders are off for this document';
    final days = _sortedReminderDays();
    final labels = days.map((d) => d == 1 ? '1 day' : '$d days').toList();
    if (labels.length == 1) return '${labels.first} before expiry';
    final last = labels.removeLast();
    return '${labels.join(', ')} and $last before expiry';
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_imagePaths.length >= _maxPhotos || _isCapturingPhoto) return;

    final source = await const DialogConfiguration().show<ImageSource>(
      context,
      (ctx) => AlertDialog(
        title: const Text('Add photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.ghost(
              alignment: Alignment.centerLeft,
              leading: const Icon(LucideIcons.camera),
              onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
              child: const Text('Take photo'),
            ),
            Button.ghost(
              alignment: Alignment.centerLeft,
              leading: const Icon(LucideIcons.images),
              onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
              child: const Text('Choose from gallery'),
            ),
          ],
        ),
      ),
    ).future;

    if (source == null || !mounted) return;
    await _captureFromSource(source);
  }

  Future<void> _captureFromSource(ImageSource source) async {
    setState(() => _isCapturingPhoto = true);
    try {
      final result = await ref
          .read(photoCaptureServiceProvider)
          .pickCropAndSave(
            source: source,
            toolbarColor: Theme.of(context).colorScheme.primary,
          );
      if (result == null) return;
      if (!mounted) {
        await _imageStore.delete(result.storedPath);
        return;
      }
      setState(() {
        _imagePaths.add(result.storedPath);
        _sessionAddedPaths.add(result.storedPath);
        if (result.suggestedExpiry != null) {
          _detectedExpiry = result.suggestedExpiry;
          // Prefill only when the user has not chosen a date yet; otherwise the
          // suggestion is offered below the field for them to accept.
          _expiryDate ??= result.suggestedExpiry;
        }
      });
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        showDuration: const Duration(seconds: 2),
        builder: (context, overlay) =>
            Alert(content: Text('Could not add photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingPhoto = false);
      }
    }
  }

  Future<void> _removePhotoAt(int index) async {
    final removed = _imagePaths[index];
    setState(() {
      _imagePaths.removeAt(index);
    });
    if (_sessionAddedPaths.remove(removed)) {
      await _imageStore.delete(removed);
    }
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final initial = (isExpiry ? _expiryDate : _issueDate) ?? now;
    final picked = await const DialogConfiguration().show<DateTime>(
      context,
      (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DatePicker(
            value: initial,
            stateBuilder: (date) => date.isBefore(
                DateTime(now.year - 30, now.month, now.day))
                ? DateState.disabled
                : date.isAfter(DateTime(now.year + 30, now.month, now.day))
                    ? DateState.disabled
                    : DateState.enabled,
            onChanged: (date) => Navigator.of(ctx).pop(date),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).future;
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || _isCapturingPhoto || _didSave) return;
    setState(() => _isSaving = true);
    try {
      await _saveDocument();
    } catch (_) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => Alert(
            content: Text(_didSave
                ? 'Document saved, but reminder setup failed.'
                : 'Could not save document. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.trim().isEmpty) {
      showToast(
        context: context,
        builder: (context, overlay) =>
            const Alert(content: Text('Title is required')),
      );
      return;
    }
    if (_expiryDate == null) {
      showToast(
        context: context,
        builder: (context, overlay) =>
            const Alert(content: Text('Please choose an expiry date')),
      );
      return;
    }

    if (!_isEditing) {
      final isPro = ref.read(settingsProvider).isPro;
      final count = ref.read(documentsProvider).length;
      final withinLimit = await ensureWithinFreeTier(
        context,
        allowed: isPro || count < FreeTier.maxDocuments,
        message: FreeTier.documentLimitMessage(count),
      );
      if (!withinLimit || !mounted) return;
    }

    final idNumber = _idNumberController.text.trim();
    final notes = _notesController.text.trim();

    final document = _isEditing
        ? widget.existing!.copyWith(
            title: _titleController.text.trim(),
            category: _categoryKey,
            idNumber: idNumber.isEmpty ? null : idNumber,
            issueDate: _issueDate,
            clearIssueDate: _issueDate == null,
            expiryDate: _expiryDate,
            profileId: _profileId,
            imagePaths: List<String>.unmodifiable(_imagePaths),
            notes: notes.isEmpty ? null : notes,
            reminderDaysBefore: _sortedReminderDays(),
            remindersEnabled: _remindersEnabled,
          )
        : Document(
            id: const Uuid().v4(),
            title: _titleController.text.trim(),
            category: _categoryKey,
            idNumber: idNumber.isEmpty ? null : idNumber,
            issueDate: _issueDate,
            expiryDate: _expiryDate!,
            profileId: _profileId,
            imagePaths: List<String>.unmodifiable(_imagePaths),
            notes: notes.isEmpty ? null : notes,
            reminderDaysBefore: _sortedReminderDays(),
            remindersEnabled: _remindersEnabled,
          );

    await ref.read(documentsProvider.notifier).upsert(document);
    _didSave = true;
    if (mounted && _originalImagePaths.isNotEmpty) {
      final removedPaths = _originalImagePaths
          .where((path) => !_imagePaths.contains(path))
          .toList(growable: false);
      if (removedPaths.isNotEmpty) {
        try {
          await _imageStore.deleteAll(removedPaths);
        } catch (_) {
          // Cleanup failure should not block success. Ciphertext persists,
          // plaintext is gone.
        }
      }
    }
    if (!mounted) return;

    if (_remindersEnabled) {
      // Explain and request notification permission only now that the user
      // actually saved something with reminders on.
      final granted =
          await ref.read(reminderServiceProvider).ensurePermission(context);
      if (!mounted) return;
      if (!granted) {
        showToast(
          context: context,
          builder: (context, overlay) => const Alert(
            content: Text(
              'Saved, but notifications are off — reminders will not fire.',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      headers: [
        AppBar(
          title: Text(_isEditing ? 'Edit document' : 'Add document'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeading(
            icon: LucideIcons.fileScan,
            title: _isEditing ? 'Document details' : 'Add to your vault',
            description:
                'Photos stay encrypted on this device. Only title and expiry date are required.',
          ),
          const SizedBox(height: 16),
          _PhotosSection(
            imagePaths: _imagePaths,
            maxPhotos: _maxPhotos,
            slotLabels: _slotLabels,
            isBusy: _isCapturingPhoto,
            onAddPhoto: _showPhotoSourceSheet,
            onRemovePhoto: _removePhotoAt,
            onPreviewPhoto: (index) {
              Navigator.of(context).push(
                ShadcnPageRoute<void>(
                  builder: (_) => EncryptedPhotoViewerScreen(
                    title: _titleController.text.trim().isEmpty
                        ? 'Document Photo'
                        : _titleController.text.trim(),
                    imagePaths: List<String>.of(_imagePaths),
                    initialIndex: index,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Document'),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            placeholder: const Text('e.g. Philippine Passport'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Select<String>(
            value: _categoryKey,
            placeholder: const Text('Category'),
            onChanged: (value) {
              if (value != null) setState(() => _categoryKey = value);
            },
            itemBuilder: (context, value) => Text(DocumentCategory.byKey(value).label),
            popup: (context) => SelectPopup(
              items: SelectItemList(
                children: [
                  for (final category in DocumentCategory.all)
                    SelectItemButton(
                      value: category.key,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 20),
                          const SizedBox(width: 12),
                          Text(category.label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Important dates'),
          const SizedBox(height: 10),
          _DateTile(
            label: 'Expiry date *',
            value: _expiryDate == null ? null : dateFormat.format(_expiryDate!),
            onTap: () => _pickDate(isExpiry: true),
          ),
          if (_detectedExpiry != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _expiryDate == _detectedExpiry
                          ? 'Detected from photo — '
                              '${dateFormat.format(_detectedExpiry!)}'
                          : 'Detected from photo: '
                              '${dateFormat.format(_detectedExpiry!)}',
                      style: Theme.of(context).typography.small.copyWith(
                            color:
                                Theme.of(context).colorScheme.mutedForeground,
                          ),
                    ),
                  ),
                  if (_expiryDate != _detectedExpiry)
                    Button.ghost(
                      onPressed: () =>
                          setState(() => _expiryDate = _detectedExpiry),
                      child: const Text('Use date'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _DateTile(
            label: 'Issue date (optional)',
            value:
                _issueDate == null ? null : dateFormat.format(_issueDate!),
            onTap: () => _pickDate(isExpiry: false),
            onClear: _issueDate == null
                ? null
                : () => setState(() => _issueDate = null),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Owner and private details'),
          const SizedBox(height: 10),
          Select<String>(
            value: profiles.any((p) => p.id == _profileId)
                ? _profileId
                : Profile.selfId,
            placeholder: const Text('Belongs to'),
            onChanged: (value) {
              if (value != null) setState(() => _profileId = value);
            },
            itemBuilder: (context, value) {
              final profile =
                  profiles.where((p) => p.id == value).firstOrNull;
              return Text('${profile?.avatarEmoji ?? ''} ${profile?.name ?? ''}'
                  .trim());
            },
            popup: (context) => SelectPopup(
              items: SelectItemList(
                children: [
                  for (final p in profiles)
                    SelectItemButton(
                      value: p.id,
                      child: Text('${p.avatarEmoji ?? ''} ${p.name}'.trim()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _idNumberController,
            placeholder: const Text('ID number (optional)'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            placeholder: const Text('Notes (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Reminders'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remind me before it expires'),
                    const SizedBox(height: 4),
                    Text(
                      _reminderSummary(),
                      style: Theme.of(context).typography.small.copyWith(
                            color: Theme.of(context).colorScheme.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _remindersEnabled,
                onChanged: (value) =>
                    setState(() => _remindersEnabled = value),
              ),
            ],
          ),
          if (_remindersEnabled) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in _reminderOptions)
                  GestureDetector(
                    onTap: () =>
                        _toggleReminderDay(days, !_reminderDays.contains(days)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _reminderDays.contains(days)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.muted,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _reminderDays.contains(days)
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.muted,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        days == 1 ? '1 day' : '$days days',
                        style: Theme.of(context).typography.small.copyWith(
                              color: _reminderDays.contains(days)
                                  ? Theme.of(context).colorScheme.foreground
                                  : Theme.of(context).colorScheme.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose at least one reminder. Documents are alerted at 9:00 AM on each selected day before expiry.',
              style: Theme.of(context).typography.small.copyWith(
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: Button.primary(
                onPressed: _isSaving ? null : _save,
                leading: const Icon(LucideIcons.check),
                child: Text(_isEditing ? 'Save changes' : 'Save document'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.medium.copyWith(
                    color: theme.colorScheme.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context)
            .typography
            .small
            .copyWith(fontWeight: FontWeight.w700),
      );
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.imagePaths,
    required this.maxPhotos,
    required this.slotLabels,
    required this.isBusy,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onPreviewPhoto,
  });

  final List<String> imagePaths;
  final int maxPhotos;
  final List<String> slotLabels;
  final bool isBusy;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<int> onPreviewPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canAddMore = imagePaths.length < maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.lock, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Photos (${imagePaths.length}/$maxPhotos) · AES-256 encrypted on device',
                style: theme.typography.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (imagePaths.isEmpty)
          Button.outline(
            onPressed: isBusy ? null : onAddPhoto,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: scheme.muted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.muted),
              ),
              child: Center(
                child: isBusy
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.imagePlus,
                            size: 36,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan or upload document photo (Front / Back)',
                            style: TextStyle(color: scheme.mutedForeground),
                          ),
                        ],
                      ),
              ),
            ),
          )
        else
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < imagePaths.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _PhotoThumbnailTile(
                      storedPath: imagePaths[i],
                      label:
                          i < slotLabels.length ? slotLabels[i] : 'Page ${i + 1}',
                      onTap: () => onPreviewPhoto(i),
                      onRemove: () => onRemovePhoto(i),
                    ),
                  ),
                if (canAddMore)
                  Button.outline(
                    onPressed: isBusy ? null : onAddPhoto,
                    child: Container(
                      width: 112,
                      decoration: BoxDecoration(
                        color: scheme.muted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.muted),
                      ),
                      child: Center(
                        child: isBusy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.imagePlus,
                                      color: scheme.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    imagePaths.length < slotLabels.length
                                        ? 'Add ${slotLabels[imagePaths.length]}'
                                        : 'Add photo',
                                    style: theme.typography.xSmall.copyWith(
                                      color: scheme.foreground,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnailTile extends StatelessWidget {
  const _PhotoThumbnailTile({
    required this.storedPath,
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String storedPath;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: '$label encrypted document photo. Open preview.',
            child: GestureDetector(
              onTap: onTap,
              child: EncryptedImageView(
                storedPath: storedPath,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Semantics(
              label: 'Remove photo',
              button: true,
              child: Tooltip(
                tooltip: (_) => const TooltipContainer(child: Text('Remove photo')),
                child: IconButton.destructive(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: onRemove,
                  shape: ButtonShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Button.outline(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.muted),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).typography.xSmall.copyWith(
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Tap to choose',
                    style: Theme.of(context).typography.medium,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton.ghost(
                icon: const Icon(LucideIcons.x),
                onPressed: onClear,
              )
            else
              const Icon(LucideIcons.calendarDays),
          ],
        ),
      ),
    );
  }
}
