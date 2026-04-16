import 'package:dio/dio.dart';

void configureHttpClientForPlatform(Dio dio) {
  // Web does not support dart:io HttpClient customization.
}
