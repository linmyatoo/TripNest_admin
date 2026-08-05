// lib/src/features/profile/personal_data_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';

class PersonalDataPage extends StatefulWidget {
  static const route = '/personal-data';
  const PersonalDataPage({super.key});

  @override
  State<PersonalDataPage> createState() => _PersonalDataPageState();
}

class _PersonalDataPageState extends State<PersonalDataPage> {
  final organizationNameCtrl = TextEditingController();
  final contactNumberCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  final _picker = ImagePicker();
  final _apiService = ApiService();
  File? _avatar; // local preview image
  static const int _maxBytes = 1024 * 1024; // 1 MB
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getOrganizerProfile();

      if (result['success']) {
        final data = result['data'];

        setState(() {
          organizationNameCtrl.text = data['organizationName'] != 'Not Set'
              ? data['organizationName'] ?? ''
              : '';
          contactNumberCtrl.text = data['contactNumber'] != 'Not Set'
              ? data['contactNumber'] ?? ''
              : '';
          addressCtrl.text =
              data['address'] != 'Not Set' ? data['address'] ?? '' : '';
          _isLoading = false;
        });
      } else {
        _snack('Failed to load profile: ${result['message']}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _snack('Error loading profile');
      setState(() => _isLoading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final result = await _apiService.createOrganizerProfile(
        organizationName: organizationNameCtrl.text.trim(),
        contactNumber: contactNumberCtrl.text.trim(),
        address: addressCtrl.text.trim(),
      );

      setState(() => _isSaving = false);

      if (result['success']) {
        _snack('Profile saved successfully');
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _snack(result['message'] ?? 'Failed to save profile');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _snack('Error saving profile');
    }
  }

  // ---------- Image compression (≤ 1 MB), pure Dart ----------
  Future<File?> _ensureUnder1MB(File file) async {
    Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes <= _maxBytes) return file;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      _snack('Couldn’t read that image. Please choose a different file.');
      return null;
    }

    int quality = 85;
    int width = decoded.width;
    int height = decoded.height;
    img.Image current = decoded;

    Future<File> write(Uint8List data) async {
      final dir = await getTemporaryDirectory();
      final path = p.join(
          dir.path, 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final out = File(path);
      await out.writeAsBytes(data, flush: true);
      return out;
    }

    while (true) {
      final encoded =
          Uint8List.fromList(img.encodeJpg(current, quality: quality));
      if (encoded.lengthInBytes <= _maxBytes) {
        return write(encoded);
      }

      if (quality > 50) {
        quality -= 10; // 85 -> 75 -> 65 -> 55 -> 50
      } else {
        // start downscaling in 85% steps
        final newW = (width * 0.85).round();
        final newH = (height * 0.85).round();
        if (newW < 500 || newH < 500) break; // keep a reasonable minimum
        width = newW;
        height = newH;
        current = img.copyResize(decoded,
            width: width,
            height: height,
            interpolation: img.Interpolation.average);
      }

      if (quality < 35 && (width < 600 || height < 600)) break; // safety
    }

    _snack('Couldn’t keep the photo under 1MB. Please choose a smaller one.');
    return null;
  }

  Future<void> _showAvatarPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('Change profile photo',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    final x = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 100,
                      maxWidth: 4096,
                    );
                    if (x != null) {
                      final compressed = await _ensureUnder1MB(File(x.path));
                      if (compressed != null) {
                        setState(() => _avatar = compressed);
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    final x = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 100,
                      maxWidth: 4096,
                    );
                    if (x != null) {
                      final compressed = await _ensureUnder1MB(File(x.path));
                      if (compressed != null) {
                        setState(() => _avatar = compressed);
                      }
                    }
                    if (mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatar != null
        ? FileImage(_avatar!)
        : const AssetImage('assets/images/avatar_jacob.jpg') as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Organizer Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                            radius: 52, backgroundImage: avatarProvider),
                        // Pencil button at bottom-right
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showAvatarPickerSheet,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.edit,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Organization Name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Enter organization name',
                    controller: organizationNameCtrl,
                  ),
                  const SizedBox(height: 16),
                  const Text('Contact Number',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Enter contact number',
                    controller: contactNumberCtrl,
                    keyboardType: TextInputType.phone,
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/images/flag_th.png',
                            width: 22, height: 22),
                        const SizedBox(width: 8),
                        const Text('+66',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const VerticalDivider(width: 1.0, thickness: 1.0),
                        const SizedBox(width: 4),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint: 'Enter address',
                    controller: addressCtrl,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ),
    );
  }
}
