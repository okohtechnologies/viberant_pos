// lib/presentation/pages/admin/users_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/viberant_card.dart';

// ─── Repository provider ───────────────────────────────────────────
final _authRepoProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class UsersManagementPage extends ConsumerWidget {
  const UsersManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(_authRepoProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Staff Management',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddUserSheet(context, ref, authState.user.businessId),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'Add Staff',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<UserEntity>>(
        stream: repo.getBusinessUsers(authState.user.businessId),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 6),
            );
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load staff',
              description: snapshot.error.toString(),
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No staff yet',
              description: 'Add staff members using the button below.',
            );
          }

          // Sort: admins first, then by name
          final sorted = [...users]
            ..sort((a, b) {
              if (a.isAdmin != b.isAdmin) {
                return a.isAdmin ? -1 : 1;
              }
              return a.displayName.compareTo(b.displayName);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _UserRow(
              user: sorted[i],
              isSelf: sorted[i].id == authState.user.id,
              onTap: () => _showUserDetailSheet(
                context,
                ref,
                sorted[i],
                authState.user.id,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserSheet(
    BuildContext context,
    WidgetRef ref,
    String businessId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddUserSheet(businessId: businessId, ref: ref),
    );
  }

  void _showUserDetailSheet(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
    String currentUserId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserDetailSheet(
        user: user,
        isSelf: user.id == currentUserId,
        ref: ref,
      ),
    );
  }
}

// ─── User row card ─────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final UserEntity user;
  final bool isSelf;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.isSelf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = user.role == UserRole.admin;

    return ViberantCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Stack(
            children: [
              AppAvatar(name: user.displayName, size: 44),
              if (!user.isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
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
                          color: user.isActive
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                            ViberantRadius.full,
                          ),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(ViberantRadius.full),
                ),
                child: Text(
                  isAdmin ? 'Admin' : 'Staff',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAdmin
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (!user.isActive)
                StatusChip.error(label: 'Inactive')
              else
                StatusChip.success(label: 'Active'),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ─── User detail / edit bottom sheet ───────────────────────────────
class _UserDetailSheet extends StatefulWidget {
  final UserEntity user;
  final bool isSelf;
  final WidgetRef ref;

  const _UserDetailSheet({
    required this.user,
    required this.isSelf,
    required this.ref,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late UserRole _selectedRole;
  late bool _isActive;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  bool get _hasChanges =>
      _selectedRole != widget.user.role || _isActive != widget.user.isActive;

  Future<void> _save() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repo = widget.ref.read(_authRepoProvider);

    try {
      // Update role if changed
      if (_selectedRole != widget.user.role) {
        await repo.updateUserRole(widget.user.id, _selectedRole);
      }
      // Update active status if changed
      if (_isActive != widget.user.isActive) {
        await repo.toggleUserActive(widget.user.id, _isActive);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Remove Staff Member',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove ${widget.user.displayName} from your business? '
          'This will delete their account and cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = widget.ref.read(_authRepoProvider);
      await repo.deleteUser(widget.user.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              AppAvatar(name: widget.user.displayName, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      widget.user.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button — not shown for self
              if (!widget.isSelf)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error,
                    size: 20,
                  ),
                  onPressed: _isSaving ? null : _delete,
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.errorContainer.withValues(
                      alpha: 0.4,
                    ),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Remove staff member',
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Error banner
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(ViberantRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Role selector
          Text(
            'Role',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RoleTile(
                  label: 'Staff',
                  description: 'POS access only',
                  icon: Icons.person_rounded,
                  isSelected: _selectedRole == UserRole.user,
                  // Can't demote yourself
                  isDisabled: widget.isSelf,
                  onTap: widget.isSelf
                      ? null
                      : () => setState(() => _selectedRole = UserRole.user),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleTile(
                  label: 'Admin',
                  description: 'Full access',
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: _selectedRole == UserRole.admin,
                  isDisabled: widget.isSelf,
                  onTap: widget.isSelf
                      ? null
                      : () => setState(() => _selectedRole = UserRole.admin),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Active toggle
          ViberantCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 20,
                  color: _isActive ? ViberantColors.success : scheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Active',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        _isActive
                            ? 'Staff member can sign in'
                            : 'Staff member cannot sign in',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  // Can't deactivate yourself
                  onChanged: widget.isSelf
                      ? null
                      : (v) => setState(() => _isActive = v),
                  activeColor: scheme.primary,
                ),
              ],
            ),
          ),

          if (widget.isSelf) ...[
            const SizedBox(height: 8),
            Text(
              'You cannot edit your own role or deactivate your own account.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasChanges
                    ? scheme.primary
                    : scheme.surfaceContainerHigh,
                foregroundColor: _hasChanges
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ViberantRadius.card),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                      ),
                    )
                  : Text(
                      _hasChanges ? 'Save Changes' : 'Done',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role selection tile ────────────────────────────────────────────
class _RoleTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _RoleTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ViberantRadius.card),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? scheme.primary
                  : isDisabled
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? scheme.primary
                    : isDisabled
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : scheme.onSurface,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDisabled
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.3)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add user sheet (unchanged from before) ────────────────────────
class _AddUserSheet extends StatefulWidget {
  final String businessId;
  final WidgetRef ref;

  const _AddUserSheet({required this.businessId, required this.ref});

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.ref
          .read(authRepositoryProvider)
          .createUserAccount(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim(),
            businessId: widget.businessId,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Staff Member',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(ViberantRadius.md),
                ),
                child: Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Invalid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Add Staff Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
