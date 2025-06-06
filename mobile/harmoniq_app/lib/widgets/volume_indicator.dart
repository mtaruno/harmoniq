import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VolumeIndicator extends StatefulWidget {
  final double volume;
  final bool showLabel;

  const VolumeIndicator({
    super.key,
    required this.volume,
    this.showLabel = false,
  });

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VolumeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate when volume changes
    if (widget.volume != oldWidget.volume) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showLabel)
              Text(
                'Volume: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            
            _buildVolumeBar(),
            
            const SizedBox(width: 8),
            
            Icon(
              _getVolumeIcon(),
              size: 20,
              color: _getVolumeColor(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeBar() {
    const barCount = 5;
    const barWidth = 3.0;
    const barSpacing = 2.0;
    const maxHeight = 20.0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (index) {
        final threshold = (index + 1) / barCount;
        final isActive = widget.volume >= threshold;
        final barHeight = maxHeight * (index + 1) / barCount;
        
        return Container(
          width: barWidth,
          height: barHeight,
          margin: const EdgeInsets.only(right: barSpacing),
          decoration: BoxDecoration(
            color: isActive 
                ? _getVolumeColor().withOpacity(_animation.value)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  IconData _getVolumeIcon() {
    if (widget.volume >= 0.7) {
      return Icons.volume_up;
    } else if (widget.volume >= 0.3) {
      return Icons.volume_down;
    } else if (widget.volume > 0.01) {
      return Icons.volume_mute;
    } else {
      return Icons.volume_off;
    }
  }

  Color _getVolumeColor() {
    if (widget.volume >= 0.7) {
      return Colors.green;
    } else if (widget.volume >= 0.3) {
      return AppTheme.primaryPink;
    } else if (widget.volume > 0.01) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
