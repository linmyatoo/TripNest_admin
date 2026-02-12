import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class SalesPage extends StatefulWidget {
  static const route = '/sales';
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  double _totalRevenue = 0;
  int _totalBookings = 0;
  int _totalTickets = 0;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await Future.wait([
      _apiService.getDashboardRevenue(),
      _apiService.getDashboardEvents(),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;

        // Revenue data
        if (results[0]['success']) {
          _totalRevenue = results[0]['totalRevenue'] ?? 0.0;
          _totalBookings = results[0]['totalBookings'] ?? 0;
          _totalTickets = results[0]['totalTickets'] ?? 0;
        } else {
          _error = results[0]['message'];
        }

        // Events data for table
        if (results[1]['success']) {
          final eventsList = results[1]['events'] as List? ?? [];
          _events = eventsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      });
    }
  }

  String money(num n) => n is int ? '${n}.00' : n.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final commission = (_totalRevenue * 0.15);
    final total = _totalRevenue - commission;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
          },
        ),
        title: const Text('Your sold tickets'),
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
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const SizedBox(height: 8),
                      _BalanceCard(
                        ticketFeeTotal: _totalRevenue,
                        commission: commission,
                        total: total,
                        totalBookings: _totalBookings,
                        totalTickets: _totalTickets,
                        money: money,
                      ),
                      const SizedBox(height: 16),
                      _SalesTable(events: _events, money: money),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text('Withdraw'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double ticketFeeTotal, commission, total;
  final int totalBookings, totalTickets;
  final String Function(num) money;
  const _BalanceCard({
    required this.ticketFeeTotal,
    required this.commission,
    required this.total,
    required this.totalBookings,
    required this.totalTickets,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Your Balance',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Revenue', style: TextStyle(color: AppColors.muted)),
          Text('฿${money(ticketFeeTotal)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Bookings',
              style: TextStyle(color: AppColors.muted)),
          Text(totalBookings.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Tickets', style: TextStyle(color: AppColors.muted)),
          Text(totalTickets.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Commission 15%',
              style: TextStyle(color: AppColors.muted)),
          Text('-฿${money(commission)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.red)),
        ]),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Net Total',
              style: TextStyle(fontWeight: FontWeight.w700)),
          Text('฿${money(total)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Colors.green)),
        ]),
      ]),
    );
  }
}

class _SalesTable extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final String Function(num) money;
  const _SalesTable({
    required this.events,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final tableTotal = events.fold<double>(
        0, (sum, e) => sum + ((e['totalRevenue'] ?? 0) as num).toDouble());

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Total ticket sale',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('See All',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
          const SizedBox(height: 10),
          const Text('Events', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          const _TableHeader(),
          const Divider(height: 14),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No sales yet',
                    style: TextStyle(color: AppColors.muted)),
              ),
            )
          else
            ...events.map((e) => _TableRow(event: e, money: money)),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text('฿${money(tableTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          )
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final h =
        const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600);
    return Row(children: [
      Expanded(flex: 6, child: Text('Name', style: h)),
      Expanded(flex: 2, child: Text('Ticket', style: h)),
      Expanded(
          flex: 3, child: Text('Amount', textAlign: TextAlign.right, style: h)),
    ]);
  }
}

class _TableRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final String Function(num) money;
  const _TableRow({required this.event, required this.money});

  @override
  Widget build(BuildContext context) {
    final name = event['title'] ?? 'Untitled';
    final tickets = event['totalTickets'] ?? 0;
    final amount = ((event['totalRevenue'] ?? 0) as num).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(flex: 6, child: Text(name, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(tickets.toString())),
        Expanded(
            flex: 3,
            child: Text('฿${money(amount)}', textAlign: TextAlign.right)),
      ]),
    );
  }
}
