import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/vibration_service.dart';

class VibrationTestWidget extends StatefulWidget {
  const VibrationTestWidget({super.key});

  @override
  State<VibrationTestWidget> createState() => _VibrationTestWidgetState();
}

class _VibrationTestWidgetState extends State<VibrationTestWidget> {
  final VibrationService _vibrationService = VibrationService();
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVibrationAvailability();
  }

  Future<void> _checkVibrationAvailability() async {
    final available = await _vibrationService.isAvailable;
    setState(() {
      _isAvailable = available;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform and availability info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAvailable ? Icons.check_circle : Icons.error,
                                color: _isAvailable ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vibration Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Platform: ${kIsWeb ? "Web" : Theme.of(context).platform.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Available: ${_isAvailable ? "Yes" : "No"}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                          if (!_isAvailable) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kIsWeb 
                                  ? 'Vibration is not supported on web browsers'
                                  : 'Vibration is not available on this device/platform',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Test buttons
                  if (_isAvailable) ...[
                    Text(
                      'Test Vibration Patterns:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildTestButton(
                            'Light\n(50ms)',
                            Icons.touch_app,
                            Colors.blue,
                            () => _vibrationService.lightVibration(),
                          ),
                          _buildTestButton(
                            'Success\n(100ms)',
                            Icons.check_circle,
                            Colors.green,
                            () => _vibrationService.successVibration(),
                          ),
                          _buildTestButton(
                            'Error\n(Pattern)',
                            Icons.error,
                            Colors.red,
                            () => _vibrationService.errorVibration(),
                          ),
                          _buildTestButton(
                            'Navigation\n(30ms)',
                            Icons.navigation,
                            Colors.purple,
                            () => _vibrationService.navigationVibration(),
                          ),
                          _buildTestButton(
                            'Selection\n(40ms)',
                            Icons.radio_button_checked,
                            Colors.orange,
                            () => _vibrationService.selectionVibration(),
                          ),
                          _buildTestButton(
                            'Mission\nComplete',
                            Icons.emoji_events,
                            Colors.amber,
                            () => _vibrationService.missionCompleteVibration(),
                          ),
                          _buildTestButton(
                            'Quiz\nComplete',
                            Icons.quiz,
                            Colors.teal,
                            () => _vibrationService.quizCompleteVibration(),
                          ),
                          _buildTestButton(
                            'Achievement\n(Pattern)',
                            Icons.star,
                            Colors.pink,
                            () => _vibrationService.achievementVibration(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    Color color,
    Future<void> Function() onPressed,
  ) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await onPressed();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Triggered: $label'),
              duration: const Duration(seconds: 1),
              backgroundColor: color,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
