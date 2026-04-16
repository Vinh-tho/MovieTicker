import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';

abstract class UserProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
    String? gender,
    String? dateOfBirth,
    String? address,
  });
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  UserProfileRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await dioClient.dio.get('/User/profile');
      return _readDataPayload(
        response.data,
        'Không thể lấy thông tin tài khoản',
      );
    } on DioException catch (e) {
      throw ServerException(
        _readErrorMessage(e, 'Không thể lấy thông tin tài khoản'),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
    String? gender,
    String? dateOfBirth,
    String? address,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/User/profile',
        data: {
          'fullName': fullName,
          'phone': phone,
          'gender': _emptyToNull(gender),
          'dateOfBirth': _emptyToNull(dateOfBirth),
          'address': _emptyToNull(address),
        },
      );
      return _readDataPayload(response.data, 'Cập nhật thông tin thất bại');
    } on DioException catch (e) {
      throw ServerException(
        _readErrorMessage(e, 'Cập nhật thông tin thất bại'),
      );
    }
  }

  Map<String, dynamic> _readDataPayload(dynamic raw, String fallbackMessage) {
    final data = _asMap(raw, fallbackMessage);
    if (data['success'] == true && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    throw ServerException(data['message']?.toString() ?? fallbackMessage);
  }

  Map<String, dynamic> _asMap(dynamic raw, String fallbackMessage) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw ServerException(fallbackMessage);
  }

  String _readErrorMessage(DioException error, String fallbackMessage) {
    final raw = error.response?.data;
    if (raw is Map<String, dynamic>) {
      return raw['message']?.toString() ?? fallbackMessage;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded['message']?.toString() ?? fallbackMessage;
        }
      } catch (_) {
        return error.message ?? fallbackMessage;
      }
    }
    return error.message ?? fallbackMessage;
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
