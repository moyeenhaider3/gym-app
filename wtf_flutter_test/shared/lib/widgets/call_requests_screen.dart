import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class CallRequestsScreen extends StatefulWidget {
  /// If true, shows trainer view (approve/decline). Otherwise member view.
  final bool isTrainer;

  const CallRequestsScreen({super.key, this.isTrainer = false});

  @override
  State<CallRequestsScreen> createState() => _CallRequestsScreenState();
}

class _CallRequestsScreenState extends State<CallRequestsScreen> {
  final _apiService = ApiService();
  late final CallService _callService;
  late final String _myUserId;
  Timer? _pollTimer;

  List<CallRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _callService = CallService(_apiService);
    final settings = Hive.box('settings');
    _myUserId = settings.get('userId', defaultValue: '') as String;
    _loadRequests();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _loadRequests());
  }

  Future<void> _loadRequests() async {
    try {
      final requests = widget.isTrainer
          ? await _callService.getRequests(trainerId: _myUserId)
          : await _callService.getRequests(memberId: _myUserId);
      if (mounted) {
        setState(() { _requests = requests; _isLoading = false; });
      }
    } catch (e) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isTrainer ? 'Call Requests' : 'My Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No requests yet', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(_requests[index]);
                  },
                ),
    );
  }

  Widget _buildRequestCard(CallRequest cr) {
    final theme = Theme.of(context);
    final schedDate = DateFormat('MMM d, yyyy').format(cr.scheduledDateTime.toLocal());
    final schedTime = DateFormat('h:mm a').format(cr.scheduledDateTime.toLocal());
    final statusColor = cr.isPending
        ? Colors.orange
        : cr.isApproved
            ? Colors.green
            : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('$schedDate at $schedTime', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cr.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (cr.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(cr.note, style: TextStyle(color: Colors.grey.shade600)),
            ],
            if (cr.isDeclined && cr.declineReason != null && cr.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${cr.declineReason}', style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            // Trainer actions
            if (widget.isTrainer && cr.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDeclineDialog(cr),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _approve(cr),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            // Join call button
            if (cr.isJoinable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _joinCall(cr),
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join Call'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(CallRequest cr) async {
    try {
      await _callService.approve(cr.id);
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call approved! ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _showDeclineDialog(CallRequest cr) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Reason'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Optional reason...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (reason != null) {
      try {
        await _callService.decline(cr.id, reason: reason);
        _loadRequests();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  void _joinCall(CallRequest cr) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(callRequest: cr),
      ),
    );
  }
}
