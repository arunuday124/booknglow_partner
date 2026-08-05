import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String clientName;
  final String? avatarUrl;
  final String initials;
  final String time;
  final String date;
  final List<String>? _services;
  final double totalPrice;
  final String? notes;
  final String
  status; // 'Pending', 'Accepted', 'Rescheduled', 'Completed', 'Cancelled'
  final bool isNew;
  final String salonId;
  final String salonName;
  final String paymentMethod;
  final String userId;
  final dynamic createdAt;

  BookingModel({
    required this.id,
    required this.clientName,
    this.avatarUrl,
    String? initials,
    required this.time,
    required this.date,
    List<String>? services,
    this.totalPrice = 0.0,
    this.notes,
    this.status = 'Pending',
    this.isNew = true,
    this.salonId = '',
    this.salonName = '',
    this.paymentMethod = 'cash',
    this.userId = '',
    this.createdAt,
  }) : initials = initials ?? _generateInitials(clientName),
       _services = services != null
           ? List<String>.from(services)
           : const <String>[];

  /// Factory to construct BookingModel directly from a Firestore DocumentSnapshot
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel.fromMap(data, doc.id);
  }

  /// Factory to construct BookingModel from a `Map<String, dynamic>` and document ID
  factory BookingModel.fromMap(Map<String, dynamic> data, String docId) {
    final String name = (data['userName'] ?? data['clientName'] ?? 'Client')
        .toString();
    final parsedServices = _parseServices(data['services']);

    return BookingModel(
      id: docId,
      clientName: name,
      avatarUrl: data['avatarUrl']?.toString(),
      initials: _generateInitials(name),
      time: data['time']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      services: parsedServices['names'] as List<String>,
      totalPrice: (data['totalPrice'] is num)
          ? (data['totalPrice'] as num).toDouble()
          : ((parsedServices['total'] as double) > 0
                ? (parsedServices['total'] as double)
                : 0.0),
      notes: data['notes']?.toString(),
      status:
          data['bookingStatus']?.toString() ??
          data['status']?.toString() ??
          'Pending',
      isNew:
          (data['bookingStatus']?.toString() ?? data['status']?.toString()) ==
          'Pending',
      salonId: data['salonId']?.toString() ?? '',
      salonName: data['salonName']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? 'cash',
      userId: data['userId']?.toString() ?? '',
      createdAt: data['createdAt'],
    );
  }

  static String _generateInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  static Map<String, dynamic> _parseServices(dynamic rawServices) {
    final List<String> serviceNames = [];
    double total = 0.0;
    if (rawServices is List) {
      for (var item in rawServices) {
        if (item is Map) {
          final sName =
              item['serviceName']?.toString() ??
              item['title']?.toString() ??
              item['name']?.toString() ??
              '';
          if (sName.isNotEmpty) {
            serviceNames.add(sName);
          }
          final priceVal = item['price'];
          if (priceVal is num) {
            total += priceVal.toDouble();
          } else if (priceVal != null) {
            total += (double.tryParse(priceVal.toString()) ?? 0.0);
          }
        } else if (item is String) {
          serviceNames.add(item);
        }
      }
    }
    return {'names': serviceNames, 'total': total};
  }

  /// Getter for services guaranteed to return a non-null List of strings
  List<String> get services =>
      _services != null ? List<String>.from(_services) : const <String>[];

  /// Convenient getter to join multiple services into a readable string
  String get serviceName => services.isEmpty ? '' : services.join(' & ');

  BookingModel copyWith({
    String? id,
    String? clientName,
    String? avatarUrl,
    String? initials,
    String? time,
    String? date,
    List<String>? services,
    double? totalPrice,
    String? notes,
    String? status,
    bool? isNew,
    String? salonId,
    String? salonName,
    String? paymentMethod,
    String? userId,
    dynamic createdAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      time: time ?? this.time,
      date: date ?? this.date,
      services: services ?? this.services,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isNew: isNew ?? this.isNew,
      salonId: salonId ?? this.salonId,
      salonName: salonName ?? this.salonName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
