import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';

class UsersManagementPage extends ConsumerStatefulWidget {
  const UsersManagementPage({super.key});

  @override
  ConsumerState<UsersManagementPage> createState() =>
      _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<UsersManagementPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated || !authState.user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access Denied',
          description: 'You do not have permission to view this page',
        ),
      );
    }

    final businessId = authState.user.businessId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddUserDialog(context, ref, authState.user),
            tooltip: 'Add Staff Member',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search users…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('businessId', isEqualTo: businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Error loading users',
                    description: snapshot.error.toString(),
                  );
                }
                if (!snapshot.hasData) {
                  return const ShimmerList(count: 4, itemHeight: 80);
                }

                final docs = snapshot.data!.docs;
                final users = docs
                    .map(
                      (d) =>
                          UserEntity.fromMap(d.data() as Map<String, dynamic>),
                    )
                    .where((u) {
                      if (_searchQuery.isEmpty) return true;
                      final q = _searchQuery.toLowerCase();
                      return u.displayName.toLowerCase().contains(q) ||
                          u.email.toLowerCase().contains(q);
                    })
                    .toList();

                if (users.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: _searchQuery.isEmpty
                        ? 'No staff members yet'
                        : 'No results for "$_searchQuery"',
                    description: _searchQuery.isEmpty
                        ? 'Tap + to add your first staff member'
                        : 'Try a different name or email',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final user = users[i];
                    return _UserCard(
                      user: user,
                      isSelf: user.id == authState.user.id,
                      onEdit: () => _showEditDialog(context, ref, user),
                      onDelete: () => _showDeleteConfirm(context, ref, user),
                    ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.05);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Add user dialog ─────────────────────────────────────────────────────
  void _showAddUserDialog(
    BuildContext context,
    WidgetRef ref,
    UserEntity admin,
  ) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    var role = UserRole.user;
    var loading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.person_add_rounded,
                color: ViberantColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Add Staff Member',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Role selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: UserRole.values.map((r) {
                      final active = role == r;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setS(() => role = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? ViberantColors.primary : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r == UserRole.admin ? 'Admin' : 'Employee',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : ViberantColors.outline,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => loading = true);
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .createUserAccount(
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text,
                              displayName: nameCtrl.text.trim(),
                              businessId: admin.businessId,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Staff member added successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: ViberantColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setS(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit role dialog ────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context, WidgetRef ref, UserEntity user) {
    var role = user.role;
    var loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            'Edit: ${user.displayName}',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(name: user.displayName, radius: 28),
              const SizedBox(height: 12),
              Text(
                user.email,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: ViberantColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Role',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.outline,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: UserRole.values.map((r) {
                    final active = role == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() => role = r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? ViberantColors.primary : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r == UserRole.admin ? 'Admin' : 'Employee',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : ViberantColors.outline,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setS(() => loading = true);
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .updateUserRole(user.id, role);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: ViberantColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setS(() => loading = false);
                      }
                    },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────────────────
  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: ViberantColors.error,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Remove Staff Member',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                text: user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' from your team? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('User removed')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: ViberantColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─── User card ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserEntity user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final joinDate = DateFormat('d MMM yyyy').format(user.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ViberantColors.primary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          AppAvatar(name: user.displayName, radius: 22),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    StatusChip.role(user.isAdmin),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ViberantColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: ViberantColors.info,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ViberantColors.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined $joinDate',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: ViberantColors.outline,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: ViberantColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Edit Role', style: GoogleFonts.inter(fontSize: 13)),
                  ],
                ),
              ),
              if (!isSelf)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: ViberantColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remove',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ViberantColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}
