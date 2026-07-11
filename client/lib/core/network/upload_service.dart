import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dio_client.dart';
import 'api_exception.dart';

class UploadService {
  final Dio _dio = DioClient.instance;

  // Return both fileUrl and fileType
  Future<Map<String, String>?> pickAndUploadFile(String uploadEndpoint) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'txt'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    // Determine file type
    final fileName = file.name.toLowerCase();
    final fileType = fileName.endsWith('.pdf') ? 'pdf' : 'docx';

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });

      final response = await _dio.post(
        uploadEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final fileUrl = response.data['data']['fileUrl'] as String;
      return {'fileUrl': fileUrl, 'fileType': fileType};
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromResponse(
          e.response!.data,
          e.response!.statusCode,
        );
      }
      throw ApiException.networkError();
    }
  }
}
