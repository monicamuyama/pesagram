import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/bitnob_service.dart';
import 'package:image_picker/image_picker.dart';

class KycScreen extends StatefulWidget {
  @override
  _KycScreenState createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idTypeController = TextEditingController();
  final _idNumberController = TextEditingController();
  XFile? _idImage;
  XFile? _selfieImage;
  String? _kycStatus;
  String? _kycRejectionReason;
  bool _loading = false;
  String? _error;

  final BitnobService _service = BitnobService();

  @override
  void initState() {
    super.initState();
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    setState(() { _loading = true; });
    final result = await _service.getKycStatus();
    setState(() {
      _loading = false;
      if (result['success']) {
        _kycStatus = result['data']['kycStatus'];
        _kycRejectionReason = result['data']['kycRejectionReason'];
      } else {
        _error = result['error'];
      }
    });
  }

  Future<void> _pickImage(bool isSelfie) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        if (isSelfie) {
          _selfieImage = picked;
        } else {
          _idImage = picked;
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate() || _idImage == null || _selfieImage == null) {
      setState(() { _error = 'Please fill all fields and upload images.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    final idImageBytes = await _idImage!.readAsBytes();
    final selfieBytes = await _selfieImage!.readAsBytes();
    final result = await _service.submitKyc(
      idType: _idTypeController.text,
      idNumber: _idNumberController.text,
      idImage: base64Encode(idImageBytes),
      selfieImage: base64Encode(selfieBytes),
    );
    setState(() { _loading = false; });
    if (result['success']) {
      _fetchKycStatus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC submitted!')));
    } else {
      setState(() { _error = result['error']; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KYC Verification')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_kycStatus != null) ...[
                    Text('KYC Status: $_kycStatus', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_kycStatus == 'rejected' && _kycRejectionReason != null)
                      Text('Reason: $_kycRejectionReason', style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _idTypeController,
                          decoration: InputDecoration(labelText: 'ID Type (e.g. Passport)'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _idNumberController,
                          decoration: InputDecoration(labelText: 'ID Number'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.image),
                              label: Text(_idImage == null ? 'Upload ID Image' : 'ID Image Selected'),
                              onPressed: () => _pickImage(false),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: Icon(Icons.camera_alt),
                              label: Text(_selfieImage == null ? 'Upload Selfie' : 'Selfie Selected'),
                              onPressed: () => _pickImage(true),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitKyc,
                          child: Text('Submit KYC'),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: 16),
                          Text(_error!, style: TextStyle(color: Colors.red)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class TwoFADialog extends StatefulWidget {
  final BitnobService service;
  final VoidCallback? onVerified;
  const TwoFADialog({required this.service, this.onVerified});
  @override
  _TwoFADialogState createState() => _TwoFADialogState();
}

class _TwoFADialogState extends State<TwoFADialog> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _requestOtp() async {
    setState(() { _loading = true; _error = null; });
    final result = await widget.service.request2faOtp();
    setState(() {
      _loading = false;
      if (result['success']) {
        _info = result['message'];
      } else {
        _error = result['error'];
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = null; });
    final result = await widget.service.verify2faOtp(_otpController.text);
    setState(() { _loading = false; });
    if (result['success']) {
      if (widget.onVerified != null) widget.onVerified!();
      Navigator.of(context).pop(true);
    } else {
      setState(() { _error = result['error']; });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestOtp();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('2FA Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_info != null) Text(_info!, style: TextStyle(color: Colors.green)),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter OTP'),
          ),
          if (_error != null) ...[
            SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _verifyOtp,
          child: _loading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Verify'),
        ),
      ],
    );
  }
} 