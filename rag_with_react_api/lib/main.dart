// ai_assistant.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

// API base URL - replace with your actual ngrok URL when testing
const String apiBaseUrl = "https://e2e1-34-145-27-23.ngrok-free.app"; // Change to your ngrok URL when deployed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgentRAG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AiAssistant2(),
    );
  }
}

class AiAssistant2 extends StatefulWidget {
  const AiAssistant2({Key? key}) : super(key: key);

  @override
  _AiAssistant2State createState() => _AiAssistant2State();
}

class _AiAssistant2State extends State<AiAssistant2> {
  // Chat history with an initial assistant message.
  List<Map<String, String>> chatHistory = [
    {"role": "assistant", "content": "Hello! I'm your AI research assistant. Upload documents and ask me questions about them."}
  ];

  // Controller for the input text field.
  final TextEditingController inputController = TextEditingController();

  // List to store multiple files
  List<Map<String, dynamic>> uploadedFiles = [];
  bool isUploading = false;
  bool isProcessing = false;
  
  // Show error message to user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  // Show success message to user
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> pickFile() async {
    try {
      setState(() {
        isUploading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'csv', 'md'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        // Process each file
        for (var platformFile in result.files) {
          if (kIsWeb) {
            // Handle web upload
            final bytes = platformFile.bytes;
            if (bytes != null) {
              await uploadFileToServer(bytes, platformFile.name, platformFile.size);
            }
          } else {
            // For mobile platforms - handle path-based upload
            if (platformFile.path != null) {
              final file = await http.MultipartFile.fromPath(
                'file', 
                platformFile.path!,
                filename: platformFile.name
              );
              
              final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/upload-file/'));
              request.files.add(file);
              final response = await request.send();
              
              if (response.statusCode == 200) {
                final responseData = await response.stream.toBytes();
                final responseString = String.fromCharCodes(responseData);
                final decodedResponse = jsonDecode(responseString);
                
                setState(() {
                  uploadedFiles.add({
                    'file_id': decodedResponse['file_id'],
                    'name': platformFile.name,
                    'size': platformFile.size,
                  });
                });
              } else {
                _showErrorSnackBar("Failed to upload file: ${platformFile.name}");
              }
            }
          }
        }
        
        if (uploadedFiles.isNotEmpty) {
          _showSuccessSnackBar("${result.files.length} file(s) uploaded successfully");
        }
      }
    } catch (e) {
      print("Error selecting files: $e");
      _showErrorSnackBar("Error selecting files: $e");
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
  
  Future<void> uploadFileToServer(Uint8List bytes, String fileName, int fileSize) async {
    try {
      // Create a multipart request
      final uri = Uri.parse('$apiBaseUrl/upload-file/');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file to request
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        setState(() {
          uploadedFiles.add({
            'file_id': responseData['file_id'],
            'name': fileName,
            'size': fileSize,
          });
        });
      } else {
        _showErrorSnackBar("Failed to upload file: $fileName. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error uploading file to server: $e");
      _showErrorSnackBar("Error uploading file: $e");
    }
  }

  // Remove a file from the list
  void removeFile(int index) {
    setState(() {
      uploadedFiles.removeAt(index);
    });
    // Note: In a complete implementation, you'd also call an API to delete the file from the server
  }

  // Clear all files
  void clearAllFiles() {
    setState(() {
      uploadedFiles.clear();
    });
    _showSuccessSnackBar("All files cleared");
    // Note: In a complete implementation, you'd also call an API to delete all files from the server
  }
  
  // Send message to backend API
  Future<void> handleSend() async {
    final message = inputController.text.trim();
    if (message.isEmpty) return;
    
    // Add user message to chat history
    setState(() {
      chatHistory.add({"role": "user", "content": message});
      inputController.clear();
      isProcessing = true;
    });
    
    try {
      // Send query to the backend
      final response = await http.post(
        Uri.parse('$apiBaseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': message}),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Fix: Ensure that responseData['result'] is properly converted to String
        final result = responseData['result']?.toString() ?? "No response received";
        
        setState(() {
          chatHistory.add({
            "role": "assistant", 
            "content": result
          });
          isProcessing = false;
        });
      } else {
        // Handle error response
        setState(() {
          chatHistory.add({
            "role": "assistant", 
            "content": "Sorry, I encountered an error processing your request. Please try again."
          });
          isProcessing = false;
        });
        _showErrorSnackBar("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending query: $e");
      setState(() {
        chatHistory.add({
          "role": "assistant", 
          "content": "Sorry, I couldn't connect to the server. Please check your connection and try again."
        });
        isProcessing = false;
      });
      _showErrorSnackBar("Connection error: $e");
    }
  }
  
  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Gradient background colors.
    final Color leftColor = const Color(0xFFE2ECFE); // Light blue.
    final Color rightColor = const Color(0xFFF6EEFD); // Light pink.
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradient background.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [leftColor, rightColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // Main Conversation Container with dynamic chat display - full width
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header for conversation.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AgentRAG: Intelligent Document Q&A with AI Agents',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Upload documents and chat with AI',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: const Text(
                                    'Connected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dynamic Chat Display Area: using ListView.builder to display chatHistory.
                  Expanded(
                    child: ListView.builder(
                      itemCount: chatHistory.length,
                      itemBuilder: (context, index) {
                        final message = chatHistory[index];
                        final isUser = message["role"] == "user";
                        return Container(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue.shade100 : const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7),
                            child: Text(
                              message["content"]!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Display uploaded files with clear all button
                  if (uploadedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Uploaded Documents:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        // Add Clear All button
                        TextButton.icon(
                          onPressed: clearAllFiles,
                          icon: Icon(Icons.delete_sweep, size: 16, color: Colors.red.shade700),
                          label: Text(
                            "Clear All",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: uploadedFiles.length > 2 ? 80 : 40,
                      child: ListView.builder(
                        itemCount: uploadedFiles.length,
                        itemBuilder: (context, index) {
                          final file = uploadedFiles[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${file['name']} (${(file['size'] / 1024).toStringAsFixed(2)} KB)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => removeFile(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Bottom Input Row.
                  Row(
                    children: [
                      // Expanded text field.
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: inputController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintText: 'Ask a question about your documents',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.black38,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => handleSend(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // File upload icon button.
                      IconButton(
                        onPressed: isUploading ? null : pickFile,
                        icon: isUploading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.upload_file),
                        tooltip: "Upload multiple files",
                        splashRadius: 24,
                      ),
                      const SizedBox(width: 8),
                      // Send button with loading state
                      ElevatedButton(
                        onPressed: isProcessing ? null : handleSend,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: isProcessing 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              )
                            )
                          : const Text(
                              'Send',
                              style: TextStyle(color: Colors.white),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}