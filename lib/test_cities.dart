import 'dart:io';

void main() async {
  final urls = [
    'https://images.unsplash.com/photo-1530785602389-07594beb8b73?w=800&q=80',
    'https://images.unsplash.com/photo-1547699326-3d895d9acd30?w=800&q=80',
    'https://images.unsplash.com/photo-1543132685-cd95dd76c03d?w=800&q=80',
    'https://images.unsplash.com/photo-1588598126483-2476d531b70c?w=800&q=80',
    'https://images.unsplash.com/photo-1566296314736-6eaac1ca0cb9?w=800&q=80',
  ];

  final client = HttpClient();
  for (final urlStr in urls) {
    try {
      final req = await client.getUrl(Uri.parse(urlStr));
      final resp = await req.close();
      print('$urlStr => ${resp.statusCode}');
    } catch (e) {
      print('$urlStr => ERROR: $e');
    }
  }
  exit(0);
}
