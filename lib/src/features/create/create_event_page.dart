import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/services/api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/dropdown_form_field.dart';

class CreateEventPage extends StatefulWidget {
  static const route = '/create-event';
  final String? eventId;
  const CreateEventPage({super.key, this.eventId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final nameCtrl = TextEditingController();
  final seatCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isFetchingEvent = false;

  bool get _isEditMode => widget.eventId != null;

  String? category;
  // Must match the backend's Mood enum exactly (mood.categorizer.ts) —
  // isValidMood() rejects anything outside these values, case-sensitive.
  static const Map<String, String> _moodLabels = {
    'FESTIVE': 'Festive',
    'CHILL': 'Chill',
    'ENERGETIC': 'Energetic',
    'ROMANTIC': 'Romantic',
    'ADVENTUROUS': 'Adventurous',
    'CULTURAL': 'Cultural',
    'PARTY': 'Party',
    'RELAXED': 'Relaxed',
    'EDUCATIONAL': 'Educational',
    'SPIRITUAL': 'Spiritual',
  };
  final List<String> categories = const [
    'FESTIVE',
    'CHILL',
    'ENERGETIC',
    'ROMANTIC',
    'ADVENTUROUS',
    'CULTURAL',
    'PARTY',
    'RELAXED',
    'EDUCATIONAL',
    'SPIRITUAL',
  ];

  final _picker = ImagePicker();
  final List<File> _photos = []; // each ≤ 300KB
  static const int _maxBytes = 300 * 1024; // 300KB to fit nginx limit
  bool _isPickingImage = false; // Prevent multiple simultaneous picks
  List<String> _existingImageUrls = []; // URLs of already uploaded images

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _fetchEventData();
    }
  }

  Future<void> _fetchEventData() async {
    setState(() => _isFetchingEvent = true);

    final result = await _apiService.getEventById(widget.eventId!);

    if (mounted) {
      if (!result['success']) {
        _showSnack(
          result['message'] ??
              'Failed to load event. It may still be pending approval.',
          isError: true,
        );
      }
      setState(() {
        _isFetchingEvent = false;
        if (result['success']) {
          final event = result['event'] as Map<String, dynamic>;
          nameCtrl.text = event['title'] ?? '';
          descCtrl.text = event['description'] ?? '';
          locationCtrl.text = event['location'] ?? '';
          seatCtrl.text = (event['capacity'] ?? '').toString();
          priceCtrl.text = (event['price'] ?? '').toString();
          final eventMood = event['mood'] as String?;
          category = categories.contains(eventMood) ? eventMood : null;

          // Parse date from ISO format
          final dateStr = event['date'] as String?;
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              dateCtrl.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (_) {}
          }

          // Store existing image URLs
          final images = event['images'] as List?;
          if (images != null) {
            _existingImageUrls = images
                .map((e) =>
                    e is Map ? e['imageUrl']?.toString() ?? '' : e.toString())
                .where((url) => url.isNotEmpty)
                .toList();
          }
        }
      });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _createEvent() async {
    // Validation
    final name = nameCtrl.text.trim();
    final location = locationCtrl.text.trim();
    final date = dateCtrl.text.trim();
    final seatText = seatCtrl.text.trim();
    final priceText = priceCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter event name', isError: true);
      return;
    }
    if (date.isEmpty) {
      _showSnack('Please select a date', isError: true);
      return;
    }
    if (location.isEmpty) {
      _showSnack('Please enter location', isError: true);
      return;
    }
    if (seatText.isEmpty) {
      _showSnack('Please enter available seats', isError: true);
      return;
    }
    if (priceText.isEmpty) {
      _showSnack('Please enter price', isError: true);
      return;
    }

    final capacity = int.tryParse(seatText);
    if (capacity == null || capacity <= 0) {
      _showSnack('Please enter a valid seat number', isError: true);
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      _showSnack('Please enter a valid price', isError: true);
      return;
    }

    // Convert date to ISO format (add time component)
    final isoDate = '${date}T00:00:00.000Z';

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditMode) {
      // Update existing event
      result = await _apiService.updateEvent(
        eventId: widget.eventId!,
        title: name,
        description: description.isNotEmpty ? description : null,
        date: isoDate,
        location: location,
        capacity: capacity,
        price: price,
        mood: category,
      );
    } else {
      // Create new event
      result = await _apiService.createEvent(
        title: name,
        description: description.isNotEmpty ? description : null,
        date: isoDate,
        location: location,
        capacity: capacity,
        price: price,
        mood: category,
        images: _photos.isNotEmpty ? _photos : null,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      // Show native device notification and save to feed
      await NotificationService.addNotification(
        title: _isEditMode
            ? 'Event Updated Successfully'
            : 'Event Created Successfully',
        body:
            '"$name" has been ${_isEditMode ? 'updated' : 'published'}. Location: $location',
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
      }
    } else {
      _showSnack(
          result['message'] ??
              'Failed to ${_isEditMode ? 'update' : 'create'} event',
          isError: true);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 10, 12, 31);
    var initial = DateTime.tryParse(dateCtrl.text) ?? now;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearDatePickerDialog(
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
    if (picked != null) {
      dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _addFromGallery() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final List<XFile> files =
          await _picker.pickMultiImage(imageQuality: 100, maxWidth: 4096);
      if (files.isEmpty) return;
      for (final x in files) {
        final f = await _ensureUnderLimit(File(x.path));
        if (f != null) {
          setState(() => _photos.add(f));
        }
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _addFromCamera() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? x = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 100, maxWidth: 4096);
      if (x == null) return;
      final f = await _ensureUnderLimit(File(x.path));
      if (f != null) setState(() => _photos.add(f));
    } finally {
      _isPickingImage = false;
    }
  }

  void _removePhoto(int i) => setState(() => _photos.removeAt(i));

  /// Ensure picked image ≤ 1MB (pure Dart compression to avoid CocoaPods issues)
  Future<File?> _ensureUnderLimit(File file) async {
    Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes <= _maxBytes) return file;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _showSnack('Cannot read image. Please choose a different file.');
      return null;
    }

