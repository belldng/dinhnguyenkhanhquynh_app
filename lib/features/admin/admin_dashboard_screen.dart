import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_providers.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    final statsRes = await ApiClient.get(ApiEndpoints.adminDashboardStats);
    final usersRes = await ApiClient.get(
        '${ApiEndpoints.adminUsers}${_searchQuery.isNotEmpty ? "?search=$_searchQuery" : ""}');

    if (statsRes.success && statsRes.data != null) {
      _stats = statsRes.data as Map<String, dynamic>;
    }

    if (usersRes.success && usersRes.data != null) {
      _users = (usersRes.data as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleUserStatus(String userId, bool currentActive) async {
    final nextStatus = !currentActive;
    final res = await ApiClient.post(ApiEndpoints.adminToggleUserStatus, {
      'userId': userId,
      'isActive': nextStatus,
    });

    if (res.success) {
      _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Đã cập nhật trạng thái người dùng'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin System Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            onPressed: () async {
              final nav = Navigator.of(context);
              await ref.read(authProvider.notifier).logout();
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Tổng Người Dùng',
                            '${_stats?['totalUsers'] ?? 0}',
                            Icons.people_alt_rounded,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Phụ Huynh',
                            '${_stats?['totalParents'] ?? 0}',
                            Icons.supervised_user_circle_rounded,
                            AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Trẻ Em',
                            '${_stats?['totalChildren'] ?? 0}',
                            Icons.child_care_rounded,
                            AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Thiết Bị Active',
                            '${_stats?['totalActiveDevices'] ?? 0}',
                            Icons.devices_rounded,
                            Colors.purple.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User Management Section
                    const Text(
                      'Quản Lý Tài Khoản Hệ Thống',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search box
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên hoặc email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  _loadAdminData();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (val) {
                        setState(() => _searchQuery = val.trim());
                        _loadAdminData();
                      },
                    ),
                    const SizedBox(height: 16),

                    // User List
                    if (_users.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Không tìm thấy tài khoản nào.'),
                        ),
                      )
                    else
                      ..._users.map((u) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: u.role == 'Admin'
                                  ? Colors.purple.shade100
                                  : (u.role == 'Parent'
                                      ? AppColors.primaryLight
                                      : AppColors.accentGreenLight),
                              child: Icon(
                                u.role == 'Admin'
                                    ? Icons.security
                                    : (u.role == 'Parent'
                                        ? Icons.person
                                        : Icons.child_care),
                                color: AppColors.primaryDark,
                              ),
                            ),
                            title: Text(
                              u.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${u.email} • Vai trò: ${u.role}'),
                            trailing: Switch(
                              value: true, // Default active
                              activeThumbColor: AppColors.accentGreen,
                              onChanged: (val) =>
                                  _toggleUserStatus(u.id, val),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
