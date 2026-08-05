import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class ReviewsPage extends StatefulWidget {
  static const route = '/reviews';
  final String? eventId;
  const ReviewsPage({super.key, this.eventId});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _apiService = ApiService();
  Map<String, dynamic>? _event;
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _sentiment;
  List<dynamic> _sentimentReviews = [];
  bool _isLoading = true;
  bool _showAllReviews = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (widget.eventId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final results = await Future.wait([
      _apiService.getEventById(widget.eventId!),
      _apiService.getEventReviews(widget.eventId!),
      _apiService.getEventSentimentSummary(widget.eventId!),
      _apiService.getEventSentimentReviews(widget.eventId!),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (results[0]['success']) _event = results[0]['event'];
        if (results[1]['success']) _reviews = results[1]['reviews'] ?? [];
        if (results[2]['success']) _sentiment = results[2]['data'];
        if (results[3]['success']) {
          _sentimentReviews = results[3]['sentiments'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.pop(context)),
          title: const Text('Reviews')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _EventStrip(event: _event),
                const SizedBox(height: 16),
                _SummaryCard(
                  sentiment: _sentiment,
                  sentimentReviews: _sentimentReviews,
                ),
                const SizedBox(height: 16),
                _LatestReviewsSection(
                  reviews: _reviews,
                  showAll: _showAllReviews,
                  onSeeAllTap: () =>
                      setState(() => _showAllReviews = !_showAllReviews),
                ),
                const SizedBox(height: 16),
                _RatingBreakdown(reviews: _reviews),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event strip
// ─────────────────────────────────────────────────────────────────────────────

class _EventStrip extends StatefulWidget {
  final Map<String, dynamic>? event;
  const _EventStrip({this.event});

  @override
  State<_EventStrip> createState() => _EventStripState();
}

class _EventStripState extends State<_EventStrip> {
  bool _isExpanded = false;

  String? get _imageUrl {
    final images = widget.event?['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) return first['imageUrl']?.toString();
      return first.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.event?['title'] ?? 'Event';
    final location = widget.event?['location'] ?? 'Location';
    final description = widget.event?['description'] ?? '';
    final hasLongDescription = description.length > 80;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _imageUrl != null
                  ? Image.network(
                      _imageUrl!,
                      width: 72,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Image.asset('assets/images/event_flower.jpg',
                      width: 72, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location,
                            style: const TextStyle(color: AppColors.muted),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedCrossFade(
              firstChild: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              secondChild: Text(
                description,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            if (hasLongDescription)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'See less' : 'See more',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic>? sentiment;
  final List<dynamic> sentimentReviews;

  const _SummaryCard({
    this.sentiment,
    required this.sentimentReviews,
  });

  @override
  Widget build(BuildContext context) {
    // Keep only NEGATIVE entries that carry a meaningful negativeSummary.
    final negativeItems = sentimentReviews
        .where((s) =>
            s['label'] == 'NEGATIVE' &&
            (s['negativeSummary'] as String?)?.isNotEmpty == true)
        .toList();

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
          const Text('Summarized reviews',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          // ── Sentiment stats ───────────────────────────────────────────────
          if (sentiment == null)
            const Text(
              'Sentiment data unavailable.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else ...[
            _SentimentStats(sentiment: sentiment!),
            const SizedBox(height: 10),
          ],

          // ── Dynamic issues from sentiment reviews API ─────────────────────
          if (negativeItems.isEmpty)
            const Text(
              'No issues reported.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else
            ...negativeItems.map(
              (s) => _Issue(s['negativeSummary'] as String),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sentiment stats chips
// ─────────────────────────────────────────────────────────────────────────────

class _SentimentStats extends StatelessWidget {
  final Map<String, dynamic> sentiment;
  const _SentimentStats({required this.sentiment});

  @override
  Widget build(BuildContext context) {
    final total = sentiment['totalReviews'] as int? ?? 0;
    final analyzed = sentiment['analyzedCount'] as int? ?? 0;
    final positive = sentiment['positiveCount'] as int? ?? 0;
    final negative = sentiment['negativeCount'] as int? ?? 0;
    final neutral = sentiment['neutralCount'] as int? ?? 0;
    final score = (sentiment['averageScore'] as num?)?.toDouble() ?? 0.0;

    final negPct =
        analyzed > 0 ? ((negative / analyzed) * 100).toStringAsFixed(1) : '0';
    final posPct =
        analyzed > 0 ? ((positive / analyzed) * 100).toStringAsFixed(1) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews analyzed: $analyzed / $total  '
          '(negatives: $negative → $negPct%)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _SentimentChip(
                label: '👍 $positive positive ($posPct%)', color: Colors.green),
            _SentimentChip(
                label: '👎 $negative negative ($negPct%)', color: Colors.red),
            if (neutral > 0)
              _SentimentChip(label: '😐 $neutral neutral', color: Colors.grey),
            _SentimentChip(
                label: 'Score: ${score.toStringAsFixed(2)}',
                color: AppColors.primary),
          ],
        ),
      ],
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SentimentChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Issue — issue label only, evidence removed
// ─────────────────────────────────────────────────────────────────────────────

class _Issue extends StatelessWidget {
  final String title;
  const _Issue(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.textPrimary),
          children: [
            const TextSpan(
              text: 'Issue: ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: title),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Latest reviews section (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _LatestReviewsSection extends StatelessWidget {
  final List<dynamic> reviews;
  final bool showAll;
  final VoidCallback onSeeAllTap;

  const _LatestReviewsSection({
    required this.reviews,
    required this.showAll,
    required this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayReviews = showAll ? reviews : reviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Latest reviews',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (reviews.length > 2)
            GestureDetector(
              onTap: onSeeAllTap,
              child: Text(
                showAll ? 'Show less' : 'See All',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('No reviews yet',
                  style: TextStyle(color: AppColors.muted)),
            ),
          )
        else
          ...displayReviews.map((r) => _ReviewTile(review: r)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';
    final createdAt = _formatDate(review['createdAt'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(rating.toStringAsFixed(1),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (createdAt.isNotEmpty)
                      Text(createdAt,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating breakdown (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBreakdown extends StatelessWidget {
  final List<dynamic> reviews;
  const _RatingBreakdown({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final counts = [0, 0, 0, 0, 0];
    for (final r in reviews) {
      final rating = (r['rating'] ?? 0) as int;
      if (rating >= 1 && rating <= 5) counts[rating - 1]++;
    }
    final total = reviews.length;
    final avg = total > 0
        ? reviews.fold<double>(
                0, (sum, r) => sum + ((r['rating'] ?? 0) as num).toDouble()) /
            total
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(avg.toStringAsFixed(1),
                style:
                    const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
            Row(
                children: List.generate(5, (i) {
              if (i < avg.floor()) {
                return const Icon(Icons.star, size: 20, color: Colors.amber);
              } else if (i < avg && avg - i >= 0.5) {
                return const Icon(Icons.star_half,
                    size: 20, color: Colors.amber);
              } else {
                return const Icon(Icons.star_border,
                    size: 20, color: Colors.amber);
              }
            })),
            const SizedBox(height: 4),
            Text('Based on $total reviews',
                style: const TextStyle(color: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: Column(
              children: List.generate(5, (i) {
            final label = (i + 1).toString();
            final value = total > 0 ? counts[i] / total : 0.0;
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
