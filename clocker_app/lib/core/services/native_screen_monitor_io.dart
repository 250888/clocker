import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'screen_monitor_service.dart';
import 'screen_monitor_factory.dart';

ScreenMonitorInterface createScreenMonitor() => NativeScreenMonitorImpl();

class NativeScreenMonitorImpl implements ScreenMonitorInterface {
  Timer? _pollTimer;
  final ScreenMonitorService _monitor = ScreenMonitorService();
  String _lastDetectedApp = '';
  bool _isRunning = false;

  @override
  void startNativeMonitoring() {
    if (_isRunning) return;
    _isRunning = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollForegroundApp();
    });
    _pollForegroundApp();
    debugPrint('Native screen monitor started');
  }

  @override
  void stopNativeMonitoring() {
    _isRunning = false;
    _pollTimer?.cancel();
    debugPrint('Native screen monitor stopped');
  }

  void _pollForegroundApp() {
    if (Platform.isWindows) {
      _getWindowsForegroundApp();
    } else if (Platform.isMacOS) {
      _getMacForegroundApp();
    } else if (Platform.isLinux) {
      _getLinuxForegroundApp();
    }
  }

  void _getWindowsForegroundApp() {
    try {
      final psScript = r'''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError=true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
}
"@

$hwnd = [WinAPI]::GetForegroundWindow()
$procId = 0
[WinAPI]::GetWindowThreadProcessId($hwnd, [ref]$procId) | Out-Null

if ($procId -gt 0) {
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if ($proc) {
        $titleLen = [WinAPI]::GetWindowTextLength($hwnd)
        $title = ""
        if ($titleLen -gt 0) {
            $sb = New-Object System.Text.StringBuilder($titleLen + 1)
            [WinAPI]::GetWindowText($hwnd, $sb, $sb.Capacity) | Out-Null
            $title = $sb.ToString()
        }
        "$($proc.ProcessName)|$title|$($proc.Id)"
    }
}
''';

      final result = Process.runSync('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        psScript,
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          final parts = output.split('|');
          final processName = parts.isNotEmpty ? parts[0] : '';
          final windowTitle = parts.length > 1 ? parts[1] : '';

          if (processName.isNotEmpty && processName != _lastDetectedApp) {
            _lastDetectedApp = processName;
            _monitor.reportForegroundApp(processName);
            debugPrint(
              'Windows foreground: $processName (title: $windowTitle)',
            );
          }
        }
      }
    } catch (e) {
      _getWindowsForegroundAppFallback();
    }
  }

  void _getWindowsForegroundAppFallback() {
    try {
      final result = Process.runSync('powershell', [
        '-NoProfile',
        '-Command',
        r'(Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object -First 1).ProcessName',
      ]);
      if (result.exitCode == 0) {
        final name = result.stdout.toString().trim();
        if (name.isNotEmpty && name != _lastDetectedApp) {
          _lastDetectedApp = name;
          _monitor.reportForegroundApp(name);
        }
      }
    } catch (e) {
      debugPrint('Fallback foreground app error: $e');
    }
  }

  void _getMacForegroundApp() {
    try {
      final result = Process.runSync('osascript', [
        '-e',
        'tell application "System Events" to get name of first application process whose frontmost is true',
      ]);
      if (result.exitCode == 0) {
        final name = result.stdout.toString().trim();
        if (name.isNotEmpty && name != _lastDetectedApp) {
          _lastDetectedApp = name;
          _monitor.reportForegroundApp(name);
        }
      }
    } catch (e) {
      debugPrint('Mac foreground app error: $e');
    }
  }

  void _getLinuxForegroundApp() {
    try {
      final result = Process.runSync('xdotool', [
        'getactivewindow',
        'getwindowname',
      ]);
      if (result.exitCode == 0) {
        final name = result.stdout.toString().trim();
        if (name.isNotEmpty && name != _lastDetectedApp) {
          _lastDetectedApp = name;
          _monitor.reportForegroundApp(name);
        }
      }
    } catch (e) {
      debugPrint('Linux foreground app error: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _isRunning = false;
  }
}
