import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class TaskDetailDialog {
  static void show(BuildContext context, Map<String, dynamic> task, bool isAdmin, VoidCallback onUpdate) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description']);
    String status = task['status'] ?? 'pending';
    List<dynamic> existingAttachments = List.from(task['attachments'] ?? []);
    List<dynamic> existingVoiceNotes = List.from(task['voice_notes'] ?? []);
    List<PlatformFile> newFiles = [];
    
    bool isUpdating = false;
    String? errorMessage;

    // Voice recording state
    final AudioRecorder audioRecorder = AudioRecorder();
    final AudioPlayer audioPlayer = AudioPlayer();
    String? recordedPath;
    bool isRecording = false;
    bool isPaused = false;
    bool isPlaying = false;
    bool isPlaybackPaused = false;

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
                  final path = '${directory.path}/task_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                  await audioRecorder.start(const RecordConfig(), path: path);
                }
                setDialogState(() {
                  isRecording = true;
                  isPaused = false;
                  recordedPath = null;
                });
              }
            } catch (e) {
              debugPrint('Error starting recording: $e');
            }
          }

          Future<void> stopRecording() async {
            final path = await audioRecorder.stop();
            setDialogState(() {
              isRecording = false;
              recordedPath = path;
            });
          }

          Future<void> playRecording(String path, bool isRemote) async {
            try {
              if (isPlaybackPaused) {
                await audioPlayer.resume();
              } else {
                await audioPlayer.play(isRemote ? UrlSource(path) : (kIsWeb ? UrlSource(path) : DeviceFileSource(path)));
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
            } catch (e) {
              debugPrint('Error playing recording: $e');
            }
          }

          Future<void> pausePlayback() async {
            await audioPlayer.pause();
            setDialogState(() {
              isPlaying = false;
              isPlaybackPaused = true;
            });
          }

          return Stack(
            children: [
              Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAdmin ? 'Edit Task' : 'Task Details',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              audioRecorder.dispose();
                              audioPlayer.dispose();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      if (errorMessage != null)
                        Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(labelText: 'Title'),
                                readOnly: !isAdmin,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(labelText: 'Description'),
                                maxLines: 3,
                                readOnly: !isAdmin,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: status,
                                    items: ['pending', 'in_progress', 'completed', 'cancelled']
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                                        .toList(),
                                    onChanged: (val) => setDialogState(() => status = val!),
                                  ),
                                ],
                              ),
                              const Divider(),
                              
                              const Text('Multimedia & Files', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              
                              // Existing media
                              if (existingVoiceNotes.isNotEmpty) ...[
                                const Text('Voice Notes:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ...existingVoiceNotes.map((url) => ListTile(
                                  leading: const Icon(Icons.mic, color: Colors.blue),
                                  title: const Text('Voice Note'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.play_arrow),
                                        onPressed: () => playRecording(url, true),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => ApiService.downloadFile(url, 'task_voice_${DateTime.now().millisecondsSinceEpoch}.m4a'),
                                      ),
                                      if (isAdmin)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => setDialogState(() => existingVoiceNotes.remove(url)),
                                        ),
                                    ],
                                  ),
                                )),
                              ],
                              
                              if (existingAttachments.isNotEmpty) ...[
                                const Text('Attachments:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ...existingAttachments.map((url) => ListTile(
                                  leading: Icon(_getFileIcon(url.split('.').last), color: Colors.blue),
                                  title: Text(url.split('/').last),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => ApiService.downloadFile(url, url.split('/').last),
                                      ),
                                      if (isAdmin)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => setDialogState(() => existingAttachments.remove(url)),
                                        ),
                                    ],
                                  ),
                                )),
                              ],
                              
                              const SizedBox(height: 12),
                              // New Uploads
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                                          allowMultiple: true,
                                          type: FileType.custom,
                                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
                                          withData: true,
                                        );
                                        if (result != null) {
                                          setDialogState(() => newFiles.addAll(result.files));
                                        }
                                      },
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text('Add Files'),
                                    ),
                                  ),
                                ],
                              ),
                              if (newFiles.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Wrap(
                                    spacing: 8,
                                    children: newFiles.map((file) => Chip(
                                      label: Text(file.name, style: const TextStyle(fontSize: 10)),
                                      onDeleted: () => setDialogState(() => newFiles.remove(file)),
                                    )).toList(),
                                  ),
                                ),
                              
                              const SizedBox(height: 12),
                              // Voice Recorder
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    if (!isRecording && recordedPath == null)
                                      IconButton(
                                        icon: const Icon(Icons.mic, color: Colors.red),
                                        onPressed: startRecording,
                                        tooltip: 'Record Voice Note',
                                      )
                                    else if (isRecording)
                                      IconButton(
                                        icon: const Icon(Icons.stop, color: Colors.red),
                                        onPressed: stopRecording,
                                      )
                                    else if (recordedPath != null) ...[
                                      IconButton(
                                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.blue),
                                        onPressed: isPlaying ? pausePlayback : () => playRecording(recordedPath!, false),
                                      ),
                                      const Text('Recorded ✓', style: TextStyle(fontSize: 10)),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => setDialogState(() => recordedPath = null),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (isRecording) const Text('Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: isUpdating ? null : () async {
                              setDialogState(() => isUpdating = true);
                              try {
                                List<String> attachmentUrls = List.from(existingAttachments);
                                List<String> voiceNoteUrls = List.from(existingVoiceNotes);

                                // Upload new files
                                for (var file in newFiles) {
                                  String? url;
                                  if (kIsWeb && file.bytes != null) {
                                    url = await ApiService.uploadFileBytes(file.name, file.bytes!);
                                  } else if (file.path != null) {
                                    url = await ApiService.uploadFile(file.path!);
                                  }
                                  if (url != null) attachmentUrls.add(url);
                                }

                                // Upload voice note
                                if (recordedPath != null) {
                                  String? url;
                                  if (kIsWeb) {
                                    final response = await http.get(Uri.parse(recordedPath!));
                                    url = await ApiService.uploadFileBytes('task_voice.m4a', response.bodyBytes);
                                  } else {
                                    url = await ApiService.uploadFile(recordedPath!);
                                  }
                                  if (url != null) voiceNoteUrls.add(url);
                                }

                                final result = await ApiService.updateTask(
                                  taskId: task['_id'],
                                  title: isAdmin ? titleController.text : null,
                                  description: isAdmin ? descriptionController.text : null,
                                  status: status,
                                  attachments: attachmentUrls,
                                  voiceNotes: voiceNoteUrls,
                                );

                                if (result['success']) {
                                  Navigator.pop(context);
                                  onUpdate();
                                } else {
                                  setDialogState(() {
                                    isUpdating = false;
                                    errorMessage = result['error'] ?? 'Update failed';
                                  });
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isUpdating = false;
                                  errorMessage = e.toString();
                                });
                              }
                            },
                            child: isUpdating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUpdating)
                const Positioned.fill(child: Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }

  static IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.article;
      case 'jpg':
      case 'png':
      case 'jpeg': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }
}
