import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/incident_category.dart';
import '../../providers/incident_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_error_message.dart';
import '../../utils/validators.dart';
import '../../widgets/category_selector.dart';

const kCampusBuildings = [
  'Social Commons',
  'Enterprise Commons',
  'Leadership Block',
];

String composeIncidentLocation(String building, String? roomName) {
  final room = roomName?.trim() ?? '';
  return room.isEmpty ? building : '$building — $room';
}

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _roomName = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  bool _categoryError = false;
  bool _buildingError = false;
  XFile? _photo;
  String? _selectedBuilding;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _roomName.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
      if (x == null) return;
      if (await x.length() >= 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo must be smaller than 5 MB. Choose a smaller image.',
            ),
          ),
        );
        return;
      }
      if (mounted) setState(() => _photo = x);
    } on PlatformException catch (error) {
      debugPrint('Could not open incident photo source: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not access that photo source. Check permissions.'),
        ),
      );
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    setState(() => _buildingError = _selectedBuilding == null);
    if (!formOk || _category == null || _selectedBuilding == null) return;

    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      await provider.submit(
        title: _title.text,
        description: _description.text,
        category: _category!,
        location: composeIncidentLocation(_selectedBuilding!, _roomName.text),
        photo: _photo,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Report submission failed: $error\n$stackTrace');
      if (!mounted) return;
      final message = error is FirebaseException
          ? firebaseErrorMessage(error, action: 'save the report')
          : error is FormatException
              ? error.message
              : error is StateError
                  ? error.message
                  : error is Exception
                      ? error.toString().replaceFirst('Exception: ', '')
                      : 'Could not submit the report. Please try again.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Report submitted. Thank you!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final submitting = provider.isSubmitting;

    return PopScope(
      canPop: !submitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Report an Incident')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _Label('Select a category'),
                CategorySelector(
                  selected: _category,
                  errorText: _categoryError ? 'Please choose a category' : null,
                  onChanged: (c) => setState(() {
                    _category = c;
                    _categoryError = false;
                  }),
                ),
                const SizedBox(height: 20),
                const _Label('Title'),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Briefly describe the issue…',
                    counterText: '',
                  ),
                  validator: Validators.title,
                ),
                const SizedBox(height: 16),
                const _Label('Description'),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Provide more details about the issue… e.g. what happened, when, impact, etc.',
                  ),
                  validator: Validators.description,
                ),
                const SizedBox(height: 8),
                const _Label('Building'),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: kCampusBuildings.map((building) {
                    return ChoiceChip(
                      label: Text(building),
                      selected: _selectedBuilding == building,
                      onSelected: (selected) => setState(() {
                        _selectedBuilding = selected ? building : null;
                        _buildingError = false;
                      }),
                    );
                  }).toList(),
                ),
                if (_buildingError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      'Please choose a building',
                      style: TextStyle(color: AppColors.brick, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roomName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Room or area (optional)',
                    hintText: 'Type a room name or number',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                const _Label('Add a photo (optional)'),
                _PhotoPicker(
                  photo: _photo,
                  onPick: submitting ? null : _choosePhotoSource,
                  onRemove:
                      submitting ? null : () => setState(() => _photo = null),
                ),
                const SizedBox(height: 24),
                if (submitting && provider.uploadStage != null) ...[
                  LinearProgressIndicator(
                    value: provider.uploadProgress,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.uploadProgress == null
                        ? provider.uploadStage!
                        : '${provider.uploadStage!} '
                            '${(provider.uploadProgress! * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Submit Report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _PhotoPicker extends StatefulWidget {
  const _PhotoPicker(
      {required this.photo, required this.onPick, required this.onRemove});

  final XFile? photo;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  State<_PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<_PhotoPicker> {
  Future<Uint8List>? _photoBytes;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant _PhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo?.path != widget.photo?.path) _loadPhoto();
  }

  void _loadPhoto() {
    _photoBytes = widget.photo?.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder(
              future: _photoBytes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onRemove,
            ),
          ),
        ],
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.onPick,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.textSecondary, size: 30),
            SizedBox(height: 6),
            Text('Tap to add photos',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
