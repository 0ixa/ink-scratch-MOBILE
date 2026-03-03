// lib/features/auth/data/datasources/remote/auth_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ink_scratch/core/services/storage/user_session_service.dart';
import 'package:ink_scratch/core/error/exception.dart';
import 'package:ink_scratch/core/api/api_client.dart';
import 'package:ink_scratch/core/api/api_endpoints.dart';
import 'package:ink_scratch/features/auth/domain/entities/auth_entity.dart';
import 'package:logger/logger.dart';

class AuthRemoteDatasource {
  final ApiClient apiClient;
  final UserSessionService sessionService;
  final Logger logger = Logger();

  AuthRemoteDatasource({required this.apiClient, required this.sessionService});

  /// Register user
  Future<AuthEntity> register({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      logger.d('REGISTER REQUEST:');
      logger.d(
        '   URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.register}',
      );
      logger.d(
        '   Data: { fullName: $fullName, phoneNumber: $phoneNumber, gender: $gender, email: $email, username: $username }',
      );

      final response = await apiClient.client.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'gender': gender,
          'email': email,
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      logger.d(
        'REGISTER RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final token = response.data['token'] as String?;

        if (token != null) {
          await sessionService.saveToken(token);
          logger.d('Token saved: ${token.substring(0, 20)}...');
        }

        return AuthEntity.fromMap(userData, token: token);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      logger.e(
        'REGISTER ERROR: Type: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}, Status: ${e.response?.statusCode}',
      );
      final message =
          e.response?.data['message'] ?? e.message ?? 'Registration failed';
      throw ServerException(message);
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      throw ServerException(e.toString());
    }
  }

  /// Login user
  Future<AuthEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      logger.d(
        'LOGIN REQUEST: URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.login}, Email: $email',
      );

      final response = await apiClient.client.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      logger.d(
        'LOGIN RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final token = response.data['token'] as String;

        await sessionService.saveToken(token);
        logger.d('Token saved: ${token.substring(0, 20)}...');

        return AuthEntity.fromMap(userData, token: token);
      } else {
        throw ServerException(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      logger.e(
        'LOGIN ERROR: Type: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}, Status: ${e.response?.statusCode}',
      );
      final message =
          e.response?.data['message'] ?? e.message ?? 'Login failed';
      throw ServerException(message);
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      throw ServerException(e.toString());
    }
  }

  /// Logout user
  Future<void> logout() async {
    logger.d('LOGOUT: Clearing token...');
    await sessionService.clearToken();
    logger.d('Token cleared');
  }

  /// Update user profile (bio and profile picture)
  Future<AuthEntity> updateProfile({
    String? bio,
    String? profilePicturePath,
  }) async {
    try {
      logger.d('UPDATE PROFILE REQUEST:');
      logger.d(
        '   URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.updateProfile}',
      );
      logger.d('   Bio: $bio, ProfilePicture: $profilePicturePath');

      FormData formData = FormData();

      if (bio != null && bio.isNotEmpty) {
        formData.fields.add(MapEntry('bio', bio));
      }

      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        if (profilePicturePath.startsWith('blob:')) {
          logger.d('   Detected WEB environment (blob URL)');
          try {
            final xFile = XFile(profilePicturePath);
            final bytes = await xFile.readAsBytes();
            final fileName =
                'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
            formData.files.add(
              MapEntry(
                'profileImage',
                MultipartFile.fromBytes(bytes, filename: fileName),
              ),
            );
            logger.d('   Image bytes loaded: ${bytes.length} bytes');
          } catch (e) {
            logger.e('   Error reading image bytes: $e');
            throw ServerException('Failed to read image file');
          }
        } else {
          logger.d('   Detected MOBILE environment (file path)');
          try {
            formData.files.add(
              MapEntry(
                'profileImage',
                await MultipartFile.fromFile(
                  profilePicturePath,
                  filename: profilePicturePath.split('/').last,
                ),
              ),
            );
            logger.d('   File added from path: $profilePicturePath');
          } catch (e) {
            logger.e('   Error reading file: $e');
            throw ServerException('Failed to read image file');
          }
        }
      }

      final response = await apiClient.client.put(
        ApiEndpoints.updateProfile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      logger.d(
        'UPDATE PROFILE RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final token = await sessionService.getToken();
        return AuthEntity.fromMap(userData, token: token);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Profile update failed',
        );
      }
    } on DioException catch (e) {
      logger.e(
        'UPDATE PROFILE ERROR: Type: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}, Status: ${e.response?.statusCode}',
      );
      final message =
          e.response?.data['message'] ?? e.message ?? 'Profile update failed';
      throw ServerException(message);
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      throw ServerException(e.toString());
    }
  }

  /// Request a password reset email
  Future<void> forgotPassword({required String email}) async {
    try {
      logger.d(
        'FORGOT PASSWORD REQUEST: URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.forgotPassword}, Email: $email',
      );

      final response = await apiClient.client.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      logger.d(
        'FORGOT PASSWORD RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      if (response.data['success'] != true) {
        throw ServerException(
          response.data['message'] ?? 'Failed to send reset email',
        );
      }
    } on DioException catch (e) {
      logger.e(
        'FORGOT PASSWORD ERROR: Type: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}',
      );
      final message =
          e.response?.data['message'] ??
          e.message ??
          'Failed to send reset email';
      throw ServerException(message);
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      throw ServerException(e.toString());
    }
  }

  /// Verify if a reset token is still valid
  Future<bool> verifyResetToken({required String token}) async {
    try {
      logger.d(
        'VERIFY RESET TOKEN REQUEST: URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.verifyResetToken(token)}',
      );

      final response = await apiClient.client.get(
        ApiEndpoints.verifyResetToken(token),
      );

      logger.d(
        'VERIFY RESET TOKEN RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      return response.data['success'] == true;
    } on DioException catch (e) {
      logger.e(
        'VERIFY RESET TOKEN ERROR: Status: ${e.response?.statusCode}, Data: ${e.response?.data}',
      );
      // 400 = invalid/expired — treat as false rather than throwing
      return false;
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      return false;
    }
  }

  /// Reset password using token
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      logger.d(
        'RESET PASSWORD REQUEST: URL: ${apiClient.client.options.baseUrl}${ApiEndpoints.resetPassword}',
      );

      final response = await apiClient.client.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );

      logger.d(
        'RESET PASSWORD RESPONSE: Status: ${response.statusCode}, Data: ${response.data}',
      );

      if (response.data['success'] != true) {
        throw ServerException(
          response.data['message'] ?? 'Failed to reset password',
        );
      }
    } on DioException catch (e) {
      logger.e(
        'RESET PASSWORD ERROR: Type: ${e.type}, Message: ${e.message}, Response: ${e.response?.data}',
      );
      final message =
          e.response?.data['message'] ??
          e.message ??
          'Failed to reset password';
      throw ServerException(message);
    } catch (e) {
      logger.e('UNEXPECTED ERROR: $e');
      throw ServerException(e.toString());
    }
  }
}
