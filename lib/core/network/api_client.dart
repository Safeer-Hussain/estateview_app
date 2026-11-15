import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import 'mock_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(SharedPreferences prefs, AppDatabase db) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.estateview.internal/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(MockNetworkInterceptor(prefs, db));
  }
}
