import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 5);
  
  final searches = {
    'Kandy': 'kandy%20sri%20lanka',
    'Trincomalee': 'trincomalee%20sri%20lanka',
    'Hikkaduwa': 'hikkaduwa%20sri%20lanka',
    'Yala': 'yala%20national%20park%20sri%20lanka',
    'Arugam': 'arugam%20bay%20sri%20lanka',
    'Dambulla': 'dambulla%20sri%20lanka',
    'NuwaraEliya': 'nuwara%20eliya%20sri%20lanka',
    'GalleFort': 'galle%20fort%20sri%20lanka',
  };

  print("Querying Pexels for verified photo IDs...");

  for (final entry in searches.entries) {
    final name = entry.key;
    final query = entry.value;
    print("\n--- Searching for $name ($query) ---");

    try {
      final request = await client.getUrl(Uri.parse('https://www.pexels.com/search/$query/'));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36');
      
      final response = await request.close();
      if (response.statusCode != 200) {
        print("Failed to fetch Pexels page for $name: ${response.statusCode}");
        continue;
      }
      
      final html = await response.transform(utf8.decoder).join();
      
      // Match Pexels photo IDs: digits inside photo URL paths
      final regex = RegExp(r'/photo/[a-zA-Z0-9-]+-(\d+)/|images\.pexels\.com/photos/(\d+)/');
      final ids = regex.allMatches(html).map((m) => m.group(1) ?? m.group(2)).where((id) => id != null).toSet().toList();
      
      print("Found ${ids.length} potential IDs for $name. Testing first 5...");
      
      int count = 0;
      for (final id in ids) {
        final testUrl = 'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=800';
        try {
          final testReq = await client.getUrl(Uri.parse(testUrl));
          final testResp = await testReq.close();
          if (testResp.statusCode == 200) {
            print("  WORKING ID for $name: $id => $testUrl");
            count++;
            if (count >= 5) break;
          }
        } catch (_) {}
      }
    } catch (e) {
      print("Error searching $name: $e");
    }
  }

  exit(0);
}
