import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../firebase_validations/workout_code_validation.dart';
import '../widgets/recent_performance_widget.dart';

class JoinCompetitiveWorkoutPage extends StatefulWidget {
  @override
  _JoinCompetitiveWorkoutCodePageState createState() =>
      _JoinCompetitiveWorkoutCodePageState();
}

class _JoinCompetitiveWorkoutCodePageState
    extends State<JoinCompetitiveWorkoutPage> {
  final TextEditingController _codeController = TextEditingController();
  final WorkoutCodeService _codeService = WorkoutCodeService();
  bool _isLoading = false;
  bool _isScanning = false;
  final MobileScannerController _scannerController = MobileScannerController();

  Future<void> _validateAndProceed() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    _processCode(_codeController.text);
  }

  Future<void> _processCode(String code) async {
    final context = this.context; // Capture context before async gap.

    setState(() {
      _isLoading = true;
    });

    try {
      final workoutData =
      await _codeService.validateWorkoutCode(code, 'competitive');

      if (workoutData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid or expired workout code')),
          );
        }
      } else {
        // Navigate to competitive workout details using GoRouter
        GoRouter.of(context).go('/competitiveWorkoutResults', extra: {
          'code': code,
          'workoutData': workoutData,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error validating code: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
      }
    }
  }

  void _toggleScanMode() {
    setState(() {
      _isScanning = !_isScanning;
      if (!_isScanning) {
        _scannerController.stop();
      } else {
        _scannerController.start();
      }
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Competitive Workout'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: _toggleScanMode,
            tooltip: _isScanning ? 'Enter Code Manually' : 'Scan QR Code',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isScanning)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && mounted) {
                        final String code = barcodes.first.rawValue ?? '';
                        if (code.length == 6) {
                          // Automatically process the scanned code
                          _processCode(code);
                          // Also update the text controller to show the scanned code
                          _codeController.text = code;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Invalid QR code format. Expected a 6-digit code.')),
                          );
                        }
                      }
                    },
                  ),
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: '6-Digit Workout Code',
                      border: OutlineInputBorder(),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.qr_code_scanner),
                        onPressed: _toggleScanMode,
                        tooltip: 'Scan QR Code',
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, letterSpacing: 10),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _validateAndProceed,
                    child: Text('Join Workout'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            if (!_isScanning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Have a QR code? '),
                    TextButton(
                      onPressed: _toggleScanMode,
                      child: Text('Scan it'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: double.infinity,
          height: 80,
          child: RecentPerformanceWidget(),
        ),
      ),
    );
  }
}