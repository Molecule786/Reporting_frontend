import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'improved_submit_report_dialog.dart';
import 'report_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/ai_chat_widget.dart';

class UnifiedEmployeeScreen extends StatefulWidget {
  const UnifiedEmployeeScreen({super.key});

  @override
  State<UnifiedEmployeeScreen> createState() => _UnifiedEmployeeScreenState();
}

class _UnifiedEmployeeScreenState extends State<UnifiedEmployeeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  List<dynamic> _myReports = [];
  List<dynamic> _myTasks = [];
  List<dynamic> _myLeaves = [];
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
      final reportsResult = await ApiService.getReports();
      final tasksResult = await ApiService.getTasks();
      
      List<dynamic> leavesResult = [];
      try {
        leavesResult = await ApiService.getMyLeaves();
      } catch (e) {
        print('Error loading leaves: $e');
        // Continue with empty leaves list
      }

      if (mounted) {
        setState(() {
          if (userResult['success']) _userData = userResult['data'];
          if (reportsResult['success']) _myReports = reportsResult['data']['reports'] ?? [];
          if (tasksResult['success']) _myTasks = tasksResult['data']['tasks'] ?? [];
          _myLeaves = leavesResult;
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

  Widget _buildSkeletonLoader() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(height: 28, width: 180),
                    SizedBox(height: 8),
                    AppSkeleton(height: 16, width: 220),
                  ],
                ),
                AppSkeleton(height: 48, width: 48, borderRadius: 24),
              ],
            ),
            const SizedBox(height: 32),
            const AppCard(child: Row(children: [AppSkeleton(height: 40, width: 40, borderRadius: 20), SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppSkeleton(height: 16, width: 120), SizedBox(height: 8), AppSkeleton(height: 14, width: 80)])])),
            const SizedBox(height: 32),
            const AppSkeleton(height: 24, width: 120),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: List.generate(4, (i) => const AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppSkeleton(height: 24, width: 24), SizedBox(height: 16), AppSkeleton(height: 28, width: 40)]))),
            ),
            const SizedBox(height: 32),
            const AppSkeleton(height: 24, width: 150),
            const SizedBox(height: 16),
            const Row(children: [Expanded(child: AppSkeleton(height: 56)), SizedBox(width: 16), Expanded(child: AppSkeleton(height: 56))]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        drawer: kIsWeb ? null : _buildMainDrawer(), // Optional for mobile more options
        body: _isLoading
            ? _buildSkeletonLoader()
            : SafeArea(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildDashboardTab(),
                    _buildReportsTab(),
                    _buildTasksTab(),
                    _buildLeavesTab(),
                    const EditProfileScreen(), // Use the existing screen as a tab
                  ],
                ),
              ),
        floatingActionButton: const AIChatWidget(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textMuted,
          showUnselectedLabels: true,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.beach_access_rounded), label: 'Leaves'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDrawer() {
    final userName = _userData?['full_name'] ?? 'Employee';
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(_userData?['email'] ?? 'employee@company.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(userName[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: AppTheme.primary)),
            ),
            decoration: const BoxDecoration(color: AppTheme.primary),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Data'),
            onTap: () {
              Navigator.pop(context);
              _loadData();
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
            onTap: () async {
              await ApiService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    final userName = _userData?['full_name'] ?? 'Employee';
    final String? rawId = _userData?['_id']?.toString();
    final employeeId = rawId != null 
        ? (rawId.length >= 8 ? rawId.substring(0, 8).toUpperCase() : rawId.toUpperCase()) 
        : 'EMP001';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here\'s what\'s happening today.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Welcome/ID Card
            AppCard(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Employee',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        'ID: $employeeId',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Quick Stats
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                AppStatCard(
                  title: 'Reports',
                  value: _myReports.length.toString(),
                  icon: Icons.description_rounded,
                  color: AppTheme.primary,
                ),
                AppStatCard(
                  title: 'Tasks',
                  value: _myTasks.length.toString(),
                  icon: Icons.assignment_rounded,
                  color: Colors.orange,
                ),
                AppStatCard(
                  title: 'Leaves',
                  value: _myLeaves.length.toString(),
                  icon: Icons.beach_access_rounded,
                  color: AppTheme.secondary,
                ),
                AppStatCard(
                  title: 'Pending',
                  value: _myTasks.where((t) => t['status'] == 'pending').length.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: Colors.pink,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'New Report',
                    onPressed: () => ImprovedSubmitReportDialog.show(context, _loadData),
                    backgroundColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Request Leave',
                    onPressed: () => _showRequestLeaveDialog(),
                    backgroundColor: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Track your submissions', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              AppButton(
                label: 'New Report',
                onPressed: () => ImprovedSubmitReportDialog.show(context, _loadData),
                width: 140,
                backgroundColor: AppTheme.primary,
              ),
            ],
          ),
        ),
        Expanded(
          child: _myReports.isEmpty
              ? const AppEmptyState(icon: Icons.description_outlined, title: 'No reports yet', message: 'Your submitted reports will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _myReports.length,
                  itemBuilder: (context, index) {
                    final report = _myReports[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailScreen(reportId: report['_id']),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  report['title'] ?? 'Untitled Report',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(report['status'] ?? 'pending'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report['description'] ?? '',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(_formatDate(report['created_at']), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const Spacer(),
                              if (report['attachments'] != null && (report['attachments'] as List).isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.primary),
                                    const SizedBox(width: 4),
                                    Text('${(report['attachments'] as List).length}', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
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
      case 'in_progress':
      case 'pending':
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
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
                  Text('My Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Active assignments', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${_myTasks.where((t) => t['status'] != 'completed').length} Pending', 
                           style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _myTasks.isEmpty
              ? const AppEmptyState(icon: Icons.task_alt_rounded, title: 'All caught up!', message: 'You have no pending tasks at the moment.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _myTasks.length,
                  itemBuilder: (context, index) {
                    final task = _myTasks[index];
                    final bool isCompleted = task['status'] == 'completed';
                    
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: isCompleted,
                              activeColor: AppTheme.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (value) async {
                                final newStatus = value == true ? 'completed' : 'pending';
                                try {
                                  await ApiService.updateTask(taskId: task['_id'], status: newStatus);
                                  _loadData();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => TaskDetailDialog.show(context, task, false, _loadData),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title'] ?? 'Untitled Task',
                                    style: TextStyle(
                                      fontSize: 15, 
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (task['description'] != null && task['description'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        task['description'],
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _buildStatusBadge(task['status'] ?? 'pending'),
                        ],
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
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Leaves', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  Text('Time off history', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              AppButton(
                label: 'Request Leave',
                onPressed: () => _showRequestLeaveDialog(),
                width: 160,
                backgroundColor: AppTheme.secondary,
              ),
            ],
          ),
        ),
        Expanded(
          child: _myLeaves.isEmpty
              ? const AppEmptyState(icon: Icons.beach_access_rounded, title: 'No leave requests', message: 'Plan your next break easily.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _myLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = _myLeaves[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(leave['leave_type'] ?? 'Leave', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              _buildStatusBadge(leave['status'] ?? 'pending'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Text('${leave['start_date'] ?? 'N/A'} → ${leave['end_date'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Reason: ${leave['reason'] ?? 'Not specified'}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          if (leave['admin_comment'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.comment_outlined, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Admin: ${leave['admin_comment']}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
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
              Image.network(url, fit: BoxFit.contain)
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
        builder: (context, setDialogState) {
          player.onPlayerComplete.listen((_) {
            if (mounted) {
              setDialogState(() {
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
                  icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 48, color: Colors.blue),
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                      setDialogState(() {
                        isPlaying = false;
                        isPaused = true;
                      });
                    } else {
                      if (isPaused) {
                        await player.resume();
                      } else {
                        await player.play(UrlSource(url));
                      }
                      setDialogState(() {
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
                      setDialogState(() {
                        isPlaying = false;
                        isPaused = false;
                      });
                    },
                  ),
                const Expanded(
                  child: Text('Listen to the recorded message'),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showSubmitReportDialog() {
    ImprovedSubmitReportDialog.show(context, () => _loadData());
  }

  void _showRequestLeaveDialog() {
    String selectedLeaveType = 'full day';
    String? selectedReason;
    DateTime? startDate;
    DateTime? endDate;
    
    // Voice recording state
    final AudioRecorder audioRecorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    String? recordedPath;
    bool isRecording = false;
    bool isPaused = false;
    bool isPlaying = false;
    bool isPlaybackPaused = false;
    
    // Attachment state
    PlatformFile? attachedFile;
    bool isSubmitting = false;

    void showPreview(PlatformFile file) {
      final isImage = file.name.toLowerCase().endsWith('.jpg') ||
          file.name.toLowerCase().endsWith('.jpeg') ||
          file.name.toLowerCase().endsWith('.png');

      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Preview: ${file.name}'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.insert_drive_file,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      file.name,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> startRecording() async {
            try {
              if (await audioRecorder.hasPermission()) {
                if (kIsWeb) {
                  await audioRecorder.start(const RecordConfig(), path: '');
                } else {
                  final directory = await getApplicationDocumentsDirectory();
                  final path = '${directory.path}/leave_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                  
                  await audioRecorder.start(const RecordConfig(), path: path);
                }
                setDialogState(() {
                  isRecording = true;
                  isPaused = false;
                  recordedPath = null;
                });
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Microphone permission required')),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error starting recording: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          }

          Future<void> pauseRecording() async {
            await audioRecorder.pause();
            setDialogState(() => isPaused = true);
          }

          Future<void> resumeRecording() async {
            await audioRecorder.resume();
            setDialogState(() => isPaused = false);
          }

          Future<void> stopRecording() async {
            try {
              final path = await audioRecorder.stop();
              setDialogState(() {
                isRecording = false;
                isPaused = false;
                recordedPath = path;
              });
            } catch (e) {
              debugPrint('Error stopping recording: $e');
            }
          }

          Future<void> playRecording() async {
            if (recordedPath != null) {
              try {
                if (isPlaybackPaused) {
                  await audioPlayer.resume();
                  setDialogState(() {
                    isPlaying = true;
                    isPlaybackPaused = false;
                  });
                } else {
                  if (kIsWeb) {
                    await audioPlayer.play(UrlSource(recordedPath!));
                  } else {
                    await audioPlayer.play(DeviceFileSource(recordedPath!));
                  }
                  
                  setDialogState(() {
                    isPlaying = true;
                    isPlaybackPaused = false;
                  });
                  audioPlayer.onPlayerComplete.listen((_) {
                    if (context.mounted) {
                      setDialogState(() {
                        isPlaying = false;
                        isPlaybackPaused = false;
                      });
                    }
                  });
                }
              } catch (e) {
                debugPrint('Error playing recording: $e');
              }
            }
          }

          Future<void> pausePlayback() async {
            await audioPlayer.pause();
            setDialogState(() {
              isPlaying = false;
              isPlaybackPaused = true;
            });
          }

          Future<void> stopPlayback() async {
            await audioPlayer.stop();
            setDialogState(() {
              isPlaying = false;
              isPlaybackPaused = false;
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Request Leave',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedLeaveType,
                    decoration: const InputDecoration(labelText: 'Leave Type'),
                    items: [
                      'half day morning',
                      'half day afternoon',
                      'full day',
                      'Annual Leave',
                      'Work from Home',
                      'Work At site'
                    ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (v) => setDialogState(() => selectedLeaveType = v!),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reason Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: [
                      'University class',
                      'Personal Work',
                      'Sick Leave',
                      'Site Deployment'
                    ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => selectedReason = v),
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Date
                  const Text('Start Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate != null && startDate!.isBefore(today) ? today : (startDate ?? today),
                        firstDate: today,
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (date != null) {
                        setDialogState(() => startDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            startDate == null ? 'Select start date' : DateFormat('MMM dd, yyyy').format(startDate!),
                            style: TextStyle(color: startDate == null ? Colors.grey[600] : Colors.black),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // End Date
                  const Text('End Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? today,
                        firstDate: startDate ?? today,
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (date != null) {
                        setDialogState(() => endDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            endDate == null ? 'Select end date' : DateFormat('MMM dd, yyyy').format(endDate!),
                            style: TextStyle(color: endDate == null ? Colors.grey[600] : Colors.black),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Voice Recording Section
                  const Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        if (!isRecording && recordedPath == null)
                          ElevatedButton.icon(
                            onPressed: startRecording,
                            icon: const Icon(Icons.mic, size: 20),
                            label: const Text('Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (isRecording) ...[
                          Icon(isPaused ? Icons.pause_circle_filled : Icons.fiber_manual_record, 
                               color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            isPaused ? 'Recording Paused' : 'Recording...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                            onPressed: isPaused ? resumeRecording : pauseRecording,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop),
                            onPressed: stopRecording,
                          ),
                        ],
                        if (recordedPath != null && !isRecording) ...[
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle : Icons.play_circle,
                              size: 32,
                              color: Colors.blue,
                            ),
                            onPressed: isPlaying ? pausePlayback : playRecording,
                          ),
                          if (isPlaybackPaused || isPlaying)
                            IconButton(
                              icon: const Icon(Icons.stop_circle, color: Colors.orange),
                              onPressed: stopPlayback,
                            ),
                          const Expanded(
                            child: Text('Voice note recorded ✓', style: TextStyle(fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setDialogState(() {
                              recordedPath = null;
                              isPlaying = false;
                              isPlaybackPaused = false;
                              audioPlayer.stop();
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Attachment Section
                  const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (attachedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Chip(
                              label: Text(attachedFile!.name),
                              onDeleted: () => setDialogState(() => attachedFile = null),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => showPreview(attachedFile!),
                            tooltip: 'Preview',
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        withData: kIsWeb, // Important for web bytes processing
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setDialogState(() => attachedFile = result.files.single);
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Document/Image'),
                  ),
                  
                  if (isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (startDate == null || selectedReason == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  
                  setDialogState(() => isSubmitting = true);
                  
                  try {
                    String? voiceUrl;
                    String? attachmentUrl;
                    
                    // Upload Voice Note
                    if (recordedPath != null) {
                      try {
                        if (kIsWeb) {
                          final response = await http.get(Uri.parse(recordedPath!));
                          voiceUrl = await ApiService.uploadFileBytes('voice_note.m4a', response.bodyBytes);
                        } else {
                          voiceUrl = await ApiService.uploadFile(recordedPath!);
                        }
                      } catch (e) {
                        debugPrint('Voice note upload error: $e');
                      }
                    }
                    
                    // Upload Attachment
                    if (attachedFile != null) {
                      if (kIsWeb && attachedFile!.bytes != null) {
                        attachmentUrl = await ApiService.uploadFileBytes(attachedFile!.name, attachedFile!.bytes!);
                      } else if (attachedFile!.path != null) {
                        attachmentUrl = await ApiService.uploadFile(attachedFile!.path!);
                      }
                    }
                    
                    await ApiService.createLeave({
                      'leave_type': selectedLeaveType,
                      'reason': selectedReason,
                      'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
                      'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
                      'voice_note_url': voiceUrl,
                      'attachment_url': attachmentUrl,
                    });
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
                    _loadData();
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Submit'),
              ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      audioRecorder.dispose();
      audioPlayer.dispose();
    });
  }
}
