import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final result = await ApiService.getCurrentUser();
    if (mounted && result['success']) {
      setState(() {
        _userData = result['data'];
        _fullNameController.text = _userData?['full_name'] ?? '';
        _emailController.text = _userData?['email'] ?? '';
        _phoneController.text = _userData?['phone'] ?? '';
        _departmentController.text = _userData?['department'] ?? 'Operations & Safety';
        _locationController.text = _userData?['location'] ?? 'North Sector Facility';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final result = await ApiService.updateUser(
      userId: _userData!['_id'],
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      department: _departmentController.text.trim(),
      location: _locationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {}, // Planned feature
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              const _SectionHeader(title: 'Personal Information'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(label: 'Full Name', controller: _fullNameController, prefixIcon: Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Email Address', controller: _emailController, prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Professional Details
              const _SectionHeader(title: 'Work Information'),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(label: 'Department', controller: _departmentController, prefixIcon: Icons.business_outlined),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Primary Location', controller: _locationController, prefixIcon: Icons.location_on_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact
              const _SectionHeader(title: 'Contact Details'),
              AppCard(
                child: AppTextField(label: 'Phone Number', controller: _phoneController, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              ),
              const SizedBox(height: 48),

              AppButton(
                label: 'Save Changes',
                onPressed: _isSaving ? null : _saveProfile,
                isLoading: _isSaving,
                height: 56,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1),
        ),
      ),
    );
  }

}
