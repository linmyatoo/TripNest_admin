import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/air_quality_service.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _organizer;
  bool _isLoading = true;
  String? _error;
  AirQualityData? _airQuality;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchAirQuality();
  }

  /// Public method to refresh events (called from AppShell)
  void refresh() {
    _fetchEvents();
    _fetchAirQuality();
  }

  Future<void> _fetchAirQuality() async {
    final aqData = await AirQualityService.getAirQuality();
    if (mounted && aqData != null) {
      setState(() => _airQuality = aqData);
    }
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getDashboardEvents();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _organizer = result['organizer'];
          final eventsList = result['events'] as List? ?? [];
          _events = eventsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          _error = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              organizerName: _organizer?['organizationName'],
              organizerAddress: _organizer?['address'],
              airQuality: _airQuality,
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your events',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                // _BlueLink('See All'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(
        child:
            Text('No events found', style: TextStyle(color: AppColors.muted)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEvents,
      child: ListView.separated(
        itemCount: _events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _EventCard(event: _events[i]),
      ),
    );
  }
}

// class _BlueLink extends StatelessWidget {
//   final String text;
//   const _BlueLink(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Text(text,
//         style: const TextStyle(
//             color: AppColors.primary, fontWeight: FontWeight.w600));
//   }
// }

class _Header extends StatelessWidget {
  final String? organizerName;
  final String? organizerAddress;
  final AirQualityData? airQuality;
  const _Header({this.organizerName, this.organizerAddress, this.airQuality});

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/avatar_jacob.jpg')),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(organizerName ?? 'Welcome',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                    (organizerAddress != null && organizerAddress!.isNotEmpty)
                        ? organizerAddress!
                        : airQuality?.cityName ?? 'Chiang Rai, Thailand',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted)),
              ),
            ]),
          ]),
        ),
        // Air Quality Badge
        if (airQuality != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _getAqiColor(airQuality!.aqi).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _getAqiColor(airQuality!.aqi).withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AQI',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getAqiColor(airQuality!.aqi),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  airQuality!.aqi.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _getAqiColor(airQuality!.aqi),
                  ),
                ),
              ],
            ),
          ),
        IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/notifications-feed'),
            icon: const Icon(Icons.notifications_outlined)),
      ],
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  List<String> get _images {
    final event = widget.event;
    if (event['images'] != null && (event['images'] as List).isNotEmpty) {
      // API returns array of objects with 'imageUrl' property
      return (event['images'] as List)
          .map((e) {
            if (e is Map) {
              return e['imageUrl']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (event['image'] != null) {
      return [event['image'].toString()];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    if (_images.length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % _images.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final title = event['title'] ?? 'Untitled Event';
    final totalRevenue = (event['totalRevenue'] ?? 0).toDouble();
    final totalBookings = event['totalBookings'] ?? 0;
    final totalTickets = event['totalTickets'] ?? 0;

    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/reviews',
          arguments: {'eventId': event['eventId']?.toString()},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image Carousel
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 140,
                child: Stack(
                  children: [
                    // Images
                    _images.isNotEmpty
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: _images.length,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                _images[index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      size: 48, color: Colors.grey),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.event,
                                  size: 48, color: Colors.grey),
                            ),
                          ),
                    // Edit Button with blur background
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/create-event',
                                  arguments: {
                                    'eventId': event['eventId']?.toString()
                                  },
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Page Indicator
                    if (_images.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _images.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.attach_money,
                          label: 'Revenue',
                          value: '฿${totalRevenue.toStringAsFixed(2)}',
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.bookmark_outline,
                          label: 'Bookings',
                          value: totalBookings.toString(),
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Tickets',
                          value: totalTickets.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}
