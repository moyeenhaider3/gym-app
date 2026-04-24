import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ScheduleCallScreen extends StatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  State<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends State<ScheduleCallScreen> {
  final _apiService = ApiService();
  late final CallService _callService;
  final _noteController = TextEditingController();

  int _selectedDay = 0; // 0=today, 1=tomorrow, 2=day after
  int? _selectedSlot;
  bool _isSending = false;

  final _days = List.generate(3, (i) => DateTime.now().add(Duration(days: i)));

  List<String> get _timeSlots {
    final slots = <String>[];
    for (int h = 9; h <= 20; h++) {
      slots.add('${h > 12 ? h - 12 : h}:00 ${h >= 12 ? 'PM' : 'AM'}');
      slots.add('${h > 12 ? h - 12 : h}:30 ${h >= 12 ? 'PM' : 'AM'}');
    }
    return slots;
  }

  DateTime _getScheduledDateTime() {
    final day = _days[_selectedDay];
    final slotStr = _timeSlots[_selectedSlot!];
    final isPM = slotStr.contains('PM');
    final parts = slotStr.split(':');
    var hour = int.parse(parts[0]);
    final min = int.parse(parts[1].split(' ')[0]);
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return DateTime(day.year, day.month, day.day, hour, min);
  }

  @override
  void initState() {
    super.initState();
    _callService = CallService(_apiService);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Call')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pick a Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(3, (i) {
                final day = _days[i];
                final label = i == 0 ? 'Today' : (i == 1 ? 'Tomorrow' : DateFormat('EEE').format(day));
                final date = DateFormat('MMM d').format(day);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: ChoiceChip(
                      label: Column(
                        children: [
                          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(date, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      selected: _selectedDay == i,
                      onSelected: (v) => setState(() { _selectedDay = i; _selectedSlot = null; }),
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Pick a Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_timeSlots.length, (i) {
                return ChoiceChip(
                  label: Text(_timeSlots[i], style: const TextStyle(fontSize: 13)),
                  selected: _selectedSlot == i,
                  onSelected: (v) => setState(() => _selectedSlot = v ? i : null),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Add a Note (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: 140,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Macros review, form check...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _selectedSlot != null && !_isSending ? _requestCall : null,
                child: _isSending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Request Call'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCall() async {
    setState(() => _isSending = true);
    try {
      final settings = Hive.box('settings');
      final memberId = settings.get('userId') as String;
      final trainerId = settings.get('trainerId', defaultValue: 'trainer_aarav') as String;
      final scheduledFor = _getScheduledDateTime().toIso8601String();

      await _callService.createRequest(
        memberId: memberId,
        trainerId: trainerId,
        scheduledFor: scheduledFor,
        note: _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call request sent! ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
