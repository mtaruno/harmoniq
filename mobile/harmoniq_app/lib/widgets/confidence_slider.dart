import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfidenceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool showLabel;

  const ConfidenceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Threshold: ${(value * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(value),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getConfidenceLabel(value),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryPink,
            inactiveTrackColor: AppTheme.primaryPink.withOpacity(0.3),
            thumbColor: AppTheme.primaryPink,
            overlayColor: AppTheme.primaryPink.withOpacity(0.2),
            valueIndicatorColor: AppTheme.primaryPink,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: 0.5,
            max: 0.95,
            divisions: 45,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
        
        if (showLabel)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '50%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '95%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        Text(
          _getConfidenceDescription(value),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) {
      return Colors.green;
    } else if (confidence >= 0.75) {
      return Colors.orange;
    } else if (confidence >= 0.65) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.85) {
      return 'Very High';
    } else if (confidence >= 0.75) {
      return 'High';
    } else if (confidence >= 0.65) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.85) {
      return 'Only very confident chord detections will be shown';
    } else if (confidence >= 0.75) {
      return 'Most accurate chord detections will be displayed';
    } else if (confidence >= 0.65) {
      return 'Balanced between accuracy and responsiveness';
    } else {
      return 'More chords shown, but may include some inaccuracies';
    }
  }
}
