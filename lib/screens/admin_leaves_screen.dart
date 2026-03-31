import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminLeavesScreen extends StatefulWidget {
  const AdminLeavesScreen({super.key});

  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _allLeaves = [];
  List<dynamic> _filteredLeaves = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterLeaves(_getFilterForTab(_tabController.index));
      }
    });
    _loadLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFilterForTab(int index) {
    switch (index) {
      case 0:
        return 'all';
      case 1:
        return 'pending';
      case 2:
        return 'approved';
      case 3:
        return 'rejected';
      default:
        return 'all';
    }
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final leaves = await ApiService.getAllLeaves(month: _selectedMonth);
      setState(() {
        _allLeaves = leaves;
        _filterLeaves(_currentFilter);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaves: $e')),
      );
    }
  }

  void _filterLeaves(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter == 'all') {
        _filteredLeaves = _allLeaves;
      } else {
        _filteredLeaves = _allLeaves.where((leave) => leave['status'] == filter).toList();
      }
    });
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      _loadLeaves();
    }
  }

  Future<void> _updateLeaveStatus(String leaveId, String status, String? comment) async {
    try {
      await ApiService.updateLeaveStatus(leaveId, status, comment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave $status successfully')),
      );
      _loadLeaves();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showActionDialog(dynamic leave) {
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Leave Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${leave['user_name']}'),
            const SizedBox(height: 8),
            Text('Leave Type: ${leave['leave_type']}'),
            const SizedBox(height: 8),
            Text('Date: ${leave['start_date']}'),
            const SizedBox(height: 16),
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
          if (leave['status'] != 'rejected')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateLeaveStatus(
                  leave['_id'],
                  'rejected',
                  commentController.text.isEmpty ? null : commentController.text,
                );
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          if (leave['status'] != 'approved')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateLeaveStatus(
                  leave['_id'],
                  'approved',
                  commentController.text.isEmpty ? null : commentController.text,
                );
              },
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLeaveCard(dynamic leave) {
    final status = leave['status'] ?? 'pending';
    final leaveType = leave['leave_type'] ?? 'Full Day';
    final userName = leave['user_name'] ?? 'Unknown';
    final reason = leave['reason'] ?? 'No reason';
    final startDate = leave['start_date'] ?? '';
    final endDate = leave['end_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showActionDialog(leave),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leave['user_email'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    leaveType,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (leave['half_day_type'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(leave['half_day_type']),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Icon(Icons.event_note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(reason),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    endDate != null ? '$startDate to $endDate' : startDate,
                  ),
                ],
              ),

              if (leave['admin_comment'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Comment:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(leave['admin_comment']),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectMonth,
            tooltip: 'Filter by month',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaves,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Month: ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_filteredLeaves.length} leaves',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLeaves.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No leaves found',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeaves,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLeaves.length,
                          itemBuilder: (context, index) {
                            return _buildLeaveCard(_filteredLeaves[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
