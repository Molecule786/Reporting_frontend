import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reportsResult = await ApiService.getReports();
      
      if (mounted) {
        if (reportsResult['success']) {
          final reports = reportsResult['data']['reports'] as List;
          _report = reports.firstWhere(
            (r) => r['_id'] == widget.reportId,
            orElse: () => null,
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playVoiceNote(String url) async {
    try {
      if (_isPlaying && _currentlyPlayingUrl == url) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
          _isPaused = true;
        });
      } else if (_isPaused && _currentlyPlayingUrl == url) {
        await _audioPlayer.resume();
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      } else {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _isPlaying = true;
          _isPaused = false;
          _currentlyPlayingUrl = url;
        });
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _isPaused = false;
              _currentlyPlayingUrl = null;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentlyPlayingUrl = null;
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Not Found')),
        body: const Center(child: Text('Could not find the requested report.')),
      );
    }

    final createdAt = _report!['created_at'];
    final formattedDate = createdAt != null 
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(createdAt))
        : 'Unknown Date';
    final status = (_report!['status'] ?? 'pending').toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {}, // Planned feature
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(status, formattedDate),
            const SizedBox(height: 24),

            // Main Content
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Text(
                    _report!['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Assets Section (Voice + Attachments)
            if (_hasAssets()) ...[
              const Text('Media & Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              if (_report!['voice_notes'] != null && (_report!['voice_notes'] as List).isNotEmpty) ...[
                ...(_report!['voice_notes'] as List).map((url) => _buildSaaSVoiceNote(url)),
                const SizedBox(height: 16),
              ],
              if (_report!['attachments'] != null && (_report!['attachments'] as List).isNotEmpty)
                _buildSaaSAttachments(_report!['attachments'] as List),
              const SizedBox(height: 24),
            ],

            // Admin Feedback
            if (_report!['admin_feedback'] != null && _report!['admin_feedback'].toString().isNotEmpty)
              _buildFeedbackSection(),
          ],
        ),
      ),
    );
  }

  bool _hasAssets() {
    final v = _report!['voice_notes'] as List?;
    final a = _report!['attachments'] as List?;
    return (v != null && v.isNotEmpty) || (a != null && a.isNotEmpty);
  }

  Widget _buildHeader(String status, String date) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _report!['project_name'] ?? 'Untitled Project',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            ],
          ),
        ),
        _buildSaaSStatusBadge(status),
      ],
    );
  }

  Widget _buildSaaSStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = AppTheme.success; break;
      case 'rejected': color = AppTheme.error; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSaaSVoiceNote(String url) {
    bool isThisPlaying = _isPlaying && _currentlyPlayingUrl == url;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              color: AppTheme.primary,
              onPressed: () => _playVoiceNote(url),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Note Recording', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Tap to preview audio', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (isThisPlaying)
            const Icon(Icons.equalizer_rounded, color: AppTheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildSaaSAttachments(List attachments) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final url = attachments[index].toString();
        final isImage = url.toLowerCase().contains('.jpg') || url.toLowerCase().contains('.png') || url.toLowerCase().contains('.jpeg');

        return GestureDetector(
          onTap: () => _viewAttachment(url),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              image: isImage ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
            ),
            child: !isImage ? const Center(child: Icon(Icons.insert_drive_file_rounded, color: AppTheme.textMuted)) : null,
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.comment_rounded, size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Reviewer Notes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _report!['admin_feedback'],
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'APPROVED' || status == 'COMPLETED') color = Colors.green;
    if (status == 'REJECTED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }



  Widget _buildVoiceNoteTile(String url) {
    bool isThisPlaying = _isPlaying && _currentlyPlayingUrl == url;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: Colors.blue,
            iconSize: 40,
            onPressed: () => _playVoiceNote(url),
          ),
          if (_currentlyPlayingUrl == url)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              color: Colors.red,
              iconSize: 40,
              onPressed: _stopPlayback,
            ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Click to listen', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsGallery(List attachments) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final url = attachments[index].toString();
        final isImage = url.toLowerCase().contains('.jpg') || 
                        url.toLowerCase().contains('.png') || 
                        url.toLowerCase().contains('.jpeg');

        return GestureDetector(
          onTap: () => _viewAttachment(url),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              image: isImage ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: !isImage ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_drive_file, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text('Document', style: TextStyle(fontSize: 12)),
                ],
              ),
            ) : null,
          ),
        );
      },
    );
  }

  void _viewAttachment(String url) {
    final isImage = url.toLowerCase().contains('.jpg') || 
                    url.toLowerCase().contains('.png') || 
                    url.toLowerCase().contains('.jpeg');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Attachment'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isImage
                  ? Image.network(url, fit: BoxFit.contain)
                  : const Column(
                      children: [
                        Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
                        SizedBox(height: 16),
                        Text('Generic File Attachment'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
