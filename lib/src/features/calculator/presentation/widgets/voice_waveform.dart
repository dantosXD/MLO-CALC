import 'package:flutter/material.dart';

class VoiceWaveform extends StatelessWidget {
  final bool isListening;
  final double level;

  const VoiceWaveform({
    super.key,
    required this.isListening,
    this.level = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: isListening
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                // Create a visualizer effect using the level. 
                // Level is usually 0..10 or similar depending on plugin, but often db.
                // We'll assume normalized or handle scaling in parent, but for now let's just oscillate.
                
                // If level is constantly changing, this will animate.
                // We use a sine wave pattern combined with the level.
                final active = level > 0.1;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 10.0, end: active ? 10.0 + (level * 20) : 10.0),
                  duration: Duration(milliseconds: 100 + (index * 20)),
                  builder: (context, height, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: height * (index % 2 == 0 ? 1.2 : 0.8),
                      decoration: BoxDecoration(
                        color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                );
              }),
            )
          : const Center(child: Icon(Icons.mic_none, size: 32, color: Colors.grey)),
    );
  }
}
