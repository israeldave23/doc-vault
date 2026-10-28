import 'package:flutter/material.dart';
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

  final _formKey = GlobalKey<FormState>();
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
  bool _didSave = false;
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
  }

  @override
  void dispose() {
    if (!_didSave && _sessionAddedPaths.isNotEmpty) {
      // Discard encrypted files created during an aborted add/edit session.
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

  List<int> _sortedReminderDays() => List<int>.of(_reminderDays)
    ..sort((a, b) => b.compareTo(a));

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

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('Capture and crop with camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Pick an existing image and crop'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

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
      if (result == null || !mounted) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add photo: $e')),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
      helpText: isExpiry ? 'Expiry date' : 'Issue date',
    );
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
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an expiry date')),
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

    _didSave = true;
    await ref.read(documentsProvider.notifier).upsert(document);
    if (!mounted) return;

    if (_remindersEnabled) {
      // Explain and request notification permission only now that the user
      // actually saved something with reminders on.
      final granted = await ref
          .read(reminderServiceProvider)
          .ensurePermission(context);
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit document' : 'Add document'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PhotosSection(
              imagePaths: _imagePaths,
              maxPhotos: _maxPhotos,
              slotLabels: _slotLabels,
              isBusy: _isCapturingPhoto,
              onAddPhoto: _showPhotoSourceSheet,
              onRemovePhoto: _removePhotoAt,
              onPreviewPhoto: (index) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Philippine Passport',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in DocumentCategory.all)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label),
                    selected: _categoryKey == c.key,
                    onSelected: (_) => setState(() => _categoryKey = c.key),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
                      Icons.auto_awesome,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _expiryDate == _detectedExpiry
                            ? 'Detected from photo — ${dateFormat.format(_detectedExpiry!)}'
                            : 'Detected from photo: ${dateFormat.format(_detectedExpiry!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (_expiryDate != _detectedExpiry)
                      TextButton(
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
              value: _issueDate == null ? null : dateFormat.format(_issueDate!),
              onTap: () => _pickDate(isExpiry: false),
              onClear: _issueDate == null
                  ? null
                  : () => setState(() => _issueDate = null),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: profiles.any((p) => p.id == _profileId)
                  ? _profileId
                  : Profile.selfId,
              decoration: const InputDecoration(labelText: 'Belongs to'),
              items: [
                for (final p in profiles)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.avatarEmoji ?? ''} ${p.name}'.trim()),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _profileId = value);
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'ID number (optional)',
                helperText: 'Only the last 4 characters are shown in lists',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me before it expires'),
              subtitle: Text(_reminderSummary()),
              value: _remindersEnabled,
              onChanged: (value) => setState(() => _remindersEnabled = value),
            ),
            if (_remindersEnabled) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in _reminderOptions)
                    FilterChip(
                      label: Text(days == 1 ? '1 day' : '$days days'),
                      selected: _reminderDays.contains(days),
                      onSelected: (selected) =>
                          setState(() => _toggleReminderDay(days, selected)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose at least one reminder. Documents are alerted at 9:00 AM on each selected day before expiry.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Save changes' : 'Save document'),
            ),
          ],
        ),
      ),
    );
  }
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
            Icon(Icons.lock_outline, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Photos (${imagePaths.length}/$maxPhotos) · AES-256 encrypted on device',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (imagePaths.isEmpty)
          InkWell(
            onTap: isBusy ? null : onAddPhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Center(
                child: isBusy
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan or upload document photo (Front / Back)',
                            style: TextStyle(color: scheme.onSurfaceVariant),
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
                      label: i < slotLabels.length
                          ? slotLabels[i]
                          : 'Page ${i + 1}',
                      onTap: () => onPreviewPhoto(i),
                      onRemove: () => onRemovePhoto(i),
                    ),
                  ),
                if (canAddMore)
                  InkWell(
                    onTap: isBusy ? null : onAddPhoto,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 112,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Center(
                        child: isBusy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    imagePaths.length < slotLabels.length
                                        ? 'Add ${slotLabels[imagePaths.length]}'
                                        : 'Add photo',
                                    style: theme.textTheme.labelMedium,
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
          GestureDetector(
            onTap: onTap,
            child: EncryptedImageView(
              storedPath: storedPath,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value ?? 'Tap to choose'),
      ),
    );
  }
}
