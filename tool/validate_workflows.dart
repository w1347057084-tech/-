// 校验 .github/workflows 下工作流的 YAML 语法与基本结构，
// 避免推送之后才在 GitHub Actions 页面发现配置无效。
//
// 用法：dart run tool/validate_workflows.dart
import 'dart:io';

import 'package:yaml/yaml.dart';

void main() {
  final dir = Directory('.github/workflows');
  if (!dir.existsSync()) {
    stderr.writeln('未找到 .github/workflows 目录');
    exit(2);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.yml') || file.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('未找到工作流文件');
    exit(2);
  }

  var failures = 0;
  for (final file in files) {
    final problems = <String>[];
    try {
      final document = loadYaml(file.readAsStringSync());
      if (document is! YamlMap) {
        problems.add('顶层内容应为映射（Map）');
      } else {
        // YAML 1.1 解析器会把 `on` 当成布尔值 true，这里两种写法都接受。
        if (document['on'] == null && document[true] == null) {
          problems.add('缺少 on 触发器');
        }
        final jobs = document['jobs'];
        if (jobs is! YamlMap || jobs.isEmpty) {
          problems.add('缺少 jobs');
        } else {
          for (final entry in jobs.entries) {
            final name = entry.key;
            final job = entry.value;
            if (job is! YamlMap) {
              problems.add('job "$name" 应为映射');
              continue;
            }
            if (job['runs-on'] == null) {
              problems.add('job "$name" 缺少 runs-on');
            }
            final steps = job['steps'];
            if (steps is! YamlList || steps.isEmpty) {
              problems.add('job "$name" 缺少 steps');
              continue;
            }
            for (var i = 0; i < steps.length; i++) {
              final step = steps[i];
              if (step is! YamlMap) {
                problems.add('job "$name" 的第 ${i + 1} 个 step 应为映射');
                continue;
              }
              if (step['uses'] == null && step['run'] == null) {
                problems.add('job "$name" 的第 ${i + 1} 个 step 既没有 uses 也没有 run');
              }
            }
          }
        }
      }
    } on YamlException catch (error) {
      problems.add('YAML 解析失败：${error.message}（第 ${(error.span?.start.line ?? 0) + 1} 行）');
    }

    if (problems.isEmpty) {
      stdout.writeln('OK   ${file.path}');
    } else {
      failures++;
      stderr.writeln('FAIL ${file.path}');
      for (final problem in problems) {
        stderr.writeln('     - $problem');
      }
    }
  }

  if (failures > 0) {
    stderr.writeln('$failures 个工作流文件未通过校验');
    exit(1);
  }
  stdout.writeln('${files.length} 个工作流文件全部通过校验');
}
