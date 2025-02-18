import 'package:flutter/material.dart';

class TimeInputWidget extends StatefulWidget {
  final ValueChanged<int> onInputChanged;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final Key? key;

  TimeInputWidget(
      {required this.onInputChanged,
      this.initialValue = 0,
      this.minValue = 0,
      this.maxValue = 300,
      this.key // Default max value is 5 minutes (300 seconds)
      })
      : super(key: key);

  @override
  _TimeSliderWidgetState createState() => _TimeSliderWidgetState();
}

class _TimeSliderWidgetState extends State<TimeInputWidget> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.initialValue.toDouble();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
    });
    widget.onInputChanged(value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Time: ${_sliderValue.toInt()} seconds'),
        Slider(
          value: _sliderValue,
          min: widget.minValue.toDouble(),
          max: widget.maxValue.toDouble(),
          divisions: widget.maxValue - widget.minValue,
          label: _sliderValue.toInt().toString(),
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }
}
