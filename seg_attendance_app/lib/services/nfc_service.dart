import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<String?> readUid({int timeoutSeconds = 20}) async {
    final available = await isAvailable();
    if (!available) return null;

    final completer = Completer<String?>();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final uid = _extractUid(tag);
          if (!completer.isCompleted) {
            completer.complete(uid);
          }
          await stop();
        },
      );

      return await completer.future.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () async {
          await stop();
          return null;
        },
      );
    } catch (_) {
      await stop();
      return null;
    }
  }

  Future<void> startBackgroundScan(
      Function(String uid) onUidDetected) async {
    final available = await isAvailable();
    if (!available) return;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final uid = _extractUid(tag);
          if (uid != null) {
            onUidDetected(uid);
          }
        },
      );
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  String? _extractUid(NfcTag tag) {
    List<int>? identifier;

    try {
      final Object rawData = tag.data;

      if (rawData is! Map) return null;

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        rawData.map((k, v) => MapEntry(k.toString(), v)),
      );

      Map<String, dynamic>? toMap(Object? val) {
        if (val is Map) {
          return Map<String, dynamic>.from(
            val.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
        return null;
      }

      final keys = [
        'nfca',
        'nfcb',
        'nfcf',
        'nfcv',
        'isodep',
        'ndef',
        'mifareultralight',
        'mifaredesfire'
      ];

      for (final key in keys) {
        final section = toMap(data[key]);
        if (section != null && section['identifier'] is List) {
          identifier = List<int>.from(section['identifier'] as List);
          break;
        }
      }
    } catch (_) {}

    if (identifier == null || identifier.isEmpty) return null;

    return identifier
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}