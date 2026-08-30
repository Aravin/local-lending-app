import 'package:dio/dio.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

/// Configured Dio HTTP client with logging, timeout, and base URL interceptors.
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: FlavorConfig.instance.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Dynamic base URL check if updated via flavor
          if (options.baseUrl.isEmpty &&
              FlavorConfig.instance.apiBaseUrl.isNotEmpty) {
            options.baseUrl = FlavorConfig.instance.apiBaseUrl;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Dio get instance => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.put<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.delete<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );
}
