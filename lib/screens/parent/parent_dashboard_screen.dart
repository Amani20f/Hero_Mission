import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/child_summary_card.dart';
import '../../services/firestore_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parent = context.read<AuthProvider>().currentUser;
      if (parent != null) {
        context.read<ChildProvider>().listenToChildren(parent.id);
        context.read<TaskProvider>().listenToPendingApprovals(parent.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final childProvider = context.watch<ChildProvider>();
    final parent = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get(context, 'appName'),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.primaryStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              AppStrings.get(context, 'myHeroes'),
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.child_care, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            tooltip: AppStrings.get(context, 'iAmAChild'),
            onPressed: () => Navigator.pushNamed(context, '/child-login'),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            tooltip: AppStrings.get(context, 'settings'),
            onPressed: () => Navigator.pushNamed(context, '/parent-settings'),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            tooltip: AppStrings.get(context, 'signOut'),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: childProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStrong))
          : childProvider.children.isEmpty
              ? _buildEmptyState(context)
              : _buildChildrenList(context, childProvider.children),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChildDialog(context, parent!),
        backgroundColor: AppColors.primaryStrong,
        elevation: 4,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          AppStrings.get(context, 'addHero'),
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildChildrenList(BuildContext context, List<UserModel> children) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        final taskProvider = context.watch<TaskProvider>();
        final pendingCount = taskProvider.pendingApprovals
            .where((t) => t.childId == child.id)
            .length;

        return StreamBuilder(
          stream: FirestoreService().getProgressStream(child.id),
          builder: (context, snapshot) {
            return ChildSummaryCard(
              child: child,
              progress: snapshot.data,
              pendingApprovalsCount: pendingCount,
              onTap: () {
                context.read<ChildProvider>().selectChild(child);
                Navigator.pushNamed(context, '/child-progress', arguments: child);
              },
              onDelete: () => _confirmDeleteChild(context, child),
            ).animate(delay: (index * 80).ms).fadeIn(duration: 300.ms).slideX(
                  begin: -0.1,
                  end: 0,
                  curve: Curves.easeOut,
                );
          },
        );
      },
    );
  }

  void _confirmDeleteChild(BuildContext context, UserModel child) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(AppStrings.get(context, 'deleteHero'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        content: Text('${child.name}? ${AppStrings.get(context, 'deleteHeroConfirm')}', style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get(context, 'cancel'), style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ChildProvider>().deleteChild(child.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? AppStrings.get(context, 'deleteSuccess')
                        : AppStrings.get(context, 'deleteError')),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(AppStrings.get(context, 'delete'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👶', style: TextStyle(fontSize: 72))
              .animate()
              .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            AppStrings.get(context, 'noHeroesYet'),
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get(context, 'noHeroesHint'),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, UserModel parent) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    int selectedAvatar = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              AppStrings.get(context, 'addNewHero'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 22, color: Theme.of(context).colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: AppStrings.get(context, 'heroName'),
                      labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.person, color: AppColors.primaryStrong),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: AppStrings.get(context, 'pin4'),
                      labelStyle: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.lock, color: AppColors.primaryStrong),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get(context, 'chooseAvatar'),
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      8,
                      (i) => GestureDetector(
                        onTap: () => setDialogState(() => selectedAvatar = i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedAvatar == i ? AppColors.primaryStrong : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _buildAvatarPreview(i, selectedAvatar == i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.get(context, 'cancel'), style: GoogleFonts.cairo(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || pinController.text.trim().length != 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.get(context, 'pleaseFillFields'))),
                    );
                    return;
                  }

                  final child = await context.read<AuthProvider>().createChildAccount(
                        name: nameController.text.trim(),
                        pin: pinController.text.trim(),
                        avatarIndex: selectedAvatar,
                      );

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (child != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${child.name} ${AppStrings.get(context, 'heroReady')}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: Text(AppStrings.get(context, 'createHero'), style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarPreview(int index, bool selected) {
    const emojis = ['🦁', '🐼', '🐸', '🐯', '🦊', '🐧', '🦄', '🐻'];
    const colors = [
      Color(0xFFFF9800), Color(0xFF607D8B), Color(0xFF4CAF50),
      Color(0xFFF44336), Color(0xFFFF5722), Color(0xFF2196F3),
      Color(0xFF9C27B0), Color(0xFF795548),
    ];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[index],
        boxShadow: selected
            ? [BoxShadow(color: colors[index].withValues(alpha: 0.5), blurRadius: 8)]
            : [],
      ),
      child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 22))),
    );
  }
}
