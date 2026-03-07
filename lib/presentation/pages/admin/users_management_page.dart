// lib/presentation/pages/dashboard/admin/users_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/domain/entities/user_entity.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/providers/auth_provider.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';

class UsersManagementPage extends ConsumerStatefulWidget {
  const UsersManagementPage({super.key});

  @override
  ConsumerState<UsersManagementPage> createState() =>
      _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<UsersManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Check if user is admin
    if (authState is! AuthAuthenticated || !authState.user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to access this page.'),
        ),
      );
    }

    final businessId = authState.user.businessId;

    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: ViberantColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddUserDialog(context, ref, authState.user),
            tooltip: 'Add User',
          ),
          // Migration button to fix existing users
          // IconButton(
          // icon: const Icon(Icons.refresh_rounded),
          // onPressed: () => _migrateUsers(context, ref),
          // tooltip: 'Fix User Business IDs',
          // ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: ViberantColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('businessId', isEqualTo: businessId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                // Filter users based on search query
                final filteredUsers = users.where((userDoc) {
                  final user = UserEntity.fromMap(
                    userDoc.data() as Map<String, dynamic>,
                  );
                  return _searchQuery.isEmpty ||
                      user.displayName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      user.email.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: ViberantColors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No users found'
                              : 'No users match your search',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: ViberantColors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add your first staff member'
                              : 'Try a different search term',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: ViberantColors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = UserEntity.fromMap(
                      filteredUsers[index].data() as Map<String, dynamic>,
                    );

                    return _UserListItem(
                          user: user,
                          isCurrentUser: user.id == authState.user.id,
                          onEdit: () => _showEditUserDialog(context, ref, user),
                          onDelete: () =>
                              _showDeleteConfirmation(context, ref, user),
                        )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(
    BuildContext context,
    WidgetRef ref,
    UserEntity currentUser,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(businessId: currentUser.businessId),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteUser(context, ref, user),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(BuildContext context, WidgetRef ref, UserEntity user) async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.deleteUser(user.id);

      if (mounted) {
        Navigator.pop(context); // Close confirmation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.displayName} deleted'),
            backgroundColor: ViberantColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close confirmation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: ViberantColors.error,
          ),
        );
      }
    }
  }

  //void _migrateUsers(BuildContext context, WidgetRef ref) async {
  // try {
  // final authNotifier = ref.read(authProvider.notifier);
  // await authNotifier.migrateUserBusinessIds();

  // ScaffoldMessenger.of(context).showSnackBar(
  // SnackBar(
  // content: Text('User business IDs migrated successfully'),
  //  backgroundColor: ViberantColors.success,
  // ),
  // );
  // } catch (e) {
  // ScaffoldMessenger.of(context).showSnackBar(
  // SnackBar(
  //  content: Text('Migration failed: $e'),
  // backgroundColor: ViberantColors.error,
  // ),
  // );
}
// }
//}

class _UserListItem extends ConsumerWidget {
  final UserEntity user;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserListItem({
    required this.user,
    required this.isCurrentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar with Status
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: user.isActive
                      ? ViberantColors.primary.withOpacity(0.1)
                      : ViberantColors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: user.isActive
                      ? ViberantColors.primary
                      : ViberantColors.grey,
                  size: 24,
                ),
              ),
              Positioned(right: 0, bottom: 0, child: _buildUserStatus(user)),
            ],
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: user.isActive
                            ? ViberantColors.onSurface
                            : ViberantColors.grey,
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ViberantColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ViberantColors.primary,
                          ),
                        ),
                      ),
                    ],
                    if (!user.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ViberantColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ViberantColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ViberantColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Joined ${_formatDate(user.createdAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ViberantColors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildUserStatus(user),
                    const SizedBox(width: 4),
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: user.isActive
                            ? ViberantColors.success
                            : ViberantColors.grey,
                      ),
                    ),
                  ],
                ),
                // Debug info - show business ID
                //if (user.businessId != user.id) // Only show if correct
                //Text(
                // 'Business: ${user.businessId.substring(0, 8)}...',
                // style: GoogleFonts.inter(
                // fontSize: 10,
                // color: ViberantColors.success,
                // ),
                // ),
                //if (user.businessId == user.id) // Show warning if wrong
                //Text(
                //'⚠️ Wrong Business ID',
                // style: GoogleFonts.inter(
                // fontSize: 10,
                // color: ViberantColors.error,
                // ),
                //  ),
              ],
            ),
          ),

          // Actions
          if (!isCurrentUser)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle_active')
                  _toggleUserActive(context, ref, user);
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Role'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive
                            ? Icons.person_off_rounded
                            : Icons.person_rounded,
                        size: 20,
                        color: user.isActive
                            ? Colors.orange
                            : ViberantColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                          color: user.isActive
                              ? Colors.orange
                              : ViberantColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ViberantColors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'You',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ViberantColors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserStatus(UserEntity user) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: user.isActive ? ViberantColors.success : ViberantColors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: ViberantColors.surface, width: 1.5),
      ),
    );
  }

  void _toggleUserActive(
    BuildContext context,
    WidgetRef ref,
    UserEntity user,
  ) async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.toggleUserActive(user.id, !user.isActive);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User ${user.displayName} ${user.isActive ? 'deactivated' : 'activated'}',
          ),
          backgroundColor: ViberantColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user: $e'),
          backgroundColor: ViberantColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7} weeks ago';
    return DateFormat('MMM d, y').format(date);
  }
}

// Add User Dialog - UPDATED
class AddUserDialog extends StatefulWidget {
  final String businessId;

  const AddUserDialog({super.key, required this.businessId});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email address';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ViberantColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: ViberantColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff users can only access POS functions',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ViberantColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add User'),
        ),
      ],
    );
  }

  void _addUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authNotifier = ProviderScope.containerOf(
          context,
        ).read(authProvider.notifier);

        await authNotifier.createUserAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          businessId: widget.businessId,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User ${_emailController.text} added successfully'),
              backgroundColor: ViberantColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add user: $e'),
              backgroundColor: ViberantColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

// Edit User Dialog remains the same...
class EditUserDialog extends StatefulWidget {
  final UserEntity user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.email,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: ViberantColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user.displayName,
            style: GoogleFonts.inter(color: ViberantColors.grey),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserRole>(
            initialValue: _selectedRole,
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(
                  role == UserRole.admin ? 'Admin' : 'Staff User',
                  style: GoogleFonts.inter(),
                ),
              );
            }).toList(),
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _selectedRole = value!),
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.people_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ViberantColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: ViberantColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedRole == UserRole.admin
                        ? 'Admins have full access to all features'
                        : 'Staff users can only access POS functions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ViberantColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  void _updateUser() async {
    setState(() => _isLoading = true);

    try {
      final authNotifier = ProviderScope.containerOf(
        context,
      ).read(authProvider.notifier);

      await authNotifier.updateUserRole(widget.user.id, _selectedRole);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User role updated to ${_selectedRole == UserRole.admin ? 'Admin' : 'Staff'}',
            ),
            backgroundColor: ViberantColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: ViberantColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
