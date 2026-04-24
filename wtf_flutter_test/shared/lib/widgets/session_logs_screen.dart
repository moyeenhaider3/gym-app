import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SessionLogsScreen extends StatefulWidget {
  const SessionLogsScreen({super.key});

  @override
  State<SessionLogsScreen> createState() => _SessionLogsScreenState();
}

class _SessionLogsScreenState extends State<SessionLogsScreen> {
  final _apiService = ApiService();
  late final LogService _logService;
  late final String _myUserId;
  Timer? _pollTimer;

  List<SessionLog> _logs = [];
  bool _isLoading = true;
  String _filter = 'all'; // all | 7days | month

  @override
  void initState() {
    super.initState();
    _logService = LogService(_apiService);
    final settings = Hive.box('settings');
    _myUserId = settings.get('userId', defaultValue: '') as String;
    _loadLogs();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _logService.getLogs(userId: _myUserId);
      if (mounted) {
        setState(() { _logs = logs; _isLoading = false; });
      }
    } catch (e) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  List<SessionLog> get _filteredLogs {
    final now = DateTime.now();
    switch (_filter) {
      case '7days':
        return _logs.where((l) => now.difference(l.startDateTime).inDays <= 7).toList();
      case 'month':
        return _logs.where((l) => l.startDateTime.month == now.month && l.startDateTime.year == now.year).toList();
      default:
        return _logs;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredLogs;

    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip('All', 'all', theme),
                const SizedBox(width: 8),
                _filterChip('Last 7 days', '7days', theme),
                const SizedBox(width: 8),
                _filterChip('This Month', 'month', theme),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No sessions yet', style: TextStyle(color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            Text('Schedule a call to get started!', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) => _buildLogCard(filtered[index], theme),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, ThemeData theme) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: _filter == value,
      onSelected: (v) => setState(() => _filter = v ? value : 'all'),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildLogCard(SessionLog log, ThemeData theme) {
    final date = DateFormat('MMM d, yyyy').format(log.startDateTime);
    final time = DateFormat('h:mm a').format(log.startDateTime);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(log),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.video_call, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$date at $time', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Duration: ${log.durationFormatted}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              if (log.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('${log.rating}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(SessionLog log) {
    final date = DateFormat('MMM d, yyyy h:mm a').format(log.startDateTime);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Session Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Date', date),
            _detailRow('Duration', log.durationFormatted),
            if (log.rating != null) _detailRow('Rating', '${log.rating}/5 ⭐'),
            if (log.memberNotes != null && log.memberNotes!.isNotEmpty)
              _detailRow('Member Notes', log.memberNotes!),
            if (log.trainerNotes != null && log.trainerNotes!.isNotEmpty)
              _detailRow('Trainer Notes', log.trainerNotes!),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
