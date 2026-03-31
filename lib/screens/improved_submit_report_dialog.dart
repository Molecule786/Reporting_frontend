import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class ImprovedSubmitReportDialog {
  static void show(BuildContext context, VoidCallback onSuccess) {
    final projectNameController = TextEditingController();
    final projectCodeController = TextEditingController();
    final descriptionController = TextEditingController();
    List<PlatformFile> selectedFiles = [];
    bool isUploading = false;
    String? errorMessage;
    
    // Voice recording state
    final AudioRecorder audioRecorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    String? recordedPath;
    Uint8List? recordedData;
    bool isRecording = false;
    bool isPaused = false;
    bool isPlaying = false;
    bool isPlaybackPaused = false;
    int recordingDuration = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> startRecording() async {
            try {
              if (await audioRecorder.hasPermission()) {
                if (kIsWeb) {
                  await audioRecorder.start(const RecordConfig(), path: '');
                } else {
                  final directory = await getApplicationDocumentsDirectory();
                  final path = '${directory.path}/report_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                  await audioRecorder.start(const RecordConfig(), path: path);
                }
                setDialogState(() {
                  isRecording = true;
                  isPaused = false;
                  recordedPath = null;
                  recordedData = null;
                  recordingDuration = 0;
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
                  SnackBar(content: Text('Recording not available: $e')),
                );
              }
            }
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

          void showPreview(PlatformFile file) {
            final isImage = file.name.toLowerCase().endsWith('.jpg') ||
                file.name.toLowerCase().endsWith('.jpeg') ||
                file.name.toLowerCase().endsWith('.png');

            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      title: Text(file.name, style: const TextStyle(fontSize: 16)),
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: isImage && (file.path != null || file.bytes != null)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb 
                                ? Image.memory(file.bytes!, fit: BoxFit.contain)
                                : Image.network(file.path!, fit: BoxFit.contain),
                            )
                          : Column(
                              children: [
                                const Icon(Icons.insert_drive_file_rounded, size: 64, color: AppTheme.textMuted),
                                const SizedBox(height: 16),
                                Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${(file.size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.assignment_rounded, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Submit Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text('Fill in project details below', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: isUploading ? null : () {
                             audioRecorder.dispose();
                             audioPlayer.dispose();
                             Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.error.withValues(alpha: 0.1))),
                        child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16), const SizedBox(width: 8), Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500)))]),
                      ),
                    ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(label: 'Project Name', controller: projectNameController, prefixIcon: Icons.work_outline_rounded),
                          const SizedBox(height: 16),
                          AppTextField(label: 'Project Code (Optional)', controller: projectCodeController, prefixIcon: Icons.tag_rounded),
                          const SizedBox(height: 16),
                          const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe details...',
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Media Section
                          Row(
                            children: [
                              Expanded(child: _buildIconButton(Icons.mic_rounded, isRecording ? 'Recording...' : 'Voice Note', isRecording ? AppTheme.error : AppTheme.primary, isRecording ? stopRecording : startRecording)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildIconButton(Icons.attach_file_rounded, 'Attach Files', AppTheme.secondary, () async {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'], withData: true);
                                if (result != null) setDialogState(() => selectedFiles.addAll(result.files));
                              })),
                            ],
                          ),

                          if (recordedPath != null || selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text('Attachments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            if (recordedPath != null) _buildVoicePreview(recordedPath!, isPlaying, isPlaybackPaused, pausePlayback, playRecording, () => setDialogState(() { recordedPath = null; audioPlayer.stop(); })),
                            if (selectedFiles.isNotEmpty) _buildFilesList(selectedFiles, (file) => setDialogState(() => selectedFiles.remove(file)), showPreview),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: AppButton(
                      label: 'Submit Report',
                      isLoading: isUploading,
                      onPressed: () async {
                        if (projectNameController.text.isEmpty || descriptionController.text.isEmpty) {
                          setDialogState(() => errorMessage = 'Name and Description are required');
                          return;
                        }
                        setDialogState(() { isUploading = true; errorMessage = null; });
                        try {
                          List<String> aUrls = []; List<String> vUrls = [];
                          if (recordedPath != null) {
                            final url = kIsWeb 
                              ? await ApiService.uploadFileBytes('voice_note.m4a', (await http.get(Uri.parse(recordedPath!))).bodyBytes)
                              : await ApiService.uploadFile(recordedPath!);
                            if (url != null) vUrls.add(url);
                          }
                          for (var f in selectedFiles) {
                            final url = (kIsWeb && f.bytes != null) ? await ApiService.uploadFileBytes(f.name, f.bytes!) : await ApiService.uploadFile(f.path!);
                            if (url != null) aUrls.add(url);
                          }
                          final res = await ApiService.createReport(projectName: projectNameController.text, projectCode: projectCodeController.text, description: descriptionController.text, attachments: aUrls, voiceNotes: vUrls);
                          if (!res['success']) throw Exception(res['error']);
                          if (context.mounted) { 
                            audioRecorder.dispose();
                            audioPlayer.dispose();
                            Navigator.pop(context); 
                            onSuccess(); 
                          }
                        } catch (e) { setDialogState(() { isUploading = false; errorMessage = e.toString(); }); }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildIconButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  static Widget _buildVoicePreview(String path, bool isPlaying, bool isPaused, VoidCallback onPause, VoidCallback onPlay, VoidCallback onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          IconButton(icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppTheme.primary), onPressed: isPlaying ? onPause : onPlay),
          const Expanded(child: Text('Voice Note Recording', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }

  static Widget _buildFilesList(List<PlatformFile> files, Function(PlatformFile) onDelete, Function(PlatformFile) onPreview) {
    return Column(
      children: files.map((f) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(f.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 18), onPressed: () => onPreview(f)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error), onPressed: () => onDelete(f)),
          ],
        ),
      )).toList(),
    );
  }

  static IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) return Icons.article;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png')) return Icons.image;
    return Icons.insert_drive_file;
  }
}
