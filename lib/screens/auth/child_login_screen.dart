import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../widgets/avatar_widget.dart';
import 'package:provider/provider.dart';

/// Child login screen — shows child profile cards; tap → enter PIN
class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _pinController = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parent = context.read<AuthProvider>().parentUser;
      if (parent == null) {
        // A parent must be signed in on this device before a child can log in
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get(context, 'parentLoginRequired'))),
        );
        Navigator.pop(context);
        return;
      }
      context.read<ChildProvider>().listenToChildren(parent.id);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _selectChild(UserModel child) {
    setState(() {
      _pinController.clear();
      _pinError = null;
    });
    _showPinDialog(child);
  }

  Future<void> _showPinDialog(UserModel child) async {
    _pinController.clear();
    _pinError = null;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final authProvider = context.watch<AuthProvider>();
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            title: Column(
              children: [
                AvatarWidget(avatarIndex: child.avatarIndex, size: 80),
                const SizedBox(height: 16),
                Text(
                  '${AppStrings.get(context, 'hello')} ${child.name}! 👋',
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  AppStrings.get(context, 'enterPin'),
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 16,
                  ),
                  onChanged: (val) async {
                    if (val.length == 4 && !authProvider.isLoading) {
                      setDialogState(() => _pinError = null);
                      final success = await context.read<AuthProvider>().childLogin(
                        child.id,
                        val,
                      );

                      if (!mounted) return;

                      if (success) {
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context, '/child-home');
                      } else {
                        setDialogState(() => _pinError = AppStrings.get(context, 'wrongPin'));
                      }
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), letterSpacing: 16),
                    errorText: _pinError,
                    errorStyle: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.w700),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.primaryStrong, width: 2.5),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.get(context, 'cancel'),
                    style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        setDialogState(() => _pinError = null);
                        final success = await context.read<AuthProvider>().childLogin(
                          child.id,
                          _pinController.text.trim(),
                        );

                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(ctx);
                          Navigator.pushReplacementNamed(context, '/child-home');
                        } else {
                          setDialogState(() => _pinError = AppStrings.get(context, 'wrongPin'));
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStrong,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        AppStrings.get(context, 'letsPlay'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final children = childProvider.children;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [const Color(0xFFE0F7FA), const Color(0xFFE8EAF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryStrong),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.get(context, 'chooseHero'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Children grid
              Expanded(
                child: childProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStrong))
                    : children.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('😢', style: TextStyle(fontSize: 72))
                                    .animate()
                                    .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut),
                                const SizedBox(height: 24),
                                Text(
                                  AppStrings.get(context, 'noHeroes'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                            itemCount: children.length,
                            itemBuilder: (context, index) {
                              final child = children[index];
                              return GestureDetector(
                                onTap: () => _selectChild(child),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: AppColors.softShadow,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AvatarWidget(avatarIndex: child.avatarIndex, size: 90),
                                      const SizedBox(height: 16),
                                      Text(
                                        child.name,
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '🔒 ${AppStrings.get(context, 'tapToPlay')}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
