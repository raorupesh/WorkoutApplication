import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericInputWidget extends StatefulWidget {
  final String label; // 'Seconds', 'Meters', or 'Reps'
  final int initialValue;
  final Function(int) onInputChanged;
  final Key? key;

  NumericInputWidget({
    required this.label,
    required this.initialValue,
    required this.onInputChanged,
    this.key,
  }) : super(key: key);

  @override
  _NumericInputWidgetState createState() => _NumericInputWidgetState();
}

class _NumericInputWidgetState extends State<NumericInputWidget> {
  late int value;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
    _controller.text = value.toString(); // Initialize controller with value
  }

  // Increment value
  void _increment() {
    setState(() {
      value++;
      _controller.text = value.toString(); // Update controller with new value
    });
    widget.onInputChanged(value); // Notify parent of change
  }

  // Decrement value
  void _decrement() {
    setState(() {
      if (value > 0) value--; // Prevent going below zero for positive values
      _controller.text = value.toString(); // Update controller with new value
    });
    widget.onInputChanged(value); // Notify parent of change
  }

  // Handle user input change
  void _onChanged(String input) {
    setState(() {
      value = int.tryParse(input) ?? 0; // Parse the input and update value
      _controller.text =
          value.toString(); // Update the controller with parsed value
    });
    widget.onInputChanged(value); // Notify parent of change
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrement Button (for negative or zero-restricted values)
            InkWell(
              onTap: _decrement,
              borderRadius: BorderRadius.circular(30),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 15),

            // TextField for numeric input
            Container(
              width: 80,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.teal.shade200, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: _onChanged,
              ),
            ),
            SizedBox(width: 15),

            // Increment Button
            InkWell(
              onTap: _increment,
              borderRadius: BorderRadius.circular(30),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
