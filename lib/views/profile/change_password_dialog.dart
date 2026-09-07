import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

/// Modal dialog allowing authenticated users to change their password.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentController.text.trim(),
      newPassword: _newController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = auth.errorMessage ?? 'Failed to update password. Check current password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final inputFill = isDark ? const Color(0xFF282832) : AppColors.scaffold;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.key, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Current Password ──────────────────────────────────────
                Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter current password',
                    hintStyle: TextStyle(color: textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Iconsax.eye_slash : Iconsax.eye, size: 18, color: textGrey),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter current password' : null,
                ),
                const SizedBox(height: 14),

                // ── New Password ──────────────────────────────────────────
                Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    hintStyle: TextStyle(color: textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Iconsax.eye_slash : Iconsax.eye, size: 18, color: textGrey),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Confirm New Password ──────────────────────────────────
                Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Re-enter new password',
                    hintStyle: TextStyle(color: textGrey, fontSize: 13),
                    filled: true,
                    fillColor: inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Iconsax.eye_slash : Iconsax.eye, size: 18, color: textGrey),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) {
                    if (val != _newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Buttons ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: textGrey.withValues(alpha: 0.3)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: textGrey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
