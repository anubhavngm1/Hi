// lib/screens/tabs/activities_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../activities/activity_detail_screen.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  List<Activity> _activities = [];
  bool _loading = true;
  String? _selectedCategory;

  final _categories = ['Water Sports', 'Adventure', 'Nature', 'Cultural', 'Food Tours'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final activities = await ApiService().getActivities(category: _selectedCategory);
      setState(() { _activities = activities; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length + 1,
              itemBuilder: (_, i) {
                final isAll = i == 0;
                final cat = isAll ? null : _categories[i - 1];
                final label = isAll ? 'All' : cat!;
                final selected = isAll ? _selectedCategory == null : _selectedCategory == cat;
                return GestureDetector(
                  onTap: () { setState(() => _selectedCategory = cat); _load(); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFE0E0E0)),
                    ),
                    child: Text(label, style: TextStyle(
                      color: selected ? Colors.white : AppTheme.grey,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    )),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(height: 100, margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                    ),
                  )
                : _activities.isEmpty
                    ? const Center(child: Text('No activities found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activities.length,
                        itemBuilder: (_, i) => _activityCard(_activities[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(Activity a) {
    final imageUrl = a.image != null ? 'https://ebostay.com/assets/images/${a.image}' : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(activity: a))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, width: 110, height: 110, fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(), errorWidget: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(a.category!, style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 4),
                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (a.duration != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.schedule, size: 12, color: AppTheme.grey),
                        const SizedBox(width: 4),
                        Text(a.duration!, style: const TextStyle(color: AppTheme.grey, fontSize: 12)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.currency}${a.price.toStringAsFixed(0)}/person',
                      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(width: 110, height: 110, color: const Color(0xFFE8E0D5),
    child: const Icon(Icons.surfing, color: Color(0xFFBBBBBB), size: 32));
}
