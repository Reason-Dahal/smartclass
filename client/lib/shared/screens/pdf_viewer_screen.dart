import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dio/dio.dart';

class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String title;
  final String fileType;

  const PDFViewerScreen({
    super.key,
    required this.fileUrl,
    required this.title,
    required this.fileType,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  // PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('=== PDFViewer initState ===');
    debugPrint('fileType: "${widget.fileType}"');
    debugPrint('fileUrl: "${widget.fileUrl}"');
    debugPrint('Platform.isAndroid: ${Platform.isAndroid}');

    if (widget.fileType == 'pdf' && (Platform.isAndroid || Platform.isIOS)) {
      _downloadAndLoad();
    } else {
      _openExternal();
    }
  }

  Future<void> _downloadAndLoad() async {
    try {
      debugPrint('=== PDF DOWNLOAD DEBUG ===');
      debugPrint('fileUrl: ${widget.fileUrl}');
      debugPrint('fileType: ${widget.fileType}');
      debugPrint('Attempting download from: ${widget.fileUrl}');

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
      debugPrint('savePath: $filePath');

      final plainDio = Dio();
      final response = await plainDio.download(widget.fileUrl, filePath);
      debugPrint('HTTP status: ${response.statusCode}');

      final file = File(filePath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      debugPrint('File exists: $exists, size: $size bytes');

      if (!mounted) return;
      setState(() {
        _localPath = filePath;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PDF DOWNLOAD ERROR: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load file. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // Download — uses url_launcher so it works on all platforms
  // Android 13+ blocks direct file writes — browser handles it correctly
  Future<void> _downloadToDevice() async {
    try {
      final uri = Uri.parse(widget.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open URL');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Non-PDF or desktop — handled in initState, show brief spinner
    if (widget.fileType != 'pdf' || (!Platform.isAndroid && !Platform.isIOS)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download',
            onPressed: _downloadToDevice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _downloadAndLoad();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() => _totalPages = pages ?? 0),
              onPageChanged: (page, _) =>
                  setState(() => _currentPage = (page ?? 0) + 1),
              // onViewCreated: (controller) => _controller = controller,
              onError: (_) => setState(() {
                _error = 'Could not render PDF.';
                _isLoading = false;
              }),
            ),
      bottomNavigationBar: _totalPages > 0 && _error == null
          ? Container(
              height: 40,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontSize: 13),
              ),
            )
          : null,
    );
  }
}
