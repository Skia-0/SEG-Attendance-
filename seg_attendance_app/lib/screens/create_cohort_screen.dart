import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cohort_provider.dart';

class CreateCohortScreen extends StatefulWidget {
  const CreateCohortScreen({super.key});

  @override
  State<CreateCohortScreen> createState() => _CreateCohortScreenState();
}

class _CreateCohortScreenState extends State<CreateCohortScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minAttendanceController = TextEditingController(text: '80');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minAttendanceController.dispose();
    super.dispose();
  }

  DateTime _todayNormalized() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateApi(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickStartDate() async {
    final today = _todayNormalized();

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6B00),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, push it forward
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final today = _todayNormalized();

    // End date cannot be before today AND cannot be before start date
    final minEndDate =
        _startDate.isAfter(today) ? _startDate : today;

    final initial =
        _endDate.isBefore(minEndDate) ? minEndDate : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minEndDate,
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFFF6B00),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End date must be after start date'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final cohort = await context.read<CohortProvider>().createCohort(
          name: _nameController.text.trim(),
          startDate: _formatDateApi(_startDate),
          endDate: _formatDateApi(_endDate),
          minAttendancePercent:
              int.tryParse(_minAttendanceController.text.trim()) ?? 80,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (cohort != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cohort "${cohort.name}" created!'),
          backgroundColor: const Color(0xFFFF6B00),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create cohort. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CREATE COHORT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Cohort',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up a new learning cohort',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 32),

                // Cohort Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Cohort Name',
                    prefixIcon: Icon(Icons.groups_outlined),
                    hintText: 'e.g. Poultry Management',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a cohort name';
                    }
                    if (v.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Dates section
                const Text(
                  'Dates',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Start Date',
                        value: _formatDate(_startDate),
                        onTap: _pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'End Date',
                        value: _formatDate(_endDate),
                        onTap: _pickEndDate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Min attendance
                const Text(
                  'Attendance Requirement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _minAttendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Attendance %',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    suffixText: '%',
                    hintText: 'e.g. 80',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter minimum attendance';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1 || n > 100) {
                      return 'Must be between 1 and 100';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                const Text(
                  'Learners below this threshold will not '
                  'qualify for certification.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),

                const SizedBox(height: 40),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _create,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Create Cohort'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFFFF6B00),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}