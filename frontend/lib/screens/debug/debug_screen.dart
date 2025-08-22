import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../services/bitnob_service.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final BitnobService _bitnobService = BitnobService();
  String _connectionStatus = 'Not tested';
  String _apiUrl = '';
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _apiUrl = ApiConfig.baseUrl;
    _addLog('App started successfully');
    _addLog('API URL: $_apiUrl');
    _addLog('Platform: ${ApiConfig.isMobile ? "Mobile" : "Desktop/Web"}');
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toLocal()}: $message');
    });
    print('DEBUG: $message');
  }

  Future<void> _testConnection() async {
    _addLog('Testing connection to backend...');
    setState(() {
      _connectionStatus = 'Testing...';
    });

    try {
      // Test with a simple authentication check - this should fail but show connection is working
      await _bitnobService.signIn('test@example.com', 'password123');
      
      // If we get here, login unexpectedly succeeded
      setState(() {
        _connectionStatus = '✅ Connected & Authenticated';
      });
      _addLog('Connection successful - unexpectedly authenticated');
    } catch (e) {
      // Login failure is expected, but shows backend is reachable
      if (e.toString().contains('Invalid') || 
          e.toString().contains('password') ||
          e.toString().contains('email') ||
          e.toString().contains('Sign in failed')) {
        setState(() {
          _connectionStatus = '✅ Connected (Login failed as expected)';
        });
        _addLog('Connection successful - backend is responding');
      } else if (e.toString().contains('Network error')) {
        setState(() {
          _connectionStatus = '❌ Network Error';
        });
        _addLog('Network error: $e');
        
        // Give specific advice based on error type
        if (e.toString().contains('Connection refused') || 
            e.toString().contains('No route to host')) {
          _addLog('💡 Tip: Make sure your backend server is running on your computer');
          _addLog('💡 Tip: Update the IP address in api_config.dart');
        }
      } else {
        setState(() {
          _connectionStatus = '❌ Connection Error';
        });
        _addLog('Connection failed: $e');
      }
    }
  }

  void _copyLogs() {
    final allLogs = _debugLogs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Debug logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug & Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Card(
              color: _connectionStatus.contains('✅') ? Colors.green.shade50 : 
                     _connectionStatus.contains('❌') ? Colors.red.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _connectionStatus.contains('✅') ? Icons.check_circle :
                      _connectionStatus.contains('❌') ? Icons.error :
                      Icons.info,
                      size: 48,
                      color: _connectionStatus.contains('✅') ? Colors.green :
                             _connectionStatus.contains('❌') ? Colors.red : Colors.blue,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Connection Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(_connectionStatus),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // API Configuration
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('Base URL: $_apiUrl'),
                    Text('Platform: ${ApiConfig.isMobile ? "Mobile" : "Desktop/Web"}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Button
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: Icon(Icons.network_check),
              label: Text('Test Backend Connection'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Debug Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Debug Logs',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: _copyLogs,
                            icon: Icon(Icons.copy),
                            tooltip: 'Copy logs',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _debugLogs.map((log) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Instructions
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Troubleshooting Steps:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Make sure backend server is running on your computer'),
                    Text('2. Find your computer\'s IP address (ipconfig on Windows)'),
                    Text('3. Update _computerIp in api_config.dart with your IP'),
                    Text('4. Make sure phone and computer are on same WiFi'),
                    Text('5. Check firewall isn\'t blocking port 3000'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
