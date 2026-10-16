// 通过 Chrome DevTools Protocol 操作无头浏览器，用来验证 Web 版真实渲染：
//   dart run tool/web_probe.dart <cdpBase> <输出png> [x1 y1 x2 y2 ...]
//
// 例：
//   dart run tool/web_probe.dart http://127.0.0.1:9222 out.png 65 168
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('用法：dart run tool/web_probe.dart <cdpBase> <out.png> [x y]');
    exit(2);
  }

  final cdpBase = args[0];
  final outputPath = args[1];
  final clickArgs = args.skip(2).map(int.parse).toList(growable: false);
  if (clickArgs.length.isOdd) {
    stderr.writeln('点击坐标需要成对给出');
    exit(2);
  }

  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('$cdpBase/json'));
  final response = await request.close();
  final targets =
      jsonDecode(await response.transform(utf8.decoder).join())
          as List<dynamic>;

  final pages = targets
      .cast<Map<String, dynamic>>()
      .where((target) => target['type'] == 'page')
      .toList(growable: false);
  if (pages.isEmpty) {
    throw StateError('没有可用的页面目标');
  }
  // 浏览器里通常有多个 page（同步页、扩展页等），优先选被测应用。
  final page = pages.firstWhere(
    (target) => !'${target['url']}'.startsWith('edge://'),
    orElse: () => pages.first,
  );
  stdout.writeln('目标页面：${page['url']}');

  final socket = await WebSocket.connect(
    page['webSocketDebuggerUrl'] as String,
  );
  final pending = <int, Completer<Map<String, dynamic>>>{};
  var nextId = 0;

  socket.listen((data) {
    final message = jsonDecode(data as String) as Map<String, dynamic>;
    final id = message['id'];
    if (id is int) {
      pending.remove(id)?.complete(message);
    }
  });

  Future<Map<String, dynamic>> send(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = ++nextId;
    final completer = Completer<Map<String, dynamic>>();
    pending[id] = completer;
    socket.add(
      jsonEncode({'id': id, 'method': method, 'params': params ?? {}}),
    );
    return completer.future;
  }

  await send('Page.enable');

  for (var i = 0; i < clickArgs.length; i += 2) {
    final clickX = clickArgs[i];
    final clickY = clickArgs[i + 1];
    for (final type in ['mousePressed', 'mouseReleased']) {
      await send('Input.dispatchMouseEvent', {
        'type': type,
        'x': clickX,
        'y': clickY,
        'button': 'left',
        'clickCount': 1,
      });
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    stdout.writeln('已点击 ($clickX, $clickY)，等待动画结束…');
    await Future<void>.delayed(const Duration(milliseconds: 2000));
  }

  final shot = await send('Page.captureScreenshot', {'format': 'png'});
  final result = shot['result'] as Map<String, dynamic>;
  final bytes = base64Decode(result['data'] as String);
  await File(outputPath).writeAsBytes(bytes);
  stdout.writeln('截图已保存：$outputPath（${bytes.length} 字节）');

  await socket.close();
  client.close();
}
