// lib/screens/tabs/hotels_tab.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../hotels/hotel_detail_screen.dart';

class HotelsTab extends StatefulWidget {
  const HotelsTab({super.key});

  @override
  State<HotelsTab> createState() => _HotelsTabState();
}

class _HotelsTabState extends State<HotelsTab> {
  List<Hotel> _hotels = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? city}) async {
    setState(() => _loading = true);
    try {
      final hotels = await ApiService().getHotels(city: city);
      setState(() { _hotels = hotels; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotels'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by city...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (v) => _load(city: v.trim().isEmpty ? null : v.trim()),
            ),
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => _shimmerCard(),
            )
          : _hotels.isEmpty
              ? const Center(child: Text('No hotels found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hotels.length,
                  itemBuilder: (_, i) => _hotelCard(_hotels[i]),
                ),
    );
  }

  Widget _hotelCard(Hotel h) {
    final imageUrl = h.image != null ? 'https://ebostay.com/assets/images/${h.image}' : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: h)),
      ),
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
                  ? CachedNetworkImage(
                      imageUrl: imageUrl, width: 110, height: 120, fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.grey),
                      const SizedBox(width: 2),
                      Expanded(child: Text(h.city ?? h.location, style: const TextStyle(color: AppTheme.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: List.generate(5, (i) => Icon(
                      i < h.starRating ? Icons.star : Icons.star_border,
                      size: 14, color: AppTheme.gold,
                    ))),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.currency}${h.pricePerNight.toStringAsFixed(0)}/night',
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

  Widget _placeholder() => Container(width: 110, height: 120, color: const Color(0xFFE8E0D5),
    child: const Icon(Icons.hotel, color: Color(0xFFBBBBBB), size: 32));

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(height: 120, margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
  );
}
