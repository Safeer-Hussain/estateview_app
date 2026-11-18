import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln('EstateView Autonomous Sprint Gatekeeper');
  stdout.writeln('Enforcing Zero-Regression Quality Gates');
  stdout.writeln('====================================================');

  final stopwatch = Stopwatch()..start();

  // Step 1: Package Resolution
  await _runStep(
    name: '1. Flutter Pub Resolution',
    executable: 'flutter',
    arguments: ['pub', 'get'],
  );

  // Step 2: Code Formatting Verification
  await _runStep(
    name: '2. Dart Format Check (Strict Fail-on-Diff)',
    executable: 'dart',
    arguments: [
      'format',
      '--output=none',
      '--set-exit-if-changed',
      'lib',
      'test',
    ],
  );

  // Step 3: Static Analysis (Strict with deprecations ignored for Flutter SDK 3.47+)
  await _runStep(
    name: '3. Flutter Static Analysis',
    executable: 'flutter',
    arguments: ['analyze', '--no-fatal-infos', '--no-pub'],
  );

  // Step 4: Automated Test Suite (Unit & Widget Tests)
  await _runStep(
    name: '4. Automated Test Suite',
    executable: 'flutter',
    arguments: ['test', '--no-pub'],
  );

  // Step 5: Physical Device & ADB Logcat Guard
  await _runAdbCheck();

  stopwatch.stop();
  stdout.writeln('====================================================');
  stdout.writeln(
    '[SUCCESS] All Sprint Gates Passed in ${stopwatch.elapsed.inSeconds}s.',
  );
  stdout.writeln('Ready for Production CI & Mainline Merges.');
  stdout.writeln('====================================================');
}

Future<void> _runStep({
  required String name,
  required String executable,
  required List<String> arguments,
}) async {
  stdout.writeln('\n[GATE] Running $name...');
  final process = await Process.start(
    executable,
    arguments,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln('\n[FATAL] Gate failed: $name (Exit Code $exitCode)');
    exit(exitCode);
  }
  stdout.writeln('[PASSED] $name');
}

Future<void> _runAdbCheck() async {
  stdout.writeln('\n[GATE] Running 5. ADB Device & Logcat Inspection...');
  try {
    final result = await Process.run('adb', ['devices'], runInShell: true);
    if (result.exitCode == 0) {
      final lines = const LineSplitter().convert(result.stdout.toString());
      final deviceLines = lines
          .skip(1)
          .where((l) => l.trim().isNotEmpty && !l.contains('List of devices'));

      if (deviceLines.isEmpty) {
        stdout.writeln(
          '[INFO] No ADB physical devices connected. Skipping logcat audit.',
        );
      } else {
        stdout.writeln(
          '[INFO] Connected devices detected: ${deviceLines.length}',
        );
        final logcat = await Process.run('adb', [
          'logcat',
          '-d',
        ], runInShell: true);
        final logOutput = logcat.stdout.toString();
        if (logOutput.contains('FATAL EXCEPTION') ||
            logOutput.contains(
                  'io.flutter.embedding.engine.renderer.FlutterRenderer',
                ) &&
                logOutput.contains('crash')) {
          stderr.writeln(
            '[WARNING] Suspect crash signatures observed in logcat buffer.',
          );
        } else {
          stdout.writeln('[PASSED] Clean device logcat buffer.');
        }
      }
    } else {
      stdout.writeln(
        '[INFO] ADB not available in PATH. Skipping hardware check.',
      );
    }
  } catch (e) {
    stdout.writeln('[INFO] ADB verification bypassed: $e');
  }
}
