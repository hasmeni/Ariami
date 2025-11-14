import 'dart:io';

/// Service for managing Tailscale on desktop
class DesktopTailscaleService {
  /// Get the Tailscale IP address by checking network interfaces
  Future<String?> getTailscaleIp() async {
    try {
      // Use ifconfig to get network interfaces (no sudo required)
      final result = await Process.run('ifconfig', []);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final ip = _extractTailscaleIp(output);

        if (ip != null) {
          print('Tailscale IP: $ip');
          return ip;
        } else {
          print('Tailscale IP not found in network interfaces');
        }
      } else {
        print('Failed to get network interfaces: ${result.stderr}');
      }
    } catch (e) {
      print('Error getting Tailscale IP: $e');
    }

    return null;
  }

  /// Extract Tailscale IP from ifconfig output
  String? _extractTailscaleIp(String ifconfigOutput) {
    final lines = ifconfigOutput.split('\n');
    bool inTailscaleInterface = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Tailscale typically uses utun interfaces on macOS
      if (line.startsWith('utun') && line.contains(':')) {
        inTailscaleInterface = true;
      } else if (line.startsWith(RegExp(r'[a-z]')) && !line.startsWith('\t') && !line.startsWith(' ')) {
        // New interface started, reset flag
        inTailscaleInterface = false;
      }

      // Look for inet line with 100.x.x.x (Tailscale CGNAT range)
      if (inTailscaleInterface && line.trim().startsWith('inet ')) {
        final parts = line.trim().split(' ');
        if (parts.length >= 2) {
          final ip = parts[1];
          // Tailscale uses 100.64.0.0/10 CGNAT range
          if (ip.startsWith('100.')) {
            return ip;
          }
        }
      }
    }

    return null;
  }

  /// Check if Tailscale is installed
  Future<bool> isTailscaleInstalled() async {
    final path = await _findTailscalePath();
    return path != null;
  }

  /// Check if Tailscale is running
  Future<bool> isTailscaleRunning() async {
    final ip = await getTailscaleIp();
    return ip != null;
  }

  /// Find the Tailscale binary path
  Future<String?> _findTailscalePath() async {
    // Common Tailscale installation paths
    final possiblePaths = [
      '/opt/homebrew/bin/tailscale',
      '/usr/local/bin/tailscale',
      '/usr/bin/tailscale',
      'C:\\Program Files\\Tailscale\\tailscale.exe', // Windows
    ];

    // Check each path
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    // Try using 'which' on Unix-like systems
    if (!Platform.isWindows) {
      try {
        final result = await Process.run('which', ['tailscale']);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) {
            return path;
          }
        }
      } catch (e) {
        // Ignore and continue
      }
    }

    // Try using 'where' on Windows
    if (Platform.isWindows) {
      try {
        final result = await Process.run('where', ['tailscale']);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) {
            return path.split('\n').first.trim();
          }
        }
      } catch (e) {
        // Ignore and continue
      }
    }

    return null;
  }
}