    int quality = 60;
    int width = decoded.width;
    int height = decoded.height;
    img.Image current = decoded;

    // Pre-resize if image is large
    if (width > 1000 || height > 1000) {
      final scale = 1000 / (width > height ? width : height);
      width = (width * scale).round();
      height = (height * scale).round();
      current = img.copyResize(decoded,
          width: width,
          height: height,
          interpolation: img.Interpolation.average);
    }

    Future<File> writeOut(Uint8List data) async {
      final dir = await getTemporaryDirectory();
      final path =
          p.join(dir.path, 'tn_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final out = File(path);
      await out.writeAsBytes(data, flush: true);
      return out;
    }

    while (true) {
      final encoded =
          Uint8List.fromList(img.encodeJpg(current, quality: quality));
      if (encoded.lengthInBytes <= _maxBytes) {
        return writeOut(encoded);
      }

      if (quality > 30) {
        quality -= 10;
      } else {
        final newW = (width * 0.75).round();
        final newH = (height * 0.75).round();
        if (newW < 300 || newH < 300) break;
        width = newW;
        height = newH;
        current = img.copyResize(current,
            width: width,
            height: height,
            interpolation: img.Interpolation.average);
        quality = 45;
      }

      if (quality < 25 && (width < 400 || height < 400)) break;
    }

    _showSnack('Photo is too large. Please choose a smaller image.');
    return null;
  }

