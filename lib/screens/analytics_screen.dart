import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userResult = await ApiService.getCurrentUser();
    final analyticsResult = await ApiService.getAnalytics();

    if (mounted) {
      setState(() {
        if (userResult['success']) {
          _userData = userResult['data'];
        }
        if (analyticsResult['success']) {
          _analyticsData = analyticsResult['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String format) async {
    final formatLower = format.toLowerCase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics as $format...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // Exporting analytics summary as a report
      final url = ApiService.getExportUrl('reports', format: formatLower);
      final fileName = 'analytics_summary_${DateTime.now().millisecondsSinceEpoch}.$formatLower';
      await ApiService.downloadFile(url, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully exported analytics to $fileName'),
            backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _userData?['full_name'] ?? 'User';
    final userRole = _userData?['role'] == 'admin' ? 'Admin' : 'Employee';
    final totalReports = _analyticsData?['reports']?['total'] ?? 0;
    final pendingReports = _analyticsData?['reports']?['pending'] ?? 0;
    final approvedReports = _analyticsData?['reports']?['approved'] ?? 0;
    final totalTasks = _analyticsData?['tasks']?['total'] ?? 0;
    final completedTasks = _analyticsData?['tasks']?['completed'] ?? 0;
    final pendingTasks = _analyticsData?['tasks']?['pending'] ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Redirect to appropriate dashboard
        if (_userData?['role'] == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
        
      },child: Scaffold(
        body: Row(
          children: [
            const Sidebar(currentRoute: '/analytics'),
            Expanded(
              child: Column(
                children: [
                  TopBar(userName: userName, userRole: userRole),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analytics & Insights',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Track performance metrics and export detailed reports',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Export Analytics'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.table_chart),
                                              title: const Text('CSV Format'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _exportData('CSV');
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.picture_as_pdf),
                                              title: const Text('PDF Report'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _exportData('PDF');
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text('Export'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                DropdownButton<String>(
                                  value: _selectedPeriod,
                                  items: ['Today', 'This Week', 'This Month', 'This Year']
                                      .map((period) => DropdownMenuItem(
                                            value: period,
                                            child: Text(period),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value ?? 'This Week';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Key Metrics
                        const Text(
                          'Key Performance Metrics',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'Total Reports',
                                totalReports.toString(),
                                Icons.description,
                                Colors.blue,
                                '+12% from last period',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildMetricCard(
                                'Approved Reports',
                                approvedReports.toString(),
                                Icons.check_circle,
                                Colors.green,
                                '${((approvedReports / (totalReports > 0 ? totalReports : 1)) * 100).toStringAsFixed(0)}% approval rate',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildMetricCard(
                                'Pending Reviews',
                                pendingReports.toString(),
                                Icons.pending,
                                Colors.orange,
                                'Requires attention',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildMetricCard(
                                'Task Completion',
                                '${((completedTasks / (totalTasks > 0 ? totalTasks : 1)) * 100).toStringAsFixed(0)}%',
                                Icons.task_alt,
                                Colors.purple,
                                '$completedTasks of $totalTasks tasks',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Charts Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildReportTrendsChart(totalReports, approvedReports, pendingReports),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              child: _buildTaskStatusBreakdown(totalTasks, completedTasks, pendingTasks),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Activity Summary
                        _buildActivitySummary(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTrendsChart(int total, int approved, int pending) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Status Distribution',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildProgressBar('Approved', approved, total, Colors.green),
          const SizedBox(height: 20),
          _buildProgressBar('Pending', pending, total, Colors.orange),
          const SizedBox(height: 20),
          _buildProgressBar('In Review', total - approved - pending, total, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
        ),
      ],
    );
  }

  Widget _buildTaskStatusBreakdown(int total, int completed, int pending) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildTaskStat('Total Tasks', total, Icons.task, Colors.purple),
          const Divider(height: 30),
          _buildTaskStat('Completed', completed, Icons.check_circle, Colors.green),
          const Divider(height: 30),
          _buildTaskStat('Pending', pending, Icons.pending_actions, Colors.orange),
          const Divider(height: 30),
          _buildTaskStat('In Progress', total - completed - pending, Icons.hourglass_empty, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTaskStat(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/detailed-report');
                },
                child: const Text('View All →'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'System is operating normally. All metrics are within expected ranges.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export detailed analytics reports for deeper insights and compliance documentation.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}