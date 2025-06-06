import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChordChip extends StatefulWidget {
  final String chord;
  final double confidence;
  final String? roman;
  final bool isLarge;
  final bool showConfidence;
  final bool showRoman;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChordChip({
    super.key,
    required this.chord,
    required this.confidence,
    this.roman,
    this.isLarge = false,
    this.showConfidence = false,
    this.showRoman = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ChordChip> createState() => _ChordChipState();
}

class _ChordChipState extends State<ChordChip> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    // Start animation when widget is created
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chordColor = AppTheme.getChordColor(widget.chord);
    final confidenceColor = AppTheme.getConfidenceColor(widget.confidence);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildChip(context, chordColor, confidenceColor),
          ),
        );
      },
    );
  }

  Widget _buildChip(BuildContext context, Color chordColor, Color confidenceColor) {
    final size = widget.isLarge ? 80.0 : 60.0;
    final fontSize = widget.isLarge ? 18.0 : 14.0;
    
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress ?? () => _showChordDetails(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              chordColor,
              chordColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(widget.isLarge ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: chordColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: confidenceColor,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Main chord text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.chord,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Roman numeral (if enabled and available)
                  if (widget.showRoman && widget.roman != null)
                    Text(
                      widget.roman!,
                      style: TextStyle(
                        fontSize: fontSize * 0.7,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            
            // Confidence indicator (if enabled)
            if (widget.showConfidence)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: confidenceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${(widget.confidence * 100).round()}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Sparkle effect for high confidence
            if (widget.confidence >= 0.9)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChordDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chord Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Chord', widget.chord),
              if (widget.roman != null)
                _buildDetailRow('Roman Numeral', widget.roman!),
              _buildDetailRow('Confidence', '${(widget.confidence * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Type', _getChordType(widget.chord)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getChordType(String chord) {
    if (chord.contains('dim')) {
      return 'Diminished';
    } else if (chord.contains('maj7')) {
      return 'Major 7th';
    } else if (chord.contains('7') && !chord.contains('maj')) {
      return 'Dominant 7th';
    } else if (chord.contains('m7')) {
      return 'Minor 7th';
    } else if (chord.contains('m') && !chord.contains('maj')) {
      return 'Minor';
    } else if (chord != 'Unknown') {
      return 'Major';
    } else {
      return 'Unknown';
    }
  }
}
