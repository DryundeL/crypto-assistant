import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class CoinDetailScraper {
  final http.Client client;

  CoinDetailScraper({required this.client});

  Future<DateTime?> getGenesisDate(String coinId) async {
    try {
      // Map common symbols (from CryptoCompare) to CoinGecko IDs
      String geckoId = coinId.toLowerCase();
      final Map<String, String> symbolMap = {
        'btc': 'bitcoin',
        'eth': 'ethereum',
        'sol': 'solana',
        'ton': 'the-open-network',
        'doge': 'dogecoin',
        'xrp': 'ripple',
        'ada': 'cardano',
        'avax': 'avalanche-2',
        'dot': 'polkadot',
        'link': 'chainlink',
        'matic': 'matic-network', // or polygon
        'shib': 'shiba-inu',
        'ltc': 'litecoin',
        'uni': 'uniswap',
        'bch': 'bitcoin-cash',
        'near': 'near',
        'apt': 'aptos',
        'atom': 'cosmos',
        'xlm': 'stellar',
        'xmr': 'monero',
        'etc': 'ethereum-classic',
        'not': 'notcoin',
        'dogs': 'dogs-2',
      };
      
      if (symbolMap.containsKey(geckoId)) {
        geckoId = symbolMap[geckoId]!;
      }

      // CoinGecko URL structure: https://www.coingecko.com/en/coins/bitcoin
      final url = 'https://www.coingecko.com/en/coins/$geckoId';
      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final html = response.body;
        
        // Look for "Genesis Date" or similar in the HTML
        // This is fragile and depends on CoinGecko's layout.
        // Example pattern: <span>Genesis Date</span> ... <span>Jan 3, 2009</span>
        
        // Regex to find date pattern like "Jan 3, 2009" or "2009-01-03" near "Genesis Date"
        // Simplistic approach: Look for "Genesis Date" and then grab the next date-like string.
        
        // Note: CoinGecko layout changes. 
        // Let's try a regex that matches common date formats after "Genesis Date"
        
        // Pattern: Genesis Date</div><div ...>Jan 3, 2009</div>
        // Or: <span>Genesis Date</span><span>Jan 3, 2009</span>
        
        // Let's try to find the text "Genesis Date" and then look ahead.
        final genesisIndex = html.indexOf('Genesis Date');
        if (genesisIndex != -1) {
          final snippet = html.substring(genesisIndex, genesisIndex + 200);
          // Look for Month Day, Year (e.g., Jan 3, 2009)
          final dateRegex = RegExp(r'([A-Z][a-z]{2})\s+(\d{1,2}),\s+(\d{4})');
          final match = dateRegex.firstMatch(snippet);
          
          if (match != null) {
            final monthStr = match.group(1);
            final dayStr = match.group(2);
            final yearStr = match.group(3);
            
            final monthMap = {
              'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
              'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
            };
            
            final month = monthMap[monthStr] ?? 1;
            final day = int.parse(dayStr!);
            final year = int.parse(yearStr!);
            
            return DateTime(year, month, day);
          }
        }
      }
    } catch (e) {
      print('Scraper Error: $e');
        return null;
    }
  }

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
        // Look for the table row
        // The structure usually is a table with class 'table' or similar
        // We need to find the row that matches the date (or just the first row since we requested a specific date range)
        
        // Try to find the price in the table
        // Selector might be: table tbody tr td (Price column is usually 2nd or 3rd)
        // Let's try a more robust approach: find the table, then the first row
        
        final rows = document.querySelectorAll('table tbody tr');
        if (rows.isNotEmpty) {
          final firstRow = rows.first;
          final cells = firstRow.querySelectorAll('td');
          
          // Usually: Date, Market Cap, Volume, Open, Close
          // Or: Date, Price, Volume, Market Cap
          // Let's look for a cell that looks like a price
          
          for (var cell in cells) {
            final text = cell.text.trim();
            if (text.startsWith('\$')) {
              // Parse price: $361.05 -> 361.05
              final priceStr = text.replaceAll('\$', '').replaceAll(',', '');
              final price = double.tryParse(priceStr);
              if (price != null) {
                print('Scraped Price: $price');
                return price;
              }
            }
          }
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
