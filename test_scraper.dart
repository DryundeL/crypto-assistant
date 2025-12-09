import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() async {
  final scraper = CoinDetailScraper(client: http.Client());
  final date = DateTime(2015, 12, 3);
  print('Testing scraper for Bitcoin on 2015-12-03...');
  final price = await scraper.getHistoricalPrice('bitcoin', date);
  print('Result: $price');
}

class CoinDetailScraper {
  final http.Client client;

  CoinDetailScraper({required this.client});

  Future<double?> getHistoricalPrice(String coinId, DateTime date) async {
    try {
      // CoinGecko format: YYYY-MM-DD
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final url = 'https://www.coingecko.com/en/coins/$coinId/historical_data?start_date=$dateStr&end_date=$dateStr';
      
      print('Scraping Historical Price: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final rows = document.querySelectorAll('table tbody tr');
        if (rows.isNotEmpty) {
          final firstRow = rows.first;
          final cells = firstRow.querySelectorAll('td');
          
          for (var cell in cells) {
            final text = cell.text.trim();
            print('Cell: $text');
            if (text.startsWith('\$')) {
              final priceStr = text.replaceAll('\$', '').replaceAll(',', '');
              final price = double.tryParse(priceStr);
              if (price != null) {
                print('Scraped Price: $price');
                return price;
              }
            }
          }
        } else {
          print('No rows found in table');
        }
      } else {
        print('Scraper Failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Scraper Error: $e');
      return null;
    }
  }
}
