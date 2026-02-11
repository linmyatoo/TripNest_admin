import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = const [
      _Event('Flower Festival', 'Chiang Rai', 'assets/images/event_flower.jpg', 250),
      _Event('Zipline Adventure', 'Chiang Rai', 'assets/images/event_zipline.jpg', 200),
      _Event('ATV Tour', 'Chiang Rai', 'assets/images/event_atv.jpg', 500),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Your events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                _BlueLink('See All'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _EventCard(e: events[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueLink extends StatelessWidget {
  final String text;
  const _BlueLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600));
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 22, backgroundImage: AssetImage('assets/images/avatar_jacob.jpg')),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Harry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
              SizedBox(width: 4),
              Text('Chiang Rai , Thailand', style: TextStyle(color: AppColors.muted)),
            ]),
          ]),
        ),
        IconButton(onPressed: () => Navigator.pushNamed(context, '/notifications-feed'),
          icon: const Icon(Icons.notifications_outlined)),
      ],
    );
  }
}

class _Event {
  final String title, city, image;
  final int priceB;
  const _Event(this.title, this.city, this.image, this.priceB);
}

class _EventCard extends StatelessWidget {
  final _Event e;
  const _EventCard({required this.e});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE6E8EC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, '/reviews'),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.asset(e.image, width: 110, height: 76, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(e.city, style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${e.priceB}B/Person', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