  String _prettySize(File f) {
    final b = f.lengthSync();
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false),
        ),
        title: Text(_isEditMode ? 'Edit your event' : 'Create your event'),
      ),
      body: _isFetchingEvent
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Event Name',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // (keeping Figma text)
                    AppTextField(hint: 'Your event name', controller: nameCtrl),

                    const SizedBox(height: 16),
                    const Text('Category',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    WhiteDropdownFormField<String>(
                      value: category,
                      hint: const Text('Mood'),
                      decoration:
                          const InputDecoration(), // picks up global white+outline
                      items: categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(_moodLabels[c] ?? c)))
                          .toList(),
                      onChanged: (v) => setState(() => category = v),
                    ),

                    const SizedBox(height: 16),
                    const Text('Photos',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      _isEditMode
                          // PATCH /events/:id carries no image payload, so the
                          // picker is hidden here rather than silently
                          // discarding whatever the organizer selects.
                          ? 'Photos cannot be changed while editing'
                          : 'Max 300KB each (auto-compressed)',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    // Show existing images if editing
                    if (_existingImageUrls.isNotEmpty) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _existingImageUrls
                            .map((url) => _ExistingImageTile(imageUrl: url))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!_isEditMode)
                      _PhotoGrid(
                        photos: _photos,
                        sizeLabelFor: _prettySize,
                        onRemove: _removePhoto,
                        onAddGallery: _addFromGallery,
                        onAddCamera: _addFromCamera,
                      ),

                    const SizedBox(height: 16),
                    const Text('Available seat',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    AppTextField(
                      hint: 'Enter number of seats',
                      controller: seatCtrl,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),
                    const Text('Price',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    AppTextField(
                      hint: 'Enter ticket price',
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 16),
                    const Text('Date',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        hintText: 'Choose the date',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Location',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Choose the location',
                        suffixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Description',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(hintText: 'Description'),
                    ),

                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _isLoading
                          ? (_isEditMode ? 'Updating...' : 'Creating...')
                          : (_isEditMode ? 'Update event' : 'Create event'),
                      onPressed: _isLoading ? null : _createEvent,
                    ),
                  ]),
            ),
    );
  }
}

// ----------------------- Photo picking UI -----------------------

class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final void Function(int index) onRemove;
  final VoidCallback onAddGallery;
  final VoidCallback onAddCamera;
  final String Function(File) sizeLabelFor;

  const _PhotoGrid({
    required this.photos,
    required this.onRemove,
    required this.onAddGallery,
    required this.onAddCamera,
    required this.sizeLabelFor,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _AddTile(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          onTap: onAddGallery),
      _AddTile(
          icon: Icons.photo_camera_outlined,
          label: 'Camera',
          onTap: onAddCamera),
      ...List.generate(
        photos.length,
        (i) => _ThumbTile(
            file: photos[i],
            sizeText: sizeLabelFor(photos[i]),
            onDelete: () => onRemove(i)),
      ),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white, // ⬅️ now white
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFD1D5DB)), // match text fields
          boxShadow: const [
            BoxShadow(
              // subtle lift (optional)
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF121212)),
            const SizedBox(height: 6),
            const Text('',
                style: TextStyle(fontSize: 12)), // keep spacing stable
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF121212))),
          ],
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  final File file;
  final String sizeText;
  final VoidCallback onDelete;
  const _ThumbTile(
      {required this.file, required this.sizeText, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 96, height: 96, fit: BoxFit.cover),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(sizeText,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only thumbnail for an image already stored on the server.
///
/// There is no delete affordance: `PATCH /events/:id` accepts no image
/// payload, so removal cannot be persisted.
class _ExistingImageTile extends StatelessWidget {
  final String imageUrl;
  const _ExistingImageTile({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 96,
          height: 96,
          color: Colors.grey[200],
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }
}

class _MonthYearDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _MonthYearDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_MonthYearDatePickerDialog> createState() =>
      _MonthYearDatePickerDialogState();
}

class _MonthYearDatePickerDialogState
    extends State<_MonthYearDatePickerDialog> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _year;
  late int _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
  }

  DateTime get _gridDate {
    var date = DateTime(_year, _month, 1);
    if (date.isBefore(widget.firstDate)) date = widget.firstDate;
    if (date.isAfter(widget.lastDate)) date = widget.lastDate;
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var y = widget.firstDate.year; y <= widget.lastDate.year; y++) y,
    ];

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: WhiteDropdownFormField<int>(
                    value: _month,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                            value: m, child: Text(_monthNames[m - 1])),
                    ],
                    onChanged: (m) {
                      if (m == null) return;
                      setState(() => _month = m);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: WhiteDropdownFormField<int>(
                    value: _year,
                    items: [
                      for (final y in years)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (y) {
                      if (y == null) return;
                      setState(() => _year = y);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: CalendarDatePicker(
                key: ValueKey('$_year-$_month'),
                initialDate: _gridDate,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onDisplayedMonthChanged: (d) {
                  setState(() {
                    _year = d.year;
                    _month = d.month;
                  });
                },
                onDateChanged: (d) => _selected = d,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
