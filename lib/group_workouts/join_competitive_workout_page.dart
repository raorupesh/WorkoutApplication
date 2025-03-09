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
    setState(() {
      _isLoading = true;
    });

    try {
      final workoutData =
      await _codeService.validateWorkoutCode(code, 'collaborative');

      if (workoutData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid or expired workout code')),
          );
        }
      } else {
        GoRouter.of(context).go('/collaborativeWorkoutDetails', extra: {
          'code': code,
          'workoutData': workoutData,
          'isCompetitive': false,
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
        leading: IconButton(
            icon: Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Competitive Workout'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          _processCode(code);
                          _codeController.text = code;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid QR code format. Expected a 6-digit code.')),
                          );
                        }
                      }
                    },
                  ),
                ),
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
