// lib/screens/packages/package_detail_screen.dart
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

class PackageDetailScreen extends StatefulWidget {
  final Package package;
  const PackageDetailScreen({super.key, required this.package});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  late Razorpay _razorpay;
  int _adults = 1, _children = 0;
  DateTime? _travelDate;
  String? _couponCode;
  double _discount = 0;
  bool _booking = false;
  Map<String, dynamic>? _pendingBooking;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  double get _totalAmount {
    final base = widget.package.effectivePrice * (_adults + _children * 0.5);
    return base - _discount;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary, secondary: AppTheme.gold),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _travelDate = date);
  }

  Future<void> _checkCoupon() async {
    if (_couponCode == null || _couponCode!.isEmpty) return;
    try {
      final result = await ApiService().checkCoupon(_couponCode!, _totalAmount);
      if (result['valid'] == true) {
        setState(() => _discount = double.tryParse(result['discount'].toString()) ?? 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied! ₹${_discount.toStringAsFixed(0)} off'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid coupon'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _bookNow() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (_travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select travel date')));
      return;
    }

    setState(() => _booking = true);
    try {
      final customer = context.read<AuthProvider>().customer!;
      final orderData = await ApiService().createPackageOrder({
        'package_id': widget.package.id,
        'customer_id': customer.id,
        'num_adults': _adults,
        'num_children': _children,
        'travel_date': _travelDate!.toIso8601String().split('T')[0],
        'coupon_code': _couponCode ?? '',
        'amount': _totalAmount,
      });

      _pendingBooking = orderData;

      final options = {
        'key': AppConstants.razorpayKey,
        'amount': (_totalAmount * 100).toInt(),
        'name': 'EBO Stay',
        'description': widget.package.title,
        'order_id': orderData['razorpay_order_id'],
        'prefill': {
          'name': customer.name,
          'email': customer.email,
          'contact': customer.phone ?? '',
        },
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
      await ApiService().verifyPackagePayment({
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
            title: const Text('Booking Confirmed! 🎉'),
            content: Text('Your booking ref: ${_pendingBooking?['booking_ref']}\nConfirmation sent to your email.'),
            actions: [
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Great!'),
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
    final p = widget.package;
    final imageUrl = p.image != null ? 'https://ebostay.com/assets/images/${p.image}' : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
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
                // Price & Duration
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.discountPrice != null)
                      Text('₹${p.price.toStringAsFixed(0)}',
                        style: TextStyle(color: AppTheme.grey, decoration: TextDecoration.lineThrough)),
                    Text('${AppConstants.currency}${p.effectivePrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 24)),
                    const Text('per person', style: TextStyle(color: AppTheme.grey, fontSize: 12)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${p.durationDays}D / ${p.durationNights}N',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 20),

                // Booking Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    // Date
                    GestureDetector(
                      onTap: _selectDate,
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
                            _travelDate == null ? 'Select Travel Date' :
                              '${_travelDate!.day}/${_travelDate!.month}/${_travelDate!.year}',
                            style: TextStyle(color: _travelDate == null ? AppTheme.grey : AppTheme.primary,
                              fontWeight: _travelDate != null ? FontWeight.w600 : FontWeight.normal),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Adults
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Adults'),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _adults > 1 ? () => setState(() => _adults--) : null),
                        Text('$_adults', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                          onPressed: () => setState(() => _adults++)),
                      ]),
                    ]),

                    // Children
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Children (50% price)'),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _children > 0 ? () => setState(() => _children--) : null),
                        Text('$_children', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                          onPressed: () => setState(() => _children++)),
                      ]),
                    ]),

                    // Coupon
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Coupon code (optional)',
                            prefixIcon: Icon(Icons.local_offer_outlined),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          ),
                          onChanged: (v) => _couponCode = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _checkCoupon, child: const Text('Apply')),
                    ]),

                    const Divider(height: 24),
                    // Total
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${AppConstants.currency}${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ]),
                ),

                const SizedBox(height: 16),
                if (p.description != null) ...[
                  const Text('About This Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(p.description!, style: const TextStyle(height: 1.6, color: Color(0xFF444444))),
                  const SizedBox(height: 16),
                ],
                if (p.inclusions != null) ...[
                  const Text('Inclusions ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(p.inclusions!, style: const TextStyle(height: 1.6)),
                  const SizedBox(height: 16),
                ],
                if (p.exclusions != null) ...[
                  const Text('Exclusions ✗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(p.exclusions!, style: const TextStyle(height: 1.6)),
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
                : const Text('Book Now & Pay'),
          ),
        ),
      ),
    );
  }
}
