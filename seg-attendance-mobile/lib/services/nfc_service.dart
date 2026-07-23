import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  Future<void> startScan({
    required Function(String uid) onTagScanned,
    required Function(String error) onError,
  }) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError("NFC is not available on this device or is disabled.");
      return;
    }

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Extract the tag identifier (UID)
            List<int>? identifier;

            if (tag.data['isodep'] != null) {
              identifier = (tag.data['isodep']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['nfca'] != null) {
              identifier = (tag.data['nfca']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['mifareultralight'] != null) {
              identifier = (tag.data['mifareultralight']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['ndef'] != null) {
              identifier = (tag.data['ndef']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['nfcb'] != null) {
              identifier = (tag.data['nfcb']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['nfcf'] != null) {
              identifier = (tag.data['nfcf']['identifier'] as List<dynamic>?)?.cast<int>();
            } else if (tag.data['nfcv'] != null) {
              identifier = (tag.data['nfcv']['identifier'] as List<dynamic>?)?.cast<int>();
            }

            if (identifier != null && identifier.isNotEmpty) {
              // Convert List<int> to hex string
              String uid = identifier
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('')
                  .toUpperCase();
              
              await NfcManager.instance.stopSession();
              onTagScanned(uid);
            } else {
              onError("Could not read UID from NFC tag.");
            }
          } catch (e) {
            await NfcManager.instance.stopSession();
            onError("Error processing NFC tag: ${e.toString()}");
          }
        },
      );
    } catch (e) {
      onError("Failed to start NFC scan: ${e.toString()}");
    }
  }

  Future<void> stopScan() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore if session already stopped
    }
  }
}
