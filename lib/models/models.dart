// lib/models/models.dart

class Customer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? referralCode;
  final String token;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.referralCode,
    required this.token,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id: j['id'],
    name: j['name'],
    email: j['email'],
    phone: j['phone'],
    referralCode: j['referral_code'],
    token: j['token'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'phone': phone, 'referral_code': referralCode, 'token': token,
  };
}

class Package {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? itinerary;
  final String? inclusions;
  final String? exclusions;
  final double price;
  final double? discountPrice;
  final int durationDays;
  final int durationNights;
  final String? image;
  final String? destination;

  Package({
    required this.id, required this.title, required this.slug,
    this.description, this.itinerary, this.inclusions, this.exclusions,
    required this.price, this.discountPrice,
    required this.durationDays, required this.durationNights,
    this.image, this.destination,
  });

  factory Package.fromJson(Map<String, dynamic> j) => Package(
    id: j['id'],
    title: j['title'],
    slug: j['slug'] ?? '',
    description: j['description'],
    itinerary: j['itinerary'],
    inclusions: j['inclusions'],
    exclusions: j['exclusions'],
    price: double.tryParse(j['price'].toString()) ?? 0,
    discountPrice: j['discount_price'] != null
        ? double.tryParse(j['discount_price'].toString()) : null,
    durationDays: j['duration_days'] ?? 1,
    durationNights: j['duration_nights'] ?? 0,
    image: j['image'],
    destination: j['destination'],
  );

  double get effectivePrice => discountPrice ?? price;
}

class Hotel {
  final int id;
  final String name;
  final String location;
  final String? city;
  final String? address;
  final int starRating;
  final double pricePerNight;
  final String? description;
  final String? amenities;
  final String? image;
  final String? mapLink;
  final List<String> images;

  Hotel({
    required this.id, required this.name, required this.location,
    this.city, this.address, required this.starRating,
    required this.pricePerNight, this.description,
    this.amenities, this.image, this.mapLink, this.images = const [],
  });

  factory Hotel.fromJson(Map<String, dynamic> j) => Hotel(
    id: j['id'],
    name: j['name'],
    location: j['location'],
    city: j['city'],
    address: j['address'],
    starRating: j['star_rating'] ?? 3,
    pricePerNight: double.tryParse(j['price_per_night'].toString()) ?? 0,
    description: j['description'],
    amenities: j['amenities'],
    image: j['image'],
    mapLink: j['map_link'],
    images: j['images'] != null
        ? List<String>.from(j['images']) : [],
  );
}

class HotelRoom {
  final int id;
  final int hotelId;
  final String roomType;
  final String? description;
  final double pricePerNight;
  final int maxOccupancy;
  final int totalRooms;
  final String? amenities;
  final String? image;

  HotelRoom({
    required this.id, required this.hotelId, required this.roomType,
    this.description, required this.pricePerNight,
    required this.maxOccupancy, required this.totalRooms,
    this.amenities, this.image,
  });

  factory HotelRoom.fromJson(Map<String, dynamic> j) => HotelRoom(
    id: j['id'],
    hotelId: j['hotel_id'],
    roomType: j['room_type'],
    description: j['description'],
    pricePerNight: double.tryParse(j['price_per_night'].toString()) ?? 0,
    maxOccupancy: j['max_occupancy'] ?? 2,
    totalRooms: j['total_rooms'] ?? 1,
    amenities: j['amenities'],
    image: j['image'],
  );
}

class Activity {
  final int id;
  final String title;
  final String? description;
  final double price;
  final String? duration;
  final String? location;
  final String? image;
  final String? category;
  final bool isActive;

  Activity({
    required this.id, required this.title, this.description,
    required this.price, this.duration, this.location,
    this.image, this.category, this.isActive = true,
  });

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'],
    title: j['title'],
    description: j['description'],
    price: double.tryParse(j['price'].toString()) ?? 0,
    duration: j['duration'],
    location: j['location'],
    image: j['image'],
    category: j['category'],
    isActive: (j['is_active'] ?? 1) == 1,
  );
}

class Booking {
  final int id;
  final String bookingRef;
  final String packageTitle;
  final String travelDate;
  final int numAdults;
  final int numChildren;
  final double finalAmount;
  final String paymentStatus;
  final String bookingStatus;
  final DateTime createdAt;

  Booking({
    required this.id, required this.bookingRef, required this.packageTitle,
    required this.travelDate, required this.numAdults, required this.numChildren,
    required this.finalAmount, required this.paymentStatus,
    required this.bookingStatus, required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'],
    bookingRef: j['booking_ref'],
    packageTitle: j['package_title'] ?? j['title'] ?? 'Booking',
    travelDate: j['travel_date'],
    numAdults: j['num_adults'] ?? 1,
    numChildren: j['num_children'] ?? 0,
    finalAmount: double.tryParse(j['final_amount'].toString()) ?? 0,
    paymentStatus: j['payment_status'] ?? 'pending',
    bookingStatus: j['booking_status'] ?? 'pending',
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );
}

class HotelBooking {
  final int id;
  final String bookingRef;
  final String hotelName;
  final String checkIn;
  final String checkOut;
  final int rooms;
  final double totalAmount;
  final String paymentStatus;
  final String bookingStatus;

  HotelBooking({
    required this.id, required this.bookingRef, required this.hotelName,
    required this.checkIn, required this.checkOut, required this.rooms,
    required this.totalAmount, required this.paymentStatus, required this.bookingStatus,
  });

  factory HotelBooking.fromJson(Map<String, dynamic> j) => HotelBooking(
    id: j['id'],
    bookingRef: j['booking_ref'],
    hotelName: j['hotel_name'] ?? 'Hotel',
    checkIn: j['check_in'],
    checkOut: j['check_out'],
    rooms: j['num_rooms'] ?? 1,
    totalAmount: double.tryParse(j['total_amount'].toString()) ?? 0,
    paymentStatus: j['payment_status'] ?? 'pending',
    bookingStatus: j['booking_status'] ?? 'pending',
  );
}
