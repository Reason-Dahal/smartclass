import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/dio_client.dart';

class PDFViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String title;
  final String fileType; // 'pdf' or 'docx'

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
  PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'pdf') {
      _downloadAndLoad();
    } else {
      // DOCX — open externally immediately
      _openExternal();
    }
  }

  Future<void> _downloadAndLoad() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'preview_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      await DioClient.instance.download(widget.fileUrl, filePath);

      if (!mounted) return;
      setState(() {
        _localPath = filePath;
        _isLoading = false;
      });
    } catch (e) {
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
    // After opening externally, pop this screen
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _downloadToDevice() async {
    try {
      // Android Downloads folder
      const downloadsPath = '/storage/emulated/0/Download';
      final extension = widget.fileType == 'pdf' ? 'pdf' : 'docx';
      final fileName = '${widget.title.replaceAll(' ', '_')}.$extension';
      final savePath = '$downloadsPath/$fileName';

      await DioClient.instance.download(widget.fileUrl, savePath);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to Downloads: $fileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // DOCX files are handled in initState — show loading briefly
    if (widget.fileType != 'pdf') {
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
              onRender: (pages) {
                setState(() => _totalPages = pages ?? 0);
              },
              onPageChanged: (page, _) {
                setState(() => _currentPage = (page ?? 0) + 1);
              },
              onViewCreated: (controller) {
                _controller = controller;
              },
              onError: (error) {
                setState(() {
                  _error = 'Could not render PDF.';
                  _isLoading = false;
                });
              },
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
