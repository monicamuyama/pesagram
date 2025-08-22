import 'package:flutter/material.dart';
import '../../services/bitnob_service.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  @override
  _TwoFactorAuthScreenState createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final BitnobService _bitnobService = BitnobService();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpRequested = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final result = await _bitnobService.request2faOtp();
      
      if (result['success']) {
        setState(() {
          _otpRequested = true;
          _message = result['message'] ?? 'OTP sent to your registered device';
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to request OTP';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final result = await _bitnobService.verify2faOtp(_otpController.text.trim());
      
      if (result['success']) {
        _showSuccessDialog();
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to verify OTP';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('2FA Verified'),
          ],
        ),
        content: Text(
          'Two-factor authentication has been successfully verified!\n\n'
          'Your account now has an additional layer of security.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _otpRequested = false;
      _message = null;
      _error = null;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Secure Your Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Two-factor authentication adds an extra layer of security to your account. '
                      'You\'ll receive a verification code via SMS or authenticator app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            if (!_otpRequested) ...[
              // Request OTP Step
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 1: Request Verification Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Click the button below to receive a verification code on your registered device.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 16),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sms),
                                  SizedBox(width: 8),
                                  Text('Request Verification Code'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Verify OTP Step
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 2: Enter Verification Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Enter the verification code you received:',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Verification Code',
                          hintText: '000000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                        ),
                        maxLength: 6,
                      ),
                      SizedBox(height: 16),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.verified),
                                  SizedBox(width: 8),
                                  Text('Verify Code'),
                                ],
                              ),
                      ),
                      SizedBox(height: 12),
                      
                      TextButton(
                        onPressed: _resetForm,
                        child: Text('Request New Code'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Messages
            if (_message != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),

            // Security Tips
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Security Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildSecurityTip('• Never share your verification codes with anyone'),
                    _buildSecurityTip('• Codes expire after a few minutes for security'),
                    _buildSecurityTip('• Contact support if you\'re not receiving codes'),
                    _buildSecurityTip('• Enable 2FA on all your important accounts'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(
          color: Colors.orange.shade700,
          fontSize: 13,
        ),
      ),
    );
  }
}
