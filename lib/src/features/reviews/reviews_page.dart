import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ReviewsPage extends StatelessWidget {
  static const route = '/reviews';
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context)), title: const Text('Reviews')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _EventStrip(),
          const SizedBox(height: 16),
          _SummaryCard(),
          const SizedBox(height: 16),
          _LatestReviews(),
          const SizedBox(height: 16),
          _RatingBreakdown(),
        ],
      ),
    );
  }
}

class _EventStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/images/event_flower.jpg', width: 72, height: 56, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flower Festival', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Chiang Rai', style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summarized reviews', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          Text('Reviews analyzed: 214 (negatives: 42 → 19.6%)', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 10),
          _Issue('Refund process unclear', "Didn't see refund info."),
          _Issue('Music too loud near stage (19:00–21:00)', '"Had to raise my voice.", "Speaker above us."'),
        ],
      ),
    );
  }
}

class _Issue extends StatelessWidget {
  final String title, evidence;
  const _Issue(this.title, this.evidence);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary),
          children: [
            const TextSpan(text: 'Issue: ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            TextSpan(text: '$title\n'),
            const TextSpan(text: 'Evidence: ', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
            TextSpan(text: evidence),
          ],
        ),
      ),
    );
  }
}

class _LatestReviews extends StatelessWidget {
  const _LatestReviews();

  @override
  Widget build(BuildContext context) {
    final reviews = const [
      _Review('Jacob Jones', 4.8, "Amazing!  Very happy with this experience. I'll come again if I have a chance.", 'assets/images/avatar_jacob.jpg'),
      _Review('Esther Howard', 4.4, "The service is on point, and I really like the facilities. Good job!", 'assets/images/avatar_esther.jpg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('Latest reviews', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ...reviews.map((r) => _ReviewTile(r: r)).toList(),
      ],
    );
  }
}

class _Review {
  final String name, avatar, text;
  final double rating;
  const _Review(this.name, this.rating, this.text, this.avatar);
}

class _ReviewTile extends StatelessWidget {
  final _Review r;
  const _ReviewTile({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundImage: AssetImage(r.avatar), radius: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(r.text),
            ]),
          ),
        ],
      ),
    );
  }
}

class _RatingBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counts = [2, 4, 10, 60, 44]; // bars for 1..5
    final total = counts.reduce((a, b) => a + b);
    final avg = 4.9;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
            Row(children: List.generate(5, (i) => const Icon(Icons.star, size: 20, color: Colors.amber))),
            const SizedBox(height: 4),
            Text('Based on $total reviews', style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: Column(children: List.generate(5, (i) {
            final idx = i;
            final label = (idx + 1).toString();
            final value = counts[idx] / total;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 10, child: Text(label)),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: value,
                      backgroundColor: const Color(0xFFEAECEF),
                    ),
                  ),
                ),
              ]),
            );
          }).reversed.toList()),
        ),
      ],
    );
  }
}
