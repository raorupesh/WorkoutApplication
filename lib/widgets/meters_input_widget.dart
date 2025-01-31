import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetersInputWidget extends StatefulWidget {
  final Function(int) onInputChanged;

  MetersInputWidget({required this.onInputChanged});

  @override
  _MetersInputWidgetState createState() => _MetersInputWidgetState();
}

class _MetersInputWidgetState extends State<MetersInputWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      // Restricting to numeric input
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Allow only digits
      ],
      decoration: InputDecoration(labelText: 'Enter distance in meters'),
      onChanged: (value) {
        widget.onInputChanged(
            int.tryParse(value) ?? 0); // Parse integer or default to 0
      },
    );
  }
}
