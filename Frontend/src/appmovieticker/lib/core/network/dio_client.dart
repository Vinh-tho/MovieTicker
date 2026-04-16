import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import 'http_client_config_stub.dart'
    if (dart.library.io) 'http_client_config_io.dart'
    if (dart.library.html) 'http_client_config_web.dart';

class DioClient {
  final AuthLocalDataSource localDataSource;
  late final Dio dio;

  DioClient({required this.localDataSource}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    configureHttpClientForPlatform(dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await localDataSource.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}
