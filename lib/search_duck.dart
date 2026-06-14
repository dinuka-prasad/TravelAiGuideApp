import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  final queries = {
    'Kandy': 'site:pexels.com/photo/ "dalada maligawa" OR "temple of the tooth" OR "kandy lake"',
    'NuwaraEliya': 'site:pexels.com/photo/ "nuwara eliya" tea OR "gregory lake"',
    'Yala': 'site:pexels.com/photo/ "yala" leopard OR elephant OR safari',
    'Trincomalee': 'site:pexels.com/photo/ "trincomalee" koneswaram OR nilaveli OR beach',
    'Hikkaduwa': 'site:pexels.com/photo/ "hikkaduwa" coral OR beach OR turtle',
    'Arugam': 'site:pexels.com/photo/ "arugam bay" surf OR beach',
  };

  print("Querying DuckDuckGo for Pexels photo pages...");

  for (final entry in queries.entries) {
    final name = entry.key;
    final query = entry.value;
    print("\n=== Searching for $name ===");

    try {
      final uri = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36');
      
      final resp = await req.close();
      if (resp.statusCode != 200) {
        print("DuckDuckGo error: ${resp.statusCode}");
        continue;
      }
      
      final html = await resp.transform(utf8.decoder).join();
      
      // Look for pexels.com/photo/... links
      // Format is usually pexels.com/photo/[name]-[id]/ or similar
      final regex = RegExp(r'pexels\.com/photo/[a-zA-Z0-9-]+-(\d+)/?');
      final ids = regex.allMatches(html).map((m) => m.group(1)).where((id) => id != null).toSet().toList();
      
      print("Found ${ids.length} potential Pexels IDs for $name. Testing them...");
      
      int count = 0;
      for (final id in ids) {
        final testUrl = 'https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=800';
        try {
          final testReq = await client.getUrl(Uri.parse(testUrl));
          final testResp = await testReq.close();
          if (testResp.statusCode == 200) {
            print("  [SUCCESS] $name photo: $testUrl");
            count++;
            if (count >= 3) break;
          }
        } catch (_) {}
      }
      if (count == 0) {
        print("  No working photos found for $name.");
      }
    } catch (e) {
      print("Error for $name: $e");
    }
    
    // Pause to avoid rate limits
    await Future.delayed(const Duration(seconds: 2));
  }

  exit(0);
}
