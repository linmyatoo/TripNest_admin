import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/dropdown_form_field.dart';

class CreateEventPage extends StatefulWidget {
  static const route = '/create-event';
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final nameCtrl = TextEditingController();
  final seatCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  String? category;
  final List<String> categories = const [
    'Relaxed',
    'Excited',
    'Adventurous',
    'Romance',
    'Energetic',
    'Cultural',
    'Fun'
  ];

  final _picker = ImagePicker();
  final List<File> _photos = []; // each ≤ 1MB
  static const int _maxBytes = 1024 * 1024;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      dateCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _addFromGallery() async {
    final XFile? x = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 100, maxWidth: 4096);
    if (x == null) return;
    final f = await _ensureUnder1MB(File(x.path));
    if (f != null) setState(() => _photos.add(f));
  }

  Future<void> _addFromCamera() async {
    final XFile? x = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 100, maxWidth: 4096);
    if (x == null) return;
    final f = await _ensureUnder1MB(File(x.path));
    if (f != null) setState(() => _photos.add(f));
  }

  void _removePhoto(int i) => setState(() => _photos.removeAt(i));

  /// Ensure picked image ≤ 1MB (pure Dart compression to avoid CocoaPods issues)
  Future<File?> _ensureUnder1MB(File file) async {
    Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes <= _maxBytes) return file;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _showSnack('Couldn’t read that image. Please choose a different file.');
      return null;
    }

    int quality = 85;
    int width = decoded.width;
    int height = decoded.height;
    img.Image current = decoded;

    Future<File> _writeOut(Uint8List data) async {
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
        return _writeOut(encoded);
      }

      if (quality > 50) {
        quality -= 10;
      } else {
        final newW = (width * 0.85).round();
        final newH = (height * 0.85).round();
        if (newW < 600 || newH < 600) break;
        width = newW;
        height = newH;
        current = img.copyResize(decoded,
            width: width,
            height: height,
            interpolation: img.Interpolation.average);
      }

      if (quality < 35 && (width < 700 || height < 700)) break;
    }

    _showSnack(
        'Couldn’t keep the photo under 1MB. Please choose a smaller one.');
    return null;
  }

  String _prettySize(File f) {
    final b = f.lengthSync();
    if (b < 1024) return '${b} B';
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
        title: const Text('Create your event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Event Name',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // (keeping Figma text)
          AppTextField(hint: 'Your enent name', controller: nameCtrl),

          const SizedBox(height: 16),
          const Text('Catagory', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          WhiteDropdownFormField<String>(
            value: category,
            hint: const Text('Mood'),
            decoration:
                const InputDecoration(), // picks up global white+outline
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => category = v),
          ),

          const SizedBox(height: 16),
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Max 1MB each',
              style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
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
          AppTextField(hint: 'Seat', controller: seatCtrl),

          const SizedBox(height: 16),
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
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
          const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
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
            decoration: const InputDecoration(hintText: 'Description'),
          ),

          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Create event',
            onPressed: () {
              // TODO: send form + _photos to backend
              _showSnack('Event created (mock). Photos: ${_photos.length}');
            },
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
