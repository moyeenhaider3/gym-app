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

  /// All possible 30-min slots from 9 AM to 8:30 PM as (hour, minute) pairs.
  List<_TimeSlot> get _allSlots {
    final slots = <_TimeSlot>[];
    for (int h = 9; h <= 20; h++) {
      slots.add(_TimeSlot(h, 0));
      slots.add(_TimeSlot(h, 30));
    }
    return slots;
  }

  /// Bug 4 fix: filter out past slots for today, show all for future days.
  List<_TimeSlot> get _availableSlots {
    final now = DateTime.now();
    final day = _days[_selectedDay];
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

    if (!isToday) return _allSlots;

    return _allSlots.where((slot) {
      final slotTime = DateTime(day.year, day.month, day.day, slot.hour, slot.minute);
      return slotTime.isAfter(now);
    }).toList();
  }

  DateTime _getScheduledDateTime(_TimeSlot slot) {
    final day = _days[_selectedDay];
    return DateTime(day.year, day.month, day.day, slot.hour, slot.minute);
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
    final slots = _availableSlots;

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
            // Bug 4 fix: show message when no slots available
            if (slots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No slots available today. Please select a future date.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(slots.length, (i) {
                  return ChoiceChip(
                    label: Text(slots[i].label, style: const TextStyle(fontSize: 13)),
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
    final slots = _availableSlots;
    if (_selectedSlot == null || _selectedSlot! >= slots.length) return;

    setState(() => _isSending = true);
    try {
      final settings = Hive.box('settings');
      final memberId = settings.get('userId') as String;
      final trainerId = settings.get('trainerId', defaultValue: 'trainer_aarav') as String;
      final scheduledFor = _getScheduledDateTime(slots[_selectedSlot!]).toUtc().toIso8601String();

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

/// Helper class for time slots — cleaner than string parsing.
class _TimeSlot {
  final int hour;
  final int minute;

  const _TimeSlot(this.hour, this.minute);

  String get label {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute == 0 ? '00' : '30';
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
