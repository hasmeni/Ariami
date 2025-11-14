import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/server/http_server.dart';
import '../services/desktop_tailscale_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BmaHttpServer _httpServer = BmaHttpServer();
  final DesktopTailscaleService _tailscaleService = DesktopTailscaleService();

  String? _musicFolderPath;
  String? _tailscaleIP;
  bool _isLoading = true;
  int _connectedClients = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load music folder path from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _musicFolderPath = prefs.getString('music_folder_path');

    // Get Tailscale IP and server status
    await _updateServerStatus();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateServerStatus() async {
    // Get Tailscale IP
    final ip = await _tailscaleService.getTailscaleIp();

    // Get connected clients count
    final clientCount = _httpServer.connectionManager.clientCount;

    setState(() {
      _tailscaleIP = ip;
      _connectedClients = clientCount;
    });
  }

  Future<void> _toggleServer() async {
    if (_httpServer.isRunning) {
      // Stop server
      await _httpServer.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server stopped'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Start server
      final ip = await _tailscaleService.getTailscaleIp();
      if (ip == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot start server: Tailscale not connected'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await _httpServer.start(tailscaleIp: ip, port: 8080);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server started'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start server: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    await _updateServerStatus();
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMA Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Status Section
                  const Text(
                    'Server Status',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Status',
                    value: _httpServer.isRunning ? 'Running' : 'Stopped',
                    icon: _httpServer.isRunning ? Icons.check_circle : Icons.cancel,
                    valueColor: _httpServer.isRunning ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  if (_httpServer.isRunning)
                    _buildInfoCard(
                      title: 'Connected Clients',
                      value: _connectedClients.toString(),
                      icon: Icons.devices,
                      valueColor: _connectedClients > 0 ? Colors.green : Colors.grey,
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _toggleServer,
                      icon: Icon(_httpServer.isRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_httpServer.isRunning ? 'Stop Server' : 'Start Server'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: _httpServer.isRunning ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Configuration Section
                  const Text(
                    'Configuration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Music Folder',
                    value: _musicFolderPath ?? 'Not configured',
                    icon: Icons.folder,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Tailscale IP',
                    value: _tailscaleIP ?? 'Not connected',
                    icon: Icons.cloud,
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/folder-selection');
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Change Folder'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/connection');
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Show QR Code'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
