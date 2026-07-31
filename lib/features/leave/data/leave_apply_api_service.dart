import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_service.dart';

class LeaveApplyApiService {
  final ApiService api;

  LeaveApplyApiService(this.api);

  Future<Map<String, dynamic>> sendLeaveRequestWithDocument({
    required Map<String, dynamic> data,
    File? document,
  }) async {
    try {
      final formData = FormData.fromMap(data);

      if (document != null) {
        formData.files.add(
          MapEntry(
            'document',
            await MultipartFile.fromFile(
              document.path,
              filename: document.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await api.postMultipart(
        ApiEndpoints.leaveRequests,
        formData,
      );

      if (response is Map<String, dynamic>) return response;
      if (response is Map) return Map<String, dynamic>.from(response);

      return {'data': response};
    } catch (e) {
      debugPrint('Leave apply failed: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> sendLeaveRequest(
    Map<String, dynamic> data,
  ) async {
    final response = await api.post(ApiEndpoints.leaveRequests, data);

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);

    return {'data': response};
  }
}
