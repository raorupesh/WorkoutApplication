import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../firebase_validations/workout_code_validation.dart';
import '../widgets/recent_performance_widget.dart';

class JoinCompetitiveWorkoutPage extends StatefulWidget {
  @override
  _JoinCompetitiveWorkoutPageState createState() =>
      _JoinCompetitiveWorkoutPageState();
}

class _JoinCompetitiveWorkoutPageState
    extends State<JoinCompetitiveWorkoutPage> {
  final TextEditingController _codeController = TextEditingController();
  final WorkoutCodeService _codeService = WorkoutCodeService();
  bool _isLoading = false;
  bool _isScanning = false;
  final MobileScannerController _scannerController = MobileScannerController();

  /// Validates the entered code and processes it
  Future<void> _validateAndProceed() async {
    String code = _codeController.text.trim();

    if (code.length != 6) {
      _showSnackBar('Please enter a valid 6-digit code');
      return;
    }
    _processCode(code);
  }

  /// Processes the workout code by validating it and navigating accordingly
  Future<void> _processCode(String code) async {
    setState(() => _isLoading = true);

    try {
      final workoutData = await _codeService.validateWorkoutCode(code, 'competitive');

      if (workoutData == null) {
        _showSnackBar('Invalid or expired workout code');
      } else {
        GoRouter.of(context).go('/competitiveWorkoutDetails', extra: {
          'code': code,
          'workoutData': workoutData,
          'isCompetitive': true,
        });
      }
    } catch (e) {
      _showSnackBar('Error validating code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
      }
    }
  }

  /// Toggles between scanning mode and manual entry
  void _toggleScanMode() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  /// Shows a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Join Competitive Workout'),
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
                          _codeController.text = code;
                          _processCode(code);
                        } else {
                          _showSnackBar('Invalid QR code format. Expected a 6-digit code.');
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
