// lib/screens/hotels/hotel_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  final Hotel hotel;
  const HotelDetailScreen({super.key, required this.hotel});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  List<HotelRoom> _rooms = [];
  bool _loadingRooms = true;
  HotelRoom? _selectedRoom;
  DateTime? _checkIn, _checkOut;
  int _numRooms = 1;
  bool _booking = false;
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingBooking;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _loadRooms();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await ApiService().getHotelRooms(widget.hotel.id);
      setState(() { _rooms = rooms; _loadingRooms = false; });
    } catch (_) {
      setState(() => _loadingRooms = false);
    }
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  double get _totalAmount {
    if (_selectedRoom == null || _nights == 0) return 0;
    return _selectedRoom!.pricePerNight * _nights * _numRooms;
  }

  Future<void> _selectDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary, secondary: AppTheme.gold),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() { _checkIn = range.start; _checkOut = range.end; });
    }
  }

  Future<void> _bookNow() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (_selectedRoom == null || _checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select room and dates')));
      return;
    }

    setState(() => _booking = true);
    try {
      final customer = context.read<AuthProvider>().customer!;
      final orderData = await ApiService().createHotelOrder({
        'hotel_id': widget.hotel.id,
        'room_id': _selectedRoom!.id,
        'customer_id': customer.id,
        'check_in': _checkIn!.toIso8601String().split('T')[0],
        'check_out': _checkOut!.toIso8601String().split('T')[0],
        'num_rooms': _numRooms,
        'amount': _totalAmount,
      });

      _pendingBooking = orderData;

      final options = {
        'key': AppConstants.razorpayKey,
        'amount': (_totalAmount * 100).toInt(),
        'name': 'EBO Stay',
        'description': '${widget.hotel.name} - ${_selectedRoom!.roomType}',
        'order_id': orderData['razorpay_order_id'],
        'prefill': {'name': customer.name, 'email': customer.email, 'contact': customer.phone ?? ''},
        'theme': {'color': '#D4AF6A'},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse res) async {
    try {
      await ApiService().verifyHotelPayment({
        'razorpay_order_id': res.orderId,
        'razorpay_payment_id': res.paymentId,
        'razorpay_signature': res.signature,
        'booking_id': _pendingBooking?['booking_id'],
      });
      setState(() => _booking = false);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Booking Confirmed! 🏨'),
            content: Text('Booking ref: ${_pendingBooking?['booking_ref']}\nConfirmation sent to your email.'),
            actions: [
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _booking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onPaymentError(PaymentFailureResponse res) {
    setState(() => _booking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${res.message}'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hotel;
    final imageUrl = h.image != null ? 'https://ebostay.com/assets/images/${h.image}' : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              background: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFE8E0D5)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFFE8E0D5)))
                  : Container(color: AppTheme.primary),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stars & Location
                Row(children: List.generate(5, (i) => Icon(
                  i < h.starRating ? Icons.star : Icons.star_border, size: 18, color: AppTheme.gold))),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(h.address ?? h.location, style: const TextStyle(color: AppTheme.grey))),
                ]),
                if (h.description != null) ...[
                  const SizedBox(height: 16),
                  const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(h.description!, style: const TextStyle(height: 1.6, color: Color(0xFF444444))),
                ],
                if (h.amenities != null) ...[
                  const SizedBox(height: 16),
                  const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: h.amenities!.split(',').map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(a.trim(), style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 20),
                const Text('Select Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // Rooms
                _loadingRooms
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                    : _rooms.isEmpty
                        ? const Text('No rooms available', style: TextStyle(color: AppTheme.grey))
                        : Column(children: _rooms.map((room) {
                            final selected = _selectedRoom?.id == room.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedRoom = room),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFE0E0E0)),
                                  boxShadow: selected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(room.roomType, style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15,
                                      color: selected ? Colors.white : AppTheme.primary)),
                                    const SizedBox(height: 4),
                                    Text('Max ${room.maxOccupancy} persons',
                                      style: TextStyle(fontSize: 12, color: selected ? Colors.white70 : AppTheme.grey)),
                                  ]),
                                  Text('${AppConstants.currency}${room.pricePerNight.toStringAsFixed(0)}/night',
                                    style: TextStyle(
                                      color: selected ? AppTheme.gold : AppTheme.gold,
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                                ]),
                              ),
                            );
                          }).toList()),

                if (_selectedRoom != null) ...[
                  const SizedBox(height: 16),
                  // Date & Rooms selection
                  GestureDetector(
                    onTap: _selectDates,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: AppTheme.gold),
                        const SizedBox(width: 12),
                        Text(
                          _checkIn == null ? 'Select Check-in & Check-out' :
                            '${_checkIn!.day}/${_checkIn!.month} → ${_checkOut!.day}/${_checkOut!.month}  ($_nights nights)',
                          style: TextStyle(
                            color: _checkIn == null ? AppTheme.grey : AppTheme.primary,
                            fontWeight: _checkIn != null ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Number of Rooms'),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _numRooms > 1 ? () => setState(() => _numRooms--) : null),
                      Text('$_numRooms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                        onPressed: () => setState(() => _numRooms++)),
                    ]),
                  ]),
                  if (_totalAmount > 0) ...[
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${AppConstants.currency}${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ],
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _booking ? null : _bookNow,
            child: _booking
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Text('Book Hotel & Pay'),
          ),
        ),
      ),
    );
  }
}
