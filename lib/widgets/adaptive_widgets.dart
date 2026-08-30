import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Adaptive button that switches between Material and Cupertino based on platform
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Check if platform is iOS or macOS
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    if (isIOS) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      child: Text(text),
    );
  }
}

// Adaptive switch widget using standard adaptive constructor
class AdaptiveSwitchWidget extends StatefulWidget {
  const AdaptiveSwitchWidget({super.key});

  @override
  State<AdaptiveSwitchWidget> createState() => _AdaptiveSwitchWidgetState();
}

class _AdaptiveSwitchWidgetState extends State<AdaptiveSwitchWidget> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Adaptive Switch: '),
        Switch.adaptive(
          value: _value,
          onChanged: (val) {
            setState(() {
              _value = val;
            });
          },
        ),
      ],
    );
  }
}
