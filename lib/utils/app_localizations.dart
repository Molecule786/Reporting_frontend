import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Dashboard
      'employee_dashboard': 'Employee Dashboard',
      'admin_dashboard': 'Admin Dashboard',
      'dashboard': 'Dashboard',
      'my_reports': 'My Reports',
      'my_tasks': 'My Tasks',
      'my_leaves': 'My Leaves',
      'welcome': 'Welcome',
      'quick_actions': 'Quick Actions',
      'submit_report': 'Submit Report',
      'request_leave': 'Request Leave',
      'recent_reports': 'Recent Reports',
      'pending_tasks': 'Pending Tasks',
      
      // Report
      'report_title': 'Report Title',
      'description': 'Description',
      'status': 'Status',
      'created_at': 'Created At',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'under_review': 'Under Review',
      
      // Tasks
      'task_title': 'Task Title',
      'due_date': 'Due Date',
      'completed': 'Completed',
      'in_progress': 'In Progress',
      
      // Leaves
      'leave_type': 'Leave Type',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'reason': 'Reason',
      'sick_leave': 'Sick Leave',
      'casual_leave': 'Casual Leave',
      'annual_leave': 'Annual Leave',
      
      // Actions
      'submit': 'Submit',
      'cancel': 'Cancel',
      'edit': 'Edit',
      'delete': 'Delete',
      'view': 'View',
      'logout': 'Logout',
      'profile': 'Profile',
      
      // Messages
      'loading': 'Loading...',
      'no_data': 'No data available',
      'error': 'Error',
      'success': 'Success',
    },
    'ur': {
      // Dashboard
      'employee_dashboard': 'ملازم ڈیش بورڈ',
      'admin_dashboard': 'ایڈمن ڈیش بورڈ',
      'dashboard': 'ڈیش بورڈ',
      'my_reports': 'میری رپورٹیں',
      'my_tasks': 'میرے کام',
      'my_leaves': 'میری چھٹیاں',
      'welcome': 'خوش آمدید',
      'quick_actions': 'فوری اقدامات',
      'submit_report': 'رپورٹ جمع کریں',
      'request_leave': 'چھٹی کی درخواست',
      'recent_reports': 'حالیہ رپورٹیں',
      'pending_tasks': 'زیر التواء کام',
      
      // Report
      'report_title': 'رپورٹ کا عنوان',
      'description': 'تفصیل',
      'status': 'حیثیت',
      'created_at': 'تخلیق کی تاریخ',
      'pending': 'زیر التواء',
      'approved': 'منظور شدہ',
      'rejected': 'مسترد',
      'under_review': 'جائزہ میں',
      
      // Tasks
      'task_title': 'کام کا عنوان',
      'due_date': 'آخری تاریخ',
      'completed': 'مکمل',
      'in_progress': 'جاری',
      
      // Leaves
      'leave_type': 'چھٹی کی قسم',
      'start_date': 'شروع کی تاریخ',
      'end_date': 'اختتام کی تاریخ',
      'reason': 'وجہ',
      'sick_leave': 'بیماری کی چھٹی',
      'casual_leave': 'عام چھٹی',
      'annual_leave': 'سالانہ چھٹی',
      
      // Actions
      'submit': 'جمع کریں',
      'cancel': 'منسوخ کریں',
      'edit': 'ترمیم',
      'delete': 'حذف کریں',
      'view': 'دیکھیں',
      'logout': 'لاگ آؤٹ',
      'profile': 'پروفائل',
      
      // Messages
      'loading': 'لوڈ ہو رہا ہے...',
      'no_data': 'کوئی ڈیٹا دستیاب نہیں',
      'error': 'خرابی',
      'success': 'کامیابی',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  String get employeeDashboard => translate('employee_dashboard');
  String get adminDashboard => translate('admin_dashboard');
  String get dashboard => translate('dashboard');
  String get myReports => translate('my_reports');
  String get myTasks => translate('my_tasks');
  String get myLeaves => translate('my_leaves');
  String get welcome => translate('welcome');
  String get quickActions => translate('quick_actions');
  String get submitReport => translate('submit_report');
  String get requestLeave => translate('request_leave');
  String get recentReports => translate('recent_reports');
  String get pendingTasks => translate('pending_tasks');
  
  String get reportTitle => translate('report_title');
  String get description => translate('description');
  String get status => translate('status');
  String get createdAt => translate('created_at');
  String get pending => translate('pending');
  String get approved => translate('approved');
  String get rejected => translate('rejected');
  String get underReview => translate('under_review');
  
  String get taskTitle => translate('task_title');
  String get dueDate => translate('due_date');
  String get completed => translate('completed');
  String get inProgress => translate('in_progress');
  
  String get leaveType => translate('leave_type');
  String get startDate => translate('start_date');
  String get endDate => translate('end_date');
  String get reason => translate('reason');
  String get sickLeave => translate('sick_leave');
  String get casualLeave => translate('casual_leave');
  String get annualLeave => translate('annual_leave');
  
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get view => translate('view');
  String get logout => translate('logout');
  String get profile => translate('profile');
  
  String get loading => translate('loading');
  String get noData => translate('no_data');
  String get error => translate('error');
  String get success => translate('success');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
