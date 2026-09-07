import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

/// Screen allowing the user to edit their display name, bio, and avatar.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.displayName);
    _bioController = TextEditingController(text: auth.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pop(); // Close photo options sheet
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;

      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);
      final success = await auth.uploadProfilePhoto(file);

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to upload photo.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selection failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    Navigator.of(context).pop();
    setState(() => _isUploadingPhoto = true);
    final auth = context.read<AuthProvider>();
    await auth.removeProfilePhoto();
    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoOptions(BuildContext context, bool hasPhoto, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.gallery, color: AppColors.primary, size: 20),
                ),
                title: Text('Choose from Gallery', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.camera, color: AppColors.primary, size: 20),
                ),
                title: Text('Take Photo', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              if (hasPhoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: _removePhoto,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update profile.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final inputFill = isDark ? const Color(0xFF282832) : Colors.white;
    final photoUrl = auth.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar with edit badge ────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: _isUploadingPhoto
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : photoUrl.isNotEmpty
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _avatarFallback(auth),
                                    )
                                  : _avatarFallback(auth),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto
                              ? null
                              : () => _showPhotoOptions(context, photoUrl.isNotEmpty, isDark),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.camera, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isUploadingPhoto
                      ? null
                      : () => _showPhotoOptions(context, photoUrl.isNotEmpty, isDark),
                  child: const Text(
                    'Change Profile Photo',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Display Name ──────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Full Name',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textGrey),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: textDark, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(color: textGrey, fontSize: 14),
                    filled: true,
                    fillColor: inputFill,
                    prefixIcon: Icon(Iconsax.user, color: textGrey, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C38) : AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C38) : AppColors.divider),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Email (Read-Only) ─────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address (Read-only)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textGrey),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : AppColors.scaffold,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF2C2C38) : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.sms, color: textGrey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          auth.email,
                          style: TextStyle(color: textGrey, fontSize: 14),
                        ),
                      ),
                      Icon(Iconsax.lock, color: textGrey.withValues(alpha: 0.6), size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Bio ───────────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bio',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textGrey),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 160,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Share a little about your cooking journey, favorite cuisines, or tips…',
                    hintStyle: TextStyle(color: textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C38) : AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF2C2C38) : AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _avatarFallback(AuthProvider auth) {
    return Center(
      child: Text(
        auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
