import 'package:dio/dio.dart';
import 'package:habit_flow/features/quotes/models/quote.dart';

class QuoteService {
  QuoteService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://dummyjson.com',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  Future<Quote> fetchRandomQuote() async {
    final response = await _dio.get<Map<String, dynamic>>('/quotes/random');
    final data = response.data;
    if (data == null) {
      throw Exception('Empty response');
    }

    return Quote.fromJson(data);
  }
}
