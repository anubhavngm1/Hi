// lib/screens/activities/activity_detail_screen.dart
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

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Razorpay _razorpay;
  int _persons = 1;
  DateTime? _activityDate;
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

  double get _total => widget.activity.price * _persons;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary, secondary: AppTheme.gold),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _activityDate = date);
  }

  Future<void> _bookNow() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (_activityDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select activity date')));
      return;
    }

    setState(() => _booking = true);
    try {
      final customer = context.read<AuthProvider>().customer!;
      final orderData = await ApiService().createActivityOrder({
        'activity_id': widget.activity.id,
        'customer_id': customer.id,
        'num_persons': _persons,
        'activity_date': _activityDate!.toIso8601String().split('T')[0],
        'amount': _total,
      });
      _pendingBooking = orderData;

      final options = {
        'key': AppConstants.razorpayKey,
        'amount': (_total * 100).toInt(),
        'name': 'EBO Stay',
        'description': widget.activity.title,
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
      await ApiService().verifyActivityPayment({
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
            title: const Text('Activity Booked! 🏄'),
            content: Text('Booking ref: ${_pendingBooking?['booking_ref']}\nHave a great time!'),
            actions: [
              ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Awesome!'),
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
    final a = widget.activity;
    final imageUrl = a.image != null ? 'https://ebostay.com/assets/images/${a.image}' : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
              background: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFFE8E0D5)),
                      errorWidget: (_, __, ___) => Container(color: AppTheme.primary))
                  : Container(color: AppTheme.primary),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (a.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(a.category!, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
                Row(children: [
                  Text('${AppConstants.currency}${a.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 26)),
                  const Text('/person', style: TextStyle(color: AppTheme.grey)),
                  if (a.duration != null) ...[
                    const Spacer(),
                    const Icon(Icons.schedule, size: 14, color: AppTheme.grey),
                    const SizedBox(width: 4),
                    Text(a.duration!, style: const TextStyle(color: AppTheme.grey)),
                  ],
                ]),
                if (a.location != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.grey),
                    const SizedBox(width: 4),
                    Text(a.location!, style: const TextStyle(color: AppTheme.grey)),
                  ]),
                ],
                if (a.description != null) ...[
                  const SizedBox(height: 16),
                  const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(a.description!, style: const TextStyle(height: 1.6, color: Color(0xFF444444))),
                ],

                const SizedBox(height: 20),
                // Booking
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
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
                            _activityDate == null ? 'Select Date' :
                              '${_activityDate!.day}/${_activityDate!.month}/${_activityDate!.year}',
                            style: TextStyle(
                              color: _activityDate == null ? AppTheme.grey : AppTheme.primary,
                              fontWeight: _activityDate != null ? FontWeight.w600 : FontWeight.normal),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Persons'),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _persons > 1 ? () => setState(() => _persons--) : null),
                        Text('$_persons', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gold),
                          onPressed: () => setState(() => _persons++)),
                      ]),
                    ]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${AppConstants.currency}${_total.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ]),
                ),
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
                : const Text('Book Activity & Pay'),
          ),
        ),
      ),
    );
  }
}
