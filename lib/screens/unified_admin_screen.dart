import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/ai_chat_widget.dart';

class UnifiedAdminScreen extends StatefulWidget {
  const UnifiedAdminScreen({super.key});

  @override
  State<UnifiedAdminScreen> createState() => _UnifiedAdminScreenState();
}

class _UnifiedAdminScreenState extends State<UnifiedAdminScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _reports = [];
  List<dynamic> _users = [];
  List<dynamic> _tasks = [];
  List<dynamic> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userResult = await ApiService.getCurrentUser();
      final statsResult = await ApiService.getDashboardStats();
      final reportsResult = await ApiService.getReports();
      final usersResult = await ApiService.getUsers();
      final tasksResult = await ApiService.getTasks();
      
      List<dynamic> leavesResult = [];
      try {
        leavesResult = await ApiService.getAllLeaves();
      } catch (e) {
        print('Error loading leaves: $e');
        // Continue with empty leaves list
      }

      if (mounted) {
        setState(() {
          if (userResult['success']) _userData = userResult['data'];
          if (statsResult['success']) _dashboardStats = statsResult['data'];
          if (reportsResult['success']) _reports = reportsResult['data']['reports'] ?? [];
          if (usersResult['success']) _users = usersResult['data']['users'] ?? [];
          if (tasksResult['success']) _tasks = tasksResult['data']['tasks'] ?? [];
          _leaves = leavesResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: _isLoading
            ? _buildSkeletonLoader()
            : Row(
                children: [
                  // Sidebar for Desktop/Tablet
                  if (MediaQuery.of(context).size.width >= 800)
                    _buildSidebar(isPermanent: true),
                  
                  // Main Content
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        Expanded(
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: [
                              _buildOverviewTab(),
                              _buildReportsTab(),
                              _buildTasksTab(),
                              _buildLeavesTab(),
                              _buildUsersTab(),
                              _buildAnalyticsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: const AIChatWidget(),
        drawer: MediaQuery.of(context).size.width < 800 
            ? Drawer(child: _buildSidebar(isPermanent: false)) 
            : null,
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Row(
      children: [
        if (MediaQuery.of(context).size.width >= 800)
          Container(
            width: 250,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(height: 40, width: 120),
                const SizedBox(height: 48),
                ...List.generate(6, (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Row(children: [AppSkeleton(height: 24, width: 24), SizedBox(width: 12), Expanded(child: AppSkeleton(height: 20))]),
                )),
              ],
            ),
          ),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 70,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Row(children: [AppSkeleton(height: 24, width: 150), Spacer(), AppSkeleton(height: 40, width: 40, borderRadius: 20)]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(4, (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i == 3 ? 0 : 16),
                            child: const AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppSkeleton(height: 24, width: 24), SizedBox(height: 16), AppSkeleton(height: 32, width: 60), SizedBox(height: 8), AppSkeleton(height: 16, width: 80)])),
                          ),
                        )),
                      ),
                      const SizedBox(height: 48),
                      const AppSkeleton(height: 24, width: 200),
                      const SizedBox(height: 16),
                      AppCard(child: Column(children: List.generate(5, (i) => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Row(children: [AppSkeleton(height: 40, width: 40, borderRadius: 20), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppSkeleton(height: 16, width: 150), SizedBox(height: 8), AppSkeleton(height: 12, width: 100)])), AppSkeleton(height: 24, width: 60)]))))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    String title;
    switch (_selectedIndex) {
      case 0: title = 'Admin Overview'; break;
      case 1: title = 'Reports Management'; break;
      case 2: title = 'Task Assignments'; break;
      case 3: title = 'Leave Requests'; break;
      case 4: title = 'User Directory'; break;
      case 5: title = 'Analytics & Export'; break;
      default: title = 'Admin Dashboard';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 800)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              (_userData?['full_name'] ?? 'A')[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isPermanent}) {
    return Container(
      width: 280,
      color: const Color(0xFF111827), // Sleek Navy/Dark SaaS Sidebar
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'WorkFlow Pro',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(0, Icons.dashboard_rounded, 'Overview'),
                _buildSidebarItem(1, Icons.description_rounded, 'Reports'),
                _buildSidebarItem(2, Icons.assignment_rounded, 'Tasks'),
                _buildSidebarItem(3, Icons.beach_access_rounded, 'Leaves'),
                _buildSidebarItem(4, Icons.people_rounded, 'Users'),
                _buildSidebarItem(5, Icons.analytics_rounded, 'Analytics'),
              ],
            ),
          ),
          
          // User Profile & Logout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _userData?['full_name'] ?? 'Admin',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Sign Out',
                  onPressed: () async {
                    await ApiService.logout();
                    if (mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  height: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (MediaQuery.of(context).size.width < 800) {
            Navigator.pop(context);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primary : const Color(0xFF9CA3AF),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(vertical: -2),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalReports = _dashboardStats?['total_reports'] ?? 0;
    final pendingReports = _dashboardStats?['pending_reports'] ?? 0;
    final totalUsers = _dashboardStats?['total_users'] ?? 0;
    final totalTasks = _dashboardStats?['total_tasks'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_userData?['full_name'] ?? 'Admin'}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text('Monitor your organization\'s performance and activities.', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
                AppButton(
                  label: 'Organization Stats',
                  onPressed: () {},
                  width: 180,
                  backgroundColor: AppTheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.6,
              children: [
                AppStatCard(
                  title: 'Total Reports',
                  value: totalReports.toString(),
                  icon: Icons.description_rounded,
                  color: AppTheme.primary,
                ),
                AppStatCard(
                  title: 'Pending Approval',
                  value: pendingReports.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange,
                ),
                AppStatCard(
                  title: 'Active Users',
                  value: totalUsers.toString(),
                  icon: Icons.people_rounded,
                  color: AppTheme.secondary,
                ),
                AppStatCard(
                  title: 'Open Tasks',
                  value: totalTasks.toString(),
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.pink,
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Recent Activity Section
            Row(
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            AppCard(
              padding: EdgeInsets.zero,
              child: _reports.isEmpty
                  ? AppEmptyState(
                      title: 'No Reports Yet',
                      message: 'New reports will appear here once submitted by employees.',
                      icon: Icons.description_outlined,
                      actionLabel: 'Invite Team',
                      onAction: () => setState(() => _selectedIndex = 4),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reports.take(5).length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.description_rounded, color: AppTheme.primary, size: 20),
                          ),
                          title: Text(report['title'] ?? 'Untitled Report', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Submitted by ${report['user_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12)),
                          trailing: _buildStatusBadge(report['status'] ?? 'pending'),
                          onTap: () => _showReportDialog(report),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        color = AppTheme.success;
        break;
      case 'rejected':
        color = AppTheme.error;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All Submission Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Review and manage all employee submissions', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const Spacer(),
              AppButton(
                label: 'Export PDF',
                onPressed: () => _handleExport('reports', 'pdf'),
                width: 120,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textPrimary,
                height: 40,
              ),
            ],
          ),
        ),
        Expanded(
          child: _reports.isEmpty
              ? const AppEmptyState(icon: Icons.description_outlined, title: 'No reports found', message: 'Organizational reports will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      onTap: () => _showReportDialog(report),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.description_rounded, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report['title'] ?? 'Untitled Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text('By ${report['user_name'] ?? 'Unknown'} • ${_formatDate(report['created_at'])}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          _buildStatusBadge(report['status'] ?? 'pending'),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Assign and monitor team objectives', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const Spacer(),
              AppButton(
                label: 'Assign Task',
                onPressed: _showAssignTaskDialog,
                width: 140,
                backgroundColor: AppTheme.primary,
                height: 40,
              ),
            ],
          ),
        ),
        Expanded(
          child: _tasks.isEmpty
              ? const AppEmptyState(icon: Icons.assignment_outlined, title: 'No tasks found', message: 'Assigned tasks will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(task['title'] ?? 'Untitled Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(task['description'] ?? 'No description'),
                        trailing: _buildStatusBadge(task['status'] ?? 'pending'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLeavesTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leave Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Review and approve time-off requests', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: _leaves.isEmpty
              ? const AppEmptyState(icon: Icons.beach_access_rounded, title: 'No leave requests', message: 'Employee time-off requests will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _leaves.length,
                  itemBuilder: (context, index) {
                    final leave = _leaves[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      onTap: () => _showLeaveActionDialog(leave),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.event_available_rounded, color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${leave['user_name']} - ${leave['leave_type']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('Reason: ${leave['reason']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(leave['status'] ?? 'pending'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Text('Duration: ${leave['start_date']} to ${leave['end_date'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const Spacer(),
                              const Text('Tap to review', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }


  // ========== NEW USERS TAB ==========
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Manage team members and roles', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const Spacer(),
              AppButton(
                label: 'Add User',
                onPressed: () {}, // Planned feature
                width: 120,
                backgroundColor: AppTheme.primary,
                height: 40,
              ),
            ],
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const AppEmptyState(icon: Icons.people_outline_rounded, title: 'No users found', message: 'Your team directory will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final role = (user['role'] ?? 'employee').toString();
                    final isAdmin = role.toLowerCase() == 'admin';

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      onTap: () => _showUserDetailsDialog(user),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isAdmin ? Colors.purple.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              color: isAdmin ? Colors.purple : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                                Text(user['email'] ?? 'No email', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.purple.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: isAdmin ? Colors.purple : AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showUserDetailsDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(user['full_name'] ?? 'Unknown')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.email, 'Email', user['email'] ?? 'N/A'),
            _buildDetailRow(Icons.badge, 'Role', (user['role'] ?? 'employee').toString().toUpperCase()),
            _buildDetailRow(Icons.business, 'Department', user['department'] ?? 'Not set'),
            _buildDetailRow(Icons.location_on, 'Location', user['location'] ?? 'Not set'),
            _buildDetailRow(Icons.phone, 'Phone', user['phone'] ?? 'Not set'),
            _buildDetailRow(Icons.calendar_today, 'Joined', _formatCreatedAt(user['created_at'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics & Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('In-depth organizational data and exports', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Charts Section
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reports by Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: _getReportStatusSections(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Task Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: _getTaskStatusSections(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Submission Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.only(top: 24, right: 16, left: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < 7) {
                                  return Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: _getSubmissionBarGroups(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

                const SizedBox(height: 32),
                const Text('Quick Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                
                // Quick Summary
                AppCard(
                  child: Column(
                    children: [
                      _buildStatRow('Total Reports Submitted', _reports.length.toString(), Icons.insert_chart_outlined_rounded),
                      _buildStatRow('Pending Approvals', _reports.where((r) => r['status'] == 'pending').length.toString(), Icons.hourglass_empty_rounded),
                      _buildStatRow('Total Task Count', _tasks.length.toString(), Icons.list_alt_rounded),
                      _buildStatRow('Total Leave Requests', _leaves.length.toString(), Icons.beach_access_rounded),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text('Data Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildSaaSExportCard('Reports', Icons.description_rounded, AppTheme.primary),
                    _buildSaaSExportCard('Tasks', Icons.assignment_rounded, AppTheme.secondary),
                    _buildSaaSExportCard('Leaves', Icons.beach_access_rounded, Colors.orange),
                    _buildSaaSExportCard('Users', Icons.people_rounded, Colors.purple),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaaSExportCard(String title, IconData icon, Color color) {
    return AppCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Export $title Data'),
            content: const Text('Choose your preferred format for the export.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleExport(title.toLowerCase(), 'csv');
                },
                child: const Text('CSV'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleExport(title.toLowerCase(), 'pdf');
                },
                child: const Text('PDF'),
              ),
            ],
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const Text('Export Data', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        final parts = title.split(' ');
        final type = parts.isNotEmpty ? parts.last.toLowerCase() : 'data';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Export $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green),
                  title: const Text('Export as CSV'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleExport(type, 'csv');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleExport(type, 'pdf');
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String type, String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing $type export ($format)...')),
    );

    try {
      final url = ApiService.getExportUrl(type, format: format);
      final fileName = '${type}_export_${DateTime.now().millisecondsSinceEpoch}.$format';
      await ApiService.downloadFile(url, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported $type as $format — saved as $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showReportDialog(dynamic report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] ?? 'Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${report['description'] ?? 'No description'}'),
            const SizedBox(height: 8),
            Text('Status: ${report['status'] ?? 'pending'}'),
            Text('Submitted by: ${report['user_name'] ?? 'Unknown'}'),
            if (report['voice_notes'] != null && (report['voice_notes'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Voice Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (report['voice_notes'] as List).map((url) => ElevatedButton.icon(
                  onPressed: () => _playVoiceNote(url),
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: const Text('Play', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (report['voice_notes'] as List).map((url) => OutlinedButton.icon(
                  onPressed: () => ApiService.downloadFile(url, 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a'),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )).toList(),
              ),
            ],
            if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (report['attachments'] as List).length,
                  itemBuilder: (context, i) {
                    final url = report['attachments'][i];
                    final isImage = url.toLowerCase().contains('.jpg') || 
                                    url.toLowerCase().contains('.png') || 
                                    url.toLowerCase().contains('.jpeg');
                    return GestureDetector(
                      onTap: () => _viewAttachment(url),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          image: isImage ? DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: !isImage ? const Icon(Icons.insert_drive_file, color: Colors.blue) : null,
                      ),
                    );
                  },
                ),
              ),
              if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (report['attachments'] as List).map((url) {
                    final fileName = url.split('/').last;
                    return OutlinedButton.icon(
                      onPressed: () => ApiService.downloadFile(url, fileName),
                      icon: const Icon(Icons.download, size: 18),
                      label: Text('Download ${report['attachments'].indexOf(url) + 1}', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (report['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateReport(
                  reportId: report['_id'],
                  status: 'approved',
                );
                if (!mounted) return;
                _loadData();
              },
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateReport(
                  reportId: report['_id'],
                  status: 'rejected',
                );
                if (!mounted) return;
                _loadData();
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  void _showAssignTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedUserId = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign to User'),
                items: _users.map<DropdownMenuItem<String>>((user) {
                  return DropdownMenuItem<String>(
                    value: user['_id'],
                    child: Text(user['full_name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedUserId = value ?? '';
                },
              ),
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
              if (titleController.text.isNotEmpty && selectedUserId.isNotEmpty) {
                Navigator.pop(context);
                await ApiService.createTask(
                  userId: selectedUserId,
                  title: titleController.text,
                  description: descriptionController.text,
                );
                if (!mounted) return;
                _loadData();
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showLeaveActionDialog(dynamic leave) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${leave['user_name']}'),
            Text('Type: ${leave['leave_type']}'),
            Text('Reason: ${leave['reason']}'),
            Text('Date: ${leave['start_date']}${leave['end_date'] != null ? ' to ${leave['end_date']}' : ''}'),
            const SizedBox(height: 16),
            if (leave['voice_note_url'] != null || leave['attachment_url'] != null) ...[
              const Text('Multimedia:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (leave['voice_note_url'] != null)
                    ElevatedButton.icon(
                      onPressed: () => _playVoiceNote(leave['voice_note_url']),
                      icon: const Icon(Icons.play_circle_fill, size: 18),
                      label: const Text('Voice Note', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  if (leave['voice_note_url'] != null && leave['attachment_url'] != null)
                    const SizedBox(width: 8),
                  if (leave['attachment_url'] != null)
                    OutlinedButton.icon(
                      onPressed: () => _viewAttachment(leave['attachment_url']),
                      icon: const Icon(Icons.attach_file, size: 14),
                      label: const Text('Attachment', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (leave['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateLeaveStatus(
                  leave['_id'],
                  'rejected',
                  commentController.text.isEmpty ? null : commentController.text,
                );
                _loadData();
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.updateLeaveStatus(
                  leave['_id'],
                  'approved',
                  commentController.text.isEmpty ? null : commentController.text,
                );
                _loadData();
              },
              child: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  void _viewAttachment(String url) {
    final isImage = url.toLowerCase().contains('.jpg') || 
                    url.toLowerCase().contains('.png') || 
                    url.toLowerCase().contains('.jpeg');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isImage ? 'Image Attachment' : 'File Attachment',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _playVoiceNote(String url) {
    final player = AudioPlayer();
    bool isPlaying = false;
    bool isPaused = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          player.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                isPlaying = false;
                isPaused = false;
              });
            }
          });
          
          return AlertDialog(
            title: const Text('Voice Note'),
            content: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                    size: 48, 
                    color: Colors.blue,
                  ),
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                      setState(() {
                        isPlaying = false;
                        isPaused = true;
                      });
                    } else if (isPaused) {
                      await player.resume();
                      setState(() {
                        isPlaying = true;
                        isPaused = false;
                      });
                    } else {
                      await player.play(UrlSource(url));
                      setState(() {
                        isPlaying = true;
                        isPaused = false;
                      });
                    }
                  },
                ),
                if (isPlaying || isPaused)
                  IconButton(
                    icon: const Icon(Icons.stop_circle, size: 48, color: Colors.red),
                    onPressed: () async {
                      await player.stop();
                      setState(() {
                        isPlaying = false;
                        isPaused = false;
                      });
                    },
                  ),
                const Expanded(
                  child: Text('Click to listen to the recorded message'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  player.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          );
        }
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      return date.toString();
    }
  }

  List<PieChartSectionData> _getReportStatusSections() {
    int pending = _reports.where((r) => (r['status'] ?? 'pending') == 'pending').length;
    int approved = _reports.where((r) => (r['status'] ?? '') == 'approved').length;
    int completed = _reports.where((r) => (r['status'] ?? '') == 'completed').length;
    int total = _reports.isEmpty ? 1 : _reports.length;

    return [
      PieChartSectionData(
        color: Colors.orange,
        value: pending.toDouble(),
        title: '${(pending / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: AppTheme.primary,
        value: approved.toDouble(),
        title: '${(approved / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: AppTheme.success,
        value: completed.toDouble(),
        title: '${(completed / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  List<PieChartSectionData> _getTaskStatusSections() {
    int complete = _tasks.where((t) => (t['status'] ?? '') == 'completed').length;
    int todo = _tasks.length - complete;
    int total = _tasks.isEmpty ? 1 : _tasks.length;

    return [
      PieChartSectionData(
        color: AppTheme.secondary,
        value: complete.toDouble(),
        title: '${(complete / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.grey.shade300,
        value: todo.toDouble(),
        title: '${(todo / total * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
      ),
    ];
  }

  List<BarChartGroupData> _getSubmissionBarGroups() {
    return List.generate(7, (i) => BarChartGroupData(
      x: i,
      barRods: [
        BarChartRodData(
          toY: (i * 1.5 + 2) % 8,
          color: AppTheme.primary,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ));
  }
}
