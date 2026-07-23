import 'package:flutter/material.dart';
import '../services/nfc_service.dart';

class NfcScanDialog extends StatefulWidget {
  const NfcScanDialog({super.key});

  static Future<String?> showScanDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NfcScanDialog(),
    );
  }

  @override
  State<NfcScanDialog> createState() => _NfcScanDialogState();
}

class _NfcScanDialogState extends State<NfcScanDialog> {
  final NfcService _nfcService = NfcService();
  String _statusMessage = "Ready to scan. Please tap your NFC card on the back of the device.";
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _startNfcScan();
  }

  @override
  void dispose() {
    _nfcService.stopScan();
    super.dispose();
  }

  void _startNfcScan() async {
    await _nfcService.startScan(
      onTagScanned: (String uid) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _statusMessage = "Card Scanned successfully!\nUID: $uid";
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop(uid);
            }
          });
        }
      },
      onError: (String error) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _statusMessage = error;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.nfc_rounded, color: Colors.emerald, size: 28),
          const SizedBox(width: 10),
          const Text("Scan NFC Card", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          if (_isScanning)
            const SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                color: Colors.emerald,
                strokeWidth: 4,
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.emerald,
              size: 60,
            ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _nfcService.stopScan();
            Navigator.of(context).pop(null);
          },
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
