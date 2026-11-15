import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';

class MockNetworkInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final AppDatabase _db;
  final Random _random = Random();

  MockNetworkInterceptor(this._prefs, this._db);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final simulate503 =
        _prefs.getBool(AppConstants.prefSimulateHttp503) ?? false;
    if (simulate503 && !options.path.contains('/health')) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage:
                'Service Unavailable (Simulated Recruiter Debug Fault)',
            data: {'error': 'Simulated HTTP 503 Service Unavailable'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    }

    // Configurable 400ms - 850ms latency
    final customLatency = _prefs.getInt(AppConstants.prefSimulatedLatency);
    final latency = customLatency ?? (400 + _random.nextInt(450));
    await Future.delayed(Duration(milliseconds: latency));

    // Handle mock routes
    if (options.path.endsWith('/properties')) {
      final properties = await _db.getAllProperties();
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success',
            'count': properties.length,
            'data': properties.map((p) => p.toMap()).toList(),
          },
        ),
      );
    }

    if (options.path.contains('/properties/') &&
        options.path.endsWith('/shortlist')) {
      final parts = options.path.split('/');
      final propIndex = parts.indexOf('properties');
      if (propIndex != -1 && parts.length > propIndex + 1) {
        final id = parts[propIndex + 1];
        final isShortlisted = options.data?['is_shortlisted'] as bool? ?? false;
        await _db.togglePropertyShortlist(id, isShortlisted);
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'id': id,
              'is_shortlisted': isShortlisted,
            },
          ),
        );
      }
    }

    if (options.path.endsWith('/tours')) {
      if (options.method == 'GET') {
        final tours = await _db.getAllTours();
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': tours.map((t) => t.toMap()).toList(),
            },
          ),
        );
      }
    }

    if (options.path.endsWith('/ar-scans')) {
      if (options.method == 'GET') {
        final scans = await _db.getAllArMeasurements();
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': scans.map((s) => s.toMap()).toList(),
            },
          ),
        );
      }
    }

    // Default pass through or simulated OK
    return handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'success', 'message': 'Mock endpoint response'},
      ),
    );
  }
}
