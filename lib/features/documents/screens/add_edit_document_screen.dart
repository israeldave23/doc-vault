import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/categories.dart';
import '../../profiles/models/profile.dart';
import '../../profiles/providers/profile_providers.dart';
import '../models/document.dart';
import '../providers/document_providers.dart';

/// Create a new document or edit an existing one (pass [existing]).
class AddEditDocumentScreen extends ConsumerStatefulWidget {
  const AddEditDocumentScreen({super.key, this.existing});

  final Document? existing;

  @override
  ConsumerState<AddEditDocumentScreen> createState() => _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends ConsumerState<AddEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _notesController;

  late String _categoryKey;
  late String _profileId;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  late bool _remindersEnabled;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.existing;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _idNumberController = TextEditingController(text: doc?.idNumber ?? '');
    _notesController = TextEditingController(text: doc?.notes ?? '');
    _categoryKey = doc?.category ?? DocumentCategory.passport.key;
    _profileId = doc?.profileId ?? Profile.selfId;
    _issueDate = doc?.issueDate;
    _expiryDate = doc?.expiryDate;
    _remindersEnabled = doc?.remindersEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _idNumberController.dispose();
    _notesController.dispose();
    super.dispose();
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
            notes: notes.isEmpty ? null : notes,
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
            notes: notes.isEmpty ? null : notes,
            remindersEnabled: _remindersEnabled,
          );

    await ref.read(documentsProvider.notifier).upsert(document);
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
            // Week 2 will replace this with the camera capture button.
            _PhotoPlaceholder(onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo capture arrives in Week 2')),
              );
            }),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Philippine Passport'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
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
            const SizedBox(height: 12),
            _DateTile(
              label: 'Issue date (optional)',
              value: _issueDate == null ? null : dateFormat.format(_issueDate!),
              onTap: () => _pickDate(isExpiry: false),
              onClear: _issueDate == null ? null : () => setState(() => _issueDate = null),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: profiles.any((p) => p.id == _profileId) ? _profileId : Profile.selfId,
              decoration: const InputDecoration(labelText: 'Belongs to'),
              items: [
                for (final p in profiles)
                  DropdownMenuItem(value: p.id, child: Text('${p.avatarEmoji ?? ''} ${p.name}'.trim())),
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
              subtitle: const Text('90, 30, 7 and 1 day before'),
              value: _remindersEnabled,
              onChanged: (value) => setState(() => _remindersEnabled = value),
            ),
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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 36, color: scheme.primary),
            const SizedBox(height: 8),
            Text('Add photo of document', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap, this.onClear});

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
