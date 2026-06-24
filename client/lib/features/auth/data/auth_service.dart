import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'];
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);

      // Save token and user to secure storage
      await SecureStorage.saveToken(token);
      await SecureStorage.saveUser(jsonEncode(user.toJson()));

      return user;
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

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        ApiConstants.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
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
