import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

/// Convertidor online externo con polling de estado que descarga audio MP3.
class AudioConverterDownloader {
  /// Descarga un archivo MP3 desde el convertidor online loader.to / savenow.to
  static Future<bool> download(
    String youtubeId,
    File destination, {
    Function(double progress, String status)? onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      onProgress?.call(0.12, 'Conectando con servicio de conversión...');
      final req = await client.getUrl(Uri.parse(
        'https://loader.to/ajax/download.php?format=mp3&url=https://www.youtube.com/watch?v=$youtubeId',
      ));
      req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return false;

      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final contentB64 = json['content'] as String?;
      if (contentB64 == null) return false;

      final html = utf8.decode(base64Decode(contentB64));
      final idMatch = RegExp(r'id="(v2_stream_[a-f0-9]+)_downloadLink"').firstMatch(html) ??
          RegExp(r'id="card-(v2_stream_[a-f0-9]+)"').firstMatch(html);
      final streamId = idMatch?.group(1);
      if (streamId == null) return false;

      String? downloadUrl;
      // Polling por hasta 30 segundos
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 1200));
        final pReq = await client.getUrl(Uri.parse('https://p.savenow.to/ajax/progress.php?id=$streamId'));
        pReq.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
        final pRes = await pReq.close().timeout(const Duration(seconds: 8));
        if (pRes.statusCode != 200) continue;

        final pBody = await pRes.transform(utf8.decoder).join();
        final pJson = jsonDecode(pBody) as Map<String, dynamic>;

        final dl = pJson['download_url'] as String?;
        if (dl != null && dl.isNotEmpty) {
          downloadUrl = dl;
          break;
        }

        final pVal = (pJson['progress'] as num?)?.toDouble() ?? 50.0;
        final pNorm = (0.15 + (pVal / 1000.0) * 0.33).clamp(0.15, 0.48);
        final statusText = pJson['text'] as String? ?? 'Preparando audio comprimido...';
        onProgress?.call(pNorm, statusText);
      }

      if (downloadUrl == null || downloadUrl.isEmpty) return false;

      onProgress?.call(0.50, 'Descargando audio...');
      final dReq = await client.getUrl(Uri.parse(downloadUrl));
      final dRes = await dReq.close().timeout(const Duration(seconds: 15));
      if (dRes.statusCode != 200 && dRes.statusCode != 206) return false;

      final totalBytes = dRes.contentLength;
      final fileSink = destination.openWrite();
      int downloaded = 0;

      await for (final chunk in dRes) {
        fileSink.add(chunk);
        downloaded += chunk.length;
        if (totalBytes > 0) {
          final p = 0.50 + (downloaded / totalBytes) * 0.20;
          onProgress?.call(p.clamp(0.50, 0.70), 'Descargando: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
        } else {
          onProgress?.call(0.60, 'Descargando: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
        }
      }
      await fileSink.flush();
      await fileSink.close();

      return downloaded > 50000;
    } catch (e) {
      developer.log('_downloadViaConverter error: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
