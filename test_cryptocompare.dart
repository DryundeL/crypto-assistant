import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final client = http.Client();
  final date = DateTime(2015, 12, 3);
  final timestamp = (date.millisecondsSinceEpoch / 1000).round();
  final symbol = 'BTC';
  final currency = 'USD';
  
  final url = 'https://min-api.cryptocompare.com/data/pricehistorical?fsym=$symbol&tsyms=$currency&ts=$timestamp';
  print('Testing CryptoCompare: $url');
  
  try {
    final response = await client.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
