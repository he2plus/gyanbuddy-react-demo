import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/vibration_service.dart';

class VibrationSettingsWidget extends StatefulWidget {
  const VibrationSettingsWidget({super.key});

  @override
  State<VibrationSettingsWidget> createState() => _VibrationSettingsWidgetState();
}

class _VibrationSettingsWidgetState extends State<VibrationSettingsWidget> {
  final VibrationService _vibrationService = VibrationService();
  bool _isVibrationEnabled = true;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkVibrationAvailability();
    _isVibrationEnabled = _vibrationService.isEnabled;
  }

  Future<void> _checkVibrationAvailability() async {
    final available = await _vibrationService.isAvailable;
    setState(() {
      _isAvailable = available;
    });
  }

  void _toggleVibration(bool value) {
    setState(() {
      _isVibrationEnabled = value;
    });
    _vibrationService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.vibration, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Vibration Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isAvailable)
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_isAvailable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        kIsWeb 
                          ? 'Vibration is not supported on web browsers'
                          : 'Vibration is not available on this device',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Vibration'),
              subtitle: const Text('Haptic feedback for interactions'),
              value: _isVibrationEnabled,
              onChanged: _isAvailable ? _toggleVibration : null,
            ),
            if (_isAvailable && _isVibrationEnabled) ...[
              const SizedBox(height: 16),
              const Text(
                'Test Vibration Patterns:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTestButton('Light', () => _vibrationService.lightVibration()),
                  _buildTestButton('Success', () => _vibrationService.successVibration()),
                  _buildTestButton('Error', () => _vibrationService.errorVibration()),
                  _buildTestButton('Navigation', () => _vibrationService.navigationVibration()),
                  _buildTestButton('Selection', () => _vibrationService.selectionVibration()),
                  _buildTestButton('Mission Complete', () => _vibrationService.missionCompleteVibration()),
                  _buildTestButton('Quiz Complete', () => _vibrationService.quizCompleteVibration()),
                  _buildTestButton('Achievement', () => _vibrationService.achievementVibration()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// Simple vibration toggle widget
class VibrationToggleWidget extends StatefulWidget {
  const VibrationToggleWidget({super.key});

  @override
  State<VibrationToggleWidget> createState() => _VibrationToggleWidgetState();
}

class _VibrationToggleWidgetState extends State<VibrationToggleWidget> {
  final VibrationService _vibrationService = VibrationService();
  bool _isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _isVibrationEnabled = _vibrationService.isEnabled;
  }

  void _toggleVibration(bool value) {
    setState(() {
      _isVibrationEnabled = value;
    });
    _vibrationService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Vibration'),
      subtitle: const Text('Haptic feedback'),
      value: _isVibrationEnabled,
      onChanged: _toggleVibration,
      secondary: const Icon(Icons.vibration),
    );
  }
}
