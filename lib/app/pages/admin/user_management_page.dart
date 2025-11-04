import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/data/models/user_model.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../controllers/user_management_controller.dart';
import '../../ui/theme/app_colors.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Scaffold(
      backgroundColor: TpsColors.musicBackgroundDark,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: TpsColors.musicBackgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingWidget());
        }

        return Column(
          children: [
            _buildFilterSection(controller),
            Expanded(
              child: _buildUsersList(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterSection(UserManagementController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => DropdownButton<String>(
                  value: controller.filterType.value,
                  isExpanded: true,
                  dropdownColor: TpsColors.musicCardDark,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(
                        value: 'admins', child: Text('Admins Only')),
                    DropdownMenuItem(
                        value: 'users', child: Text('Regular Users')),
                  ],
                  onChanged: (value) => controller.setFilterType(value!),
                )),
          ),
          // const SizedBox(width: 16),
          // ElevatedButton.icon(
          //   onPressed: controller.loadUsers,
          //   icon: const Icon(Icons.refresh),
          //   label: const Text('Refresh'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: TpsColors.musicPrimary,
          //     foregroundColor: Colors.white,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserManagementController controller) {
    return Obx(() {
      final users = controller.filteredUsers;

      if (users.isEmpty) {
        return const Center(
          child: Text(
            'No users found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(controller, user);
        },
      );
    });
  }

  Widget _buildUserCard(UserManagementController controller, UserModel user) {
    return Card(
      color: TpsColors.musicCardDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      user.isAdmin ? Colors.orange : TpsColors.musicPrimary,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ??
                            user.phone?.replaceAll('+959', '09') ??
                            'No email or phone',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (user.isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: TpsColors.musicCardDark,
                  onSelected: (value) =>
                      _handleMenuAction(controller, user, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: user.isAdmin ? 'demote' : 'promote',
                      child: Row(
                        children: [
                          Icon(
                            user.isAdmin
                                ? Icons.remove_circle
                                : Icons.add_circle,
                            color: user.isAdmin ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isAdmin ? 'Remove Admin' : 'Make Admin',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View Details',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (user.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Joined: ${_formatDate(user.createdAt!)}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
      UserManagementController controller, UserModel user, String action) {
    switch (action) {
      case 'promote':
        _showPromoteDialog(controller, user);
        break;
      case 'demote':
        _showDemoteDialog(controller, user);
        break;
      case 'view_details':
        _showUserDetailsDialog(user);
        break;
    }
  }

  void _showPromoteDialog(UserManagementController controller, UserModel user) {
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: TpsColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: const Text('Promote to Admin'),
        content: Text(
            'Are you sure you want to promote ${user.displayName} to admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(Get.context!);
              await controller.promoteToAdmin(user.id!);
            },
            // style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.green,
            //     textStyle: const TextStyle(color: Colors.white)),
            child: const Text(
              'Promote',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoteDialog(UserManagementController controller, UserModel user) {
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: TpsColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: const Text('Remove Admin Privileges'),
        content: Text(
            'Are you sure you want to remove admin privileges from ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(Get.context!);
              await controller.demoteFromAdmin(user.id!);
            },
            // style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.green,
            //     textStyle: const TextStyle(color: Colors.white)),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(UserModel user) {
    Get.dialog(
      GlassAlertDialog(
        title: Text('User Details - ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', user.displayName),
            _buildDetailRow('Email', user.email ?? 'Not provided'),
            _buildDetailRow('Phone', user.phone ?? 'Not provided'),
            _buildDetailRow('Provider', user.provider ?? 'Not provided'),
            _buildDetailRow('Admin Status', user.isAdmin ? 'Yes' : 'No'),
            _buildDetailRow('Guest User', user.isGuest ? 'Yes' : 'No'),
            if (user.createdAt != null)
              _buildDetailRow('Created', _formatDate(user.createdAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
