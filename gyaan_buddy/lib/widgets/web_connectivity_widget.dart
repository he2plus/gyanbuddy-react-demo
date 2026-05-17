import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/web_network_service.dart';

/// Widget that shows network connectivity status and helpful error messages for web users
class WebConnectivityWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  
  const WebConnectivityWidget({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<WebConnectivityWidget> createState() => _WebConnectivityWidgetState();
}

class _WebConnectivityWidgetState extends State<WebConnectivityWidget> {
  bool _isChecking = false;
  bool _hasConnection = true;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkConnectivity();
    }
  }

  Future<void> _checkConnectivity() async {
    if (!kIsWeb) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final webService = WebNetworkHelper();
      
      // Check if the service is available
      if (!webService.isAvailable) {
        setState(() {
          _hasConnection = false;
          _lastError = 'Web network service not available';
          _isChecking = false;
        });
        return;
      }
      
      final hasConnection = await webService.hasInternetConnection();
      
      setState(() {
        _hasConnection = hasConnection;
        _lastError = null;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _hasConnection = false;
        _lastError = e.toString();
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    if (_isChecking) {
      return _buildCheckingWidget();
    }

    if (!_hasConnection) {
      return _buildNoConnectionWidget();
    }

    return widget.child;
  }

  Widget _buildCheckingWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Checking network connection...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Network error icon
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'It looks like you\'re having trouble connecting to the internet. This could be due to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Common causes
              _buildCauseItem(
                '• Your internet connection is down',
                Icons.wifi_off,
              ),
              _buildCauseItem(
                '• CORS policy blocking the request',
                Icons.block,
              ),
              _buildCauseItem(
                '• API server is not accessible',
                Icons.cloud_off,
              ),
              const SizedBox(height: 32),
              
              // Error details (if available)
              if (_lastError != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Technical Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _checkConnectivity(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.login),
                      label: const Text('Try Login Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Helpful tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      '💡 Tips:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Check your internet connection\n'
                      '• Try refreshing the page\n'
                      '• Clear browser cache and cookies\n'
                      '• Check if the API server is running',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCauseItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
