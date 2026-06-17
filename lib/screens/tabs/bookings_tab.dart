// lib/screens/tabs/bookings_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Booking> _tourBookings = [];
  List<HotelBooking> _hotelBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService().getMyBookings(),
        ApiService().getMyHotelBookings(),
      ]);
      setState(() {
        _tourBookings  = results[0] as List<Booking>;
        _hotelBookings = results[1] as List<HotelBooking>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.luggage_outlined, size: 80, color: AppTheme.grey.withOpacity(0.3)),
              const SizedBox(height: 16),
              const Text('Sign in to view your bookings', style: TextStyle(color: AppTheme.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.gold,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Tour Packages'), Tab(text: 'Hotels')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : _tourBookings.isEmpty
                  ? _emptyState('No tour bookings yet', Icons.map_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tourBookings.length,
                        itemBuilder: (_, i) => _tourCard(_tourBookings[i]),
                      ),
                    ),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : _hotelBookings.isEmpty
                  ? _emptyState('No hotel bookings yet', Icons.hotel_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _hotelBookings.length,
                        itemBuilder: (_, i) => _hotelCard(_hotelBookings[i]),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _tourCard(Booking b) {
    final statusColor = _statusColor(b.bookingStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(b.bookingRef, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          _statusBadge(b.bookingStatus, statusColor),
        ]),
        const SizedBox(height: 8),
        Text(b.packageTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.calendar_today, size: 13, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(b.travelDate, style: const TextStyle(color: AppTheme.grey, fontSize: 13)),
          const SizedBox(width: 12),
          Icon(Icons.people, size: 13, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text('${b.numAdults + b.numChildren} persons', style: const TextStyle(color: AppTheme.grey, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${AppConstants.currency}${b.finalAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 17)),
          _paymentBadge(b.paymentStatus),
        ]),
      ]),
    );
  }

  Widget _hotelCard(HotelBooking h) {
    final statusColor = _statusColor(h.bookingStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(h.bookingRef, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
          _statusBadge(h.bookingStatus, statusColor),
        ]),
        const SizedBox(height: 8),
        Text(h.hotelName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.login, size: 13, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(h.checkIn, style: const TextStyle(color: AppTheme.grey, fontSize: 13)),
          const Text(' → ', style: TextStyle(color: AppTheme.grey)),
          Icon(Icons.logout, size: 13, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(h.checkOut, style: const TextStyle(color: AppTheme.grey, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${AppConstants.currency}${h.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 17)),
          _paymentBadge(h.paymentStatus),
        ]),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default:          return Colors.orange;
    }
  }

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _paymentBadge(String status) {
    final color = status == 'paid' ? Colors.green : status == 'pending' ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState(String msg, IconData icon) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 80, color: AppTheme.grey.withOpacity(0.3)),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppTheme.grey)),
    ]),
  );
}
