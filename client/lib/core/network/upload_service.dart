import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dio_client.dart';
import 'api_exception.dart';
import '../constants/api_constants.dart';

class UploadService {
  final Dio _dio = DioClient.instance;

  Future<String?> pickAndUploadFile(String uploadEndpoint) async {
    // 1. Open file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'txt', 'ppt'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    // 2. Upload to backend
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });

      final response = await _dio.post(
        uploadEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data['data']['fileUrl'] as String;
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
