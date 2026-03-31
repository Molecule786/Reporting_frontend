import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Full Day';
  String? _halfDayType;
  String _reason = '';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Voice recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedPath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  bool _isPlaybackPaused = false;
  
  // Attachment state
  PlatformFile? _attachedFile;
  bool _isLoading = false;

  final List<String> _leaveTypes = ['Full Day', 'Half Day'];
  final List<String> _halfDayTypes = ['1st Half (Morning)', '2nd Half (Afternoon)'];
  final List<String> _reasons = [
    'Sick Leave',
    'Personal Leave',
    'Emergency',
    'Family Event',
    'Medical Appointment',
    'Other'
  ];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true, // Needed for web generic bytes
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 10MB')),
          );
          return;
        }
        setState(() {
          _attachedFile = file;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: ${file.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(), path: '');
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/leave_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
        }
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordedPath = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordedPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedPath != null) {
      try {
        if (_isPlaybackPaused) {
          await _audioPlayer.resume();
          setState(() {
            _isPlaying = true;
            _isPlaybackPaused = false;
          });
        } else {
          if (kIsWeb) {
            await _audioPlayer.play(UrlSource(_recordedPath!));
          } else {
            await _audioPlayer.play(DeviceFileSource(_recordedPath!));
          }
          setState(() {
            _isPlaying = true;
            _isPlaybackPaused = false;
          });
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _isPlaybackPaused = false;
              });
            }
          });
        }
      } catch (e) {
        debugPrint('Error playing recording: $e');
      }
    }
  }

  Future<void> _pausePlayback() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _isPlaybackPaused = true;
    });
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _isPlaybackPaused = false;
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date')),
      );
      return;
    }

    if (_leaveType == 'Half Day' && _halfDayType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select half day type')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedVoiceUrl;
      String? uploadedAttachmentUrl;

      // Upload voice note
      if (_recordedPath != null) {
        try {
          if (kIsWeb) {
            final response = await http.get(Uri.parse(_recordedPath!));
            uploadedVoiceUrl = await ApiService.uploadFileBytes('voice_note.m4a', response.bodyBytes);
          } else {
            uploadedVoiceUrl = await ApiService.uploadFile(_recordedPath!);
          }
        } catch (e) {
          debugPrint('Voice note upload error: $e');
        }
      }

      // Upload attachment
      if (_attachedFile != null) {
        if (kIsWeb && _attachedFile!.bytes != null) {
          uploadedAttachmentUrl = await ApiService.uploadFileBytes(_attachedFile!.name, _attachedFile!.bytes!);
        } else if (_attachedFile!.path != null) {
          uploadedAttachmentUrl = await ApiService.uploadFile(_attachedFile!.path!);
        }
      }

      final leaveData = {
        'leave_type': _leaveType,
        'half_day_type': _halfDayType,
        'reason': _reason,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        'voice_note_url': uploadedVoiceUrl,
        'attachment_url': uploadedAttachmentUrl,
      };

      await ApiService.createLeave(leaveData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request submitted successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Leave Request'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              
              AppCard(
                child: Column(
                  children: [
                    _buildDropdown('Leave Type', _leaveType, _leaveTypes, (val) {
                      setState(() {
                        _leaveType = val!;
                        if (_leaveType == 'Full Day') _halfDayType = null;
                      });
                    }),
                    if (_leaveType == 'Half Day') ...[
                      const SizedBox(height: 20),
                      _buildHalfDayToggle(),
                    ],
                    const SizedBox(height: 20),
                    _buildDropdown('Reason', _reason.isEmpty ? null : _reason, _reasons, (val) {
                      setState(() => _reason = val!);
                    }, hint: 'Select reason'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    Expanded(child: _buildDatePicker('Start Date', _startDate, true)),
                    if (_leaveType == 'Full Day') ...[
                      const SizedBox(width: 16),
                      Expanded(child: _buildDatePicker('End Date (Optional)', _endDate, false)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Additional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _buildVoiceCard(),
              const SizedBox(height: 12),
              _buildAttachmentCard(),
              
              const SizedBox(height: 40),
              AppButton(
                label: 'Submit Request',
                onPressed: _isLoading ? null : _submitLeave,
                isLoading: _isLoading,
                height: 56,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: hint != null ? Text(hint) : null,
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
          items: items.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHalfDayToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Half Day Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: _halfDayTypes.map((type) {
            final isSelected = _halfDayType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _halfDayType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB)),
                  ),
                  child: Center(
                    child: Text(
                      type.split(' ')[0],
                      style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: date != null ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select',
                style: TextStyle(color: date != null ? AppTheme.textPrimary : AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard() {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _isRecording ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
              color: _isRecording ? AppTheme.error : AppTheme.primary,
              onPressed: _isRecording ? _stopRecording : _startRecording,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voice Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  _recordedPath != null ? 'Voice note recorded ✓' : (_isRecording ? 'Recording...' : 'Tap to explain orally'),
                  style: TextStyle(fontSize: 12, color: _isRecording ? AppTheme.error : AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard() {
    return AppCard(
      onTap: _pickFile,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.attach_file_rounded, color: AppTheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medical Cert / Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  _attachedFile?.name ?? 'Tap to select document',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_attachedFile != null)
            IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _attachedFile = null)),
        ],
      ),
    );
  }
}
