import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SalesPage extends StatelessWidget {
  static const route = '/sales';
  const SalesPage({super.key});

  String money(num n) => n is int ? '${n}.00' : n.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final rows = const [
      _SaleRow('Flower Festival', 100, 25000),
      _SaleRow('Zipline Adventure', 10, 25000),
      _SaleRow('ATV Tour', 10, 25000),
    ];

    final ticketFeeTotal = rows.fold<int>(0, (sum, r) => sum + r.amount);
    final commission = (ticketFeeTotal * 0.15).round();
    final total = ticketFeeTotal - commission;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Go to AppShell (Home tab is the default index = 0)
            Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
          },
        ),
        title: const Text('Your sold tickets'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SizedBox(height: 8),
          _BalanceCard(
            ticketFeeTotal: ticketFeeTotal,
            commission: commission,
            total: total,
            money: money,
          ),
          const SizedBox(height: 16),
          _SalesTable(rows: rows, tableTotal: ticketFeeTotal, money: money),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int ticketFeeTotal, commission, total;
  final String Function(num) money;
  const _BalanceCard({
    required this.ticketFeeTotal,
    required this.commission,
    required this.total,
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
          const Text('Ticket Fee Total',
              style: TextStyle(color: AppColors.muted)),
          Text(money(ticketFeeTotal),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Commision 15%', style: TextStyle(color: AppColors.muted)),
          Text(money(commission),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(money(total),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}

class _SalesTable extends StatelessWidget {
  final List<_SaleRow> rows;
  final int tableTotal;
  final String Function(num) money;
  const _SalesTable({
    required this.rows,
    required this.tableTotal,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text('Today', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          const _TableHeader(),
          const Divider(height: 14),
          ...rows.map((r) => _TableRow(row: r, money: money)),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(money(tableTotal),
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
  final _SaleRow row;
  final String Function(num) money;
  const _TableRow({required this.row, required this.money});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(flex: 6, child: Text(row.name)),
        Expanded(flex: 2, child: Text(row.ticket.toString())),
        Expanded(
            flex: 3,
            child: Text(money(row.amount), textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _SaleRow {
  final String name;
  final int ticket;
  final int amount;
  const _SaleRow(this.name, this.ticket, this.amount);
}
