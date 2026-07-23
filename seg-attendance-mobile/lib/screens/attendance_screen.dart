import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/attendance_provider.dart';
import '../services/nfc_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../models/attendance_record.dart';
import '../models/learner.dart';
import '../widgets/learner_tile.dart';

class AttendanceScreen extends StatefulWidget {
  final String sessionId;

  const AttendanceScreen({super.key, required this.sessionId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Timer? _pollingTimer;
  final NfcService _nfcService = NfcService();
  final BiometricService _biometricService = BiometricService();
  List<Learner> _cohortLearners = [];
  bool _isNfcActive = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _startPolling();
    _loadCohortLearners();
    _syncNfcScanState();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _nfcService.stopScan();
    super.dispose();
  }

  void _startPolling() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    attendanceProvider.loadAttendanceRecords(widget.sessionId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        attendanceProvider.loadAttendanceRecords(widget.sessionId);
        Provider.of<SessionProvider>(context, listen: false).loadSession(widget.sessionId).then((_) {
          _syncNfcScanState();
        });
      }
    });
  }

  void _loadCohortLearners() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final cohortId = sessionProvider.currentCohort?.cohortId;
    if (cohortId != null) {
      final list = await _apiGetLearners(cohortId);
      setState(() {
        _cohortLearners = list;
      });
    }
  }

  Future<List<Learner>> _apiGetLearners(String cohortId) async {
    try {
      final response = await _apiService.get('/learners?cohort_id=$cohortId');
      return (response.data as List).map((l) => Learner.fromJson(l)).toList();
    } catch (_) {
      return [];
    }
  }

  void _syncNfcScanState() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final session = sessionProvider.currentSession;
    if (session == null || session.endedAt != null) {
      if (_isNfcActive) {
        await _nfcService.stopScan();
        _isNfcActive = false;
      }
      return;
    }

    final bool shouldBeScanning = session.checkinOpen || session.checkoutOpen;

    if (shouldBeScanning && !_isNfcActive) {
      _isNfcActive = true;
      _startNfcScanningLoop();
    } else if (!shouldBeScanning && _isNfcActive) {
      await _nfcService.stopScan();
      _isNfcActive = false;
    }
  }

  void _startNfcScanningLoop() async {
    await _nfcService.startScan(
      onTagScanned: (String uid) async {
        if (mounted) {
          _handleNfcCardTap(uid);
        }
      },
      onError: (String error) {
        // Log or show scan error silently
      },
    );
  }

  void _handleNfcCardTap(String uid) async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final session = sessionProvider.currentSession;

    if (session == null) return;

    // Show indicator
    _showNfcProcessingIndicator(uid);

    // 1. Lookup learner by NFC
    final learner = await attendanceProvider.lookupLearnerByNfc(uid);

    // Close indicator
    if (mounted) Navigator.of(context).pop();

    if (learner == null) {
      _showErrorSnackBar("No learner registered to this NFC Card (UID: $uid)");
      _restartNfcScanStateDelayed();
      return;
    }

    bool success = false;
    String modeText = "";

    // 2. Call check-in or check-out depending on which state is open
    if (session.checkinOpen) {
      modeText = "Check-in";
      success = await attendanceProvider.checkInLearner(
        sessionId: session.sessionId,
        learnerId: learner.learnerId,
        verificationMethod: 'nfc',
      );
    } else if (session.checkoutOpen) {
      modeText = "Check-out";
      success = await attendanceProvider.checkOutLearner(
        sessionId: session.sessionId,
        learnerId: learner.learnerId,
        verificationMethod: 'nfc',
      );
    }

    if (success) {
      _showSuccessSnackBar("$modeText successful for ${learner.fullName} via NFC!");
    } else {
      _showErrorSnackBar(attendanceProvider.errorMessage ?? "$modeText failed for ${learner.fullName}.");
    }

    _restartNfcScanStateDelayed();
  }

  void _restartNfcScanStateDelayed() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _syncNfcScanState();
      }
    });
  }

  void _showNfcProcessingIndicator(String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.emerald),
            const SizedBox(height: 20),
            Text("Processing card UID: $uid"),
          ],
        ),
      ),
    );
  }

  void _verifyFingerprint() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final session = sessionProvider.currentSession;

    if (session == null || (!session.checkinOpen && !session.checkoutOpen)) {
      _showErrorSnackBar("Please open Check-in or Check-out before verifying fingerprint.");
      return;
    }

    // 1. Show selection dialog
    final Learner? selectedLearner = await showDialog<Learner>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Select Learner for Fingerprint"),
        content: SizedBox(
          width: double.maxFinite,
          child: _cohortLearners.isEmpty
              ? const Text("No registered learners in this cohort.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cohortLearners.length,
                  itemBuilder: (context, index) {
                    final l = _cohortLearners[index];
                    return ListTile(
                      title: Text(l.fullName),
                      subtitle: Text(l.segId, style: const TextStyle(fontFamily: 'monospace')),
                      trailing: Icon(
                        l.fingerprintEnrolled ? Icons.fingerprint_rounded : Icons.warning_amber_rounded,
                        color: l.fingerprintEnrolled ? Colors.emerald : Colors.amber,
                      ),
                      onTap: () => Navigator.of(context).pop(l),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (selectedLearner == null) return;

    if (!selectedLearner.fingerprintEnrolled) {
      _showErrorSnackBar("This learner has not enrolled a fingerprint yet.");
      return;
    }

    // 2. Trigger biometric authentication prompt
    try {
      final authenticated = await _biometricService.authenticateLearner();
      if (!authenticated) {
        _showErrorSnackBar("Biometric authentication was cancelled.");
        return;
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    // 3. Post to API
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    bool success = false;
    String modeText = "";

    if (session.checkinOpen) {
      modeText = "Check-in";
      success = await attendanceProvider.checkInLearner(
        sessionId: session.sessionId,
        learnerId: selectedLearner.learnerId,
        verificationMethod: 'fingerprint',
      );
    } else if (session.checkoutOpen) {
      modeText = "Check-out";
      success = await attendanceProvider.checkOutLearner(
        sessionId: session.sessionId,
        learnerId: selectedLearner.learnerId,
        verificationMethod: 'fingerprint',
      );
    }

    if (success) {
      _showSuccessSnackBar("$modeText successful for ${selectedLearner.fullName} via Fingerprint!");
    } else {
      _showErrorSnackBar(attendanceProvider.errorMessage ?? "$modeText failed for ${selectedLearner.fullName}.");
    }
  }

  void _showSuccessSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.emerald),
      );
    }
  }

  void _showErrorSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final session = sessionProvider.currentSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Attendance Session")),
        body: const Center(child: Text("No session is active.")),
      );
    }

    String modeText = "CLOSED";
    Color modeColor = Colors.grey;
    if (session.endedAt != null) {
      modeText = "SESSION ENDED";
      modeColor = Colors.red;
    } else if (session.checkinOpen) {
      modeText = "CHECK-IN OPEN";
      modeColor = Colors.green;
    } else if (session.checkoutOpen) {
      modeText = "CHECK-OUT OPEN";
      modeColor = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.title ?? "Attendance Verification"),
        backgroundColor: Colors.emerald,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current Mode Header
          Container(
            color: modeColor.withOpacity(0.12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  "Verification Status:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  modeText,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: modeColor),
                ),
              ],
            ),
          ),

          // Lifecycle Controls (if session not ended)
          if (session.endedAt == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Toggle Check-in
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sessionProvider.updateCheckinState(!session.checkinOpen),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: session.checkinOpen ? Colors.amber.shade700 : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            session.checkinOpen ? "Close Check-in" : "Open Check-in",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Toggle Check-out
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => sessionProvider.updateCheckoutState(!session.checkoutOpen),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: session.checkoutOpen ? Colors.amber.shade700 : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            session.checkoutOpen ? "Close Check-out" : "Open Check-out",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Verify Fingerprint
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _verifyFingerprint,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text("Verify Fingerprint"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // End Session
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("End Session?"),
                                content: const Text("This will permanently close attendance taking."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("End")),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await sessionProvider.endSession();
                              _syncNfcScanState();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("End Session", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "Attendance List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Live Attendance Records list
          Expanded(
            child: attendanceProvider.records.isEmpty
                ? const Center(
                    child: Text(
                      "No attendance recorded yet.",
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: attendanceProvider.records.length,
                    itemBuilder: (context, index) {
                      final r = attendanceProvider.records[index];
                      String status = "Pending";
                      if (r.isComplete) {
                        status = "Complete";
                      } else if (r.checkedInAt != null) {
                        status = "Checked In";
                      }

                      String details = "Method: ${r.verificationMethod.toUpperCase()}";
                      if (r.checkedInAt != null) {
                        final inTime = DateTime.parse(r.checkedInAt!).toLocal().toIso8601String().substring(11, 19);
                        details += " | In: $inTime";
                      }
                      if (r.checkedOutAt != null) {
                        final outTime = DateTime.parse(r.checkedOutAt!).toLocal().toIso8601String().substring(11, 19);
                        details += " | Out: $outTime";
                      }

                      return LearnerTile(
                        segId: r.segId ?? 'N/A',
                        fullName: r.fullName ?? 'Learner',
                        status: status,
                        timeText: details,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
