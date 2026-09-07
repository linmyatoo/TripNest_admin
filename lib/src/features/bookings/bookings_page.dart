import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class BookingsPage extends StatefulWidget {
  static const route = '/bookings';
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _confirmingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getOrganizerBookings(status: 'PENDING');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success']) {
        final bookings = result['bookings'] as List? ?? [];
        _bookings =
            bookings.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = result['message'];
      }
    });
  }

  Future<void> _confirm(String bookingId) async {
    setState(() => _confirmingIds.add(bookingId));

    final result = await _apiService.confirmBooking(bookingId);

    if (!mounted) return;
    setState(() => _confirmingIds.remove(bookingId));

    if (result['success']) {
      setState(() {
        final booking = _bookings.firstWhere((b) => b['id'] == bookingId);
        booking['status'] = 'CONFIRMED';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to confirm booking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Approvals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? const Center(
                      child: Text('No pending bookings',
                          style: TextStyle(color: AppColors.muted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BookingCard(
                          booking: _bookings[i],
                          isConfirming:
                              _confirmingIds.contains(_bookings[i]['id']),
                          onConfirm: () => _confirm(_bookings[i]['id']),
                        ),
                      ),
                    ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isConfirming;
  final VoidCallback onConfirm;

  const _BookingCard({
    required this.booking,
    required this.isConfirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final event = booking['event'] as Map?;
    final user = booking['user'] as Map?;
    final eventTitle = event?['title']?.toString() ?? 'Untitled event';
    final buyerName = user?['name']?.toString() ?? 'Unknown';
    final buyerEmail = user?['email']?.toString() ?? '';
    final tickets = booking['ticketCounts'] ?? 0;
    final totalPrice = (booking['totalPrice'] as num?)?.toDouble() ?? 0;
    final isConfirmed = booking['status'] == 'CONFIRMED';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eventTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(buyerEmail.isNotEmpty ? '$buyerName · $buyerEmail' : buyerName,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$tickets ticket${tickets == 1 ? '' : 's'} · ฿${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: (isConfirming || isConfirmed) ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isConfirmed ? Colors.green : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        isConfirmed ? Colors.green : null,
                    disabledForegroundColor: isConfirmed ? Colors.white : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isConfirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isConfirmed ? 'Confirmed' : 'Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
