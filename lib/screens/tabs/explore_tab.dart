// lib/screens/tabs/explore_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../packages/package_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  List<Package> _packages = [];
  List<Map<String, dynamic>> _destinations = [];
  bool _loading = true;
  String? _selectedDest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService().getPackages(destination: _selectedDest),
        ApiService().getDestinations(),
      ]);
      setState(() {
        _packages     = results[0] as List<Package>;
        _destinations = results[1] as List<Map<String, dynamic>>;
        _loading      = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0B1320), Color(0xFF1A2840)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.travel_explore, color: AppTheme.gold, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'EBO Stay',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.gold, fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Where do you\nwant to go? ✈️',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            title: const Text('Explore Packages'),
          ),

          // Destinations Filter
          if (_destinations.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _destinations.length + 1,
                  itemBuilder: (ctx, i) {
                    final isAll = i == 0;
                    final dest = isAll ? null : _destinations[i - 1];
                    final label = isAll ? 'All' : dest!['name'];
                    final selected = isAll ? _selectedDest == null : _selectedDest == label;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDest = isAll ? null : label;
                          _loading = true;
                        });
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppTheme.primary : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.grey,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Packages Grid
          _loading
              ? SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 1,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 16,
                    children: List.generate(4, (_) => _shimmerCard()),
                  ),
                )
              : _packages.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.travel_explore, size: 64, color: AppTheme.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No packages found', style: TextStyle(color: AppTheme.grey)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _packageCard(_packages[i]),
                          childCount: _packages.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _packageCard(Package p) {
    final imageUrl = p.image != null
        ? 'https://ebostay.com/assets/images/${p.image}'
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PackageDetailScreen(package: p)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.08),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 200, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (_, __) => _imgPlaceholder(),
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppTheme.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${p.durationDays}D / ${p.durationNights}N',
                        style: TextStyle(color: AppTheme.grey, fontSize: 13),
                      ),
                      if (p.destination != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(
                          p.destination!,
                          style: TextStyle(color: AppTheme.grey, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.discountPrice != null)
                            Text(
                              '${AppConstants.currency}${p.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${AppConstants.currency}${p.effectivePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text('per person', style: TextStyle(color: AppTheme.grey, fontSize: 11)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PackageDetailScreen(package: p)),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Book Now'),
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

  Widget _imgPlaceholder() => Container(
    height: 200, color: const Color(0xFFE8E0D5),
    child: const Center(child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFBBBBBB))),
  );

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: 280,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    ),
  );
}
