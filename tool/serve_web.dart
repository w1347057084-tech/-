// 本地预览 Web 构建产物：
//   dart run tool/serve_web.dart [端口]
//
// 需要先执行：flutter build web --release
// 启动后本机访问 http://localhost:<端口>/，
// 同一 Wi-Fi 下的手机 / 平板访问 http://<本机局域网 IP>:<端口>/。
import 'dart:io';

const _contentTypes = <String, String>{
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
  '.bin': 'application/octet-stream',
  '.symbols': 'text/plain; charset=utf-8',
};

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);
  final root = Directory('build/web');

  if (!root.existsSync()) {
    stderr.writeln('未找到 build/web，请先执行：flutter build web --release');
    exit(2);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('服务已启动：');
  stdout.writeln('  本机：http://localhost:$port/');
  for (final address in await _lanAddresses()) {
    stdout.writeln('  局域网：http://$address:$port/');
  }
  stdout.writeln('按 Ctrl+C 停止。');

  await for (final request in server) {
    final rawPath = request.uri.path;
    final relative = rawPath == '/' || rawPath.isEmpty
        ? '/index.html'
        : rawPath;
    final file = File('${root.path}$relative');

    if (!file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    final extension = relative.contains('.')
        ? relative.substring(relative.lastIndexOf('.')).toLowerCase()
        : '';
    request.response.headers.contentType = ContentType.parse(
      _contentTypes[extension] ?? 'application/octet-stream',
    );
    // 资源带哈希后缀，避免反复下载；入口文件不缓存，便于更新后立即生效。
    request.response.headers.set(
      'Cache-Control',
      extension == '.html' ? 'no-cache' : 'public, max-age=3600',
    );
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

Future<List<String>> _lanAddresses() async {
  final result = <String>[];
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  )) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) {
        result.add(address.address);
      }
    }
  }
  return result;
}
