import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureHttpClientForPlatform(Dio dio) {
  if (dio.httpClientAdapter is! IOHttpClientAdapter) {
    return;
  }

  final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
  adapter.createHttpClient = () {
    final client = HttpClient();
    // Support local development certificate on localhost.
    client.badCertificateCallback = (cert, host, port) {
      return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
    };
    return client;
  };
}
