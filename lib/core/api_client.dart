import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint(' [API REQ] ${options.method} -> ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(' [API RES] ${response.statusCode} <- ${response.requestOptions.uri}');
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(' [API ERR] ${error.requestOptions.uri}: ${error.type}');
        }

        final req = error.requestOptions;
        final retries = req.extra['retries'] as int? ?? 0;
        if (req.method == 'GET' && retries < 3 && error.type == DioExceptionType.connectionError) {
          req.extra['retries'] = retries + 1;
          await Future.delayed(Duration(milliseconds: 500 * (retries + 1)));
          try {
            final res = await dio.fetch(req);
            return handler.resolve(res);
          } catch (_) {}
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}