import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SoundSettingsWidget extends StatefulWidget {
  const SoundSettingsWidget({super.key});

  @override
  State<SoundSettingsWidget> createState() => _SoundSettingsWidgetState();
}

class _SoundSettingsWidgetState extends State<SoundSettingsWidget> {
  bool _isSoundEnabled = false;
  double _volume = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
  }

  Future<void> _loadSoundSettings() async {
    final soundService = SoundService();
    setState(() {
      _isSoundEnabled = soundService.isSoundEnabled;
      _volume = soundService.volume;
    });
  }

  Future<void> _toggleSound() async {
    final soundService = SoundService();
    await soundService.toggleSound();
    setState(() {
      _isSoundEnabled = soundService.isSoundEnabled;
    });
  }

  Future<void> _setVolume(double volume) async {
    final soundService = SoundService();
    await soundService.setVolume(volume);
    setState(() {
      _volume = volume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sound toggle row
          Row(
            children: [
              Icon(
                _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                color: _isSoundEnabled ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sound Effects',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSoundEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isSoundEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isSoundEnabled,
                onChanged: (value) async {
                  await _toggleSound();
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          
          // Volume control (only show when sound is enabled)
          if (_isSoundEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.volume_down,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) async {
                      await _setVolume(value);
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.volume_up,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_volume * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class SoundSettingsDialog extends StatelessWidget {
  const SoundSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.green),
          SizedBox(width: 8),
          Text('Sound Settings'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoundSettingsWidget(),
          SizedBox(height: 16),
          Text(
            'Sound effects provide haptic feedback for better user experience.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
