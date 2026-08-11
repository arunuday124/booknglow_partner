import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userName;
  final String paymentMethod;
  final String paymentStatus;
  final double amount;
  final String date;
  final String serviceName;

  TransactionModel({
    required this.id,
    required this.userName,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.amount,
    required this.date,
    this.serviceName = '',
  });

  /// Factory to construct TransactionModel from Firestore DocumentSnapshot or Map
  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    final String name =
        (map['userName'] ??
                map['clientName'] ??
                map['customerName'] ??
                'Guest User')
            .toString();
    final String method = (map['paymentMethod'] ?? map['method'] ?? 'UPI')
        .toString();
    final String rawStatus = (map['paymentStatus'] ??
            map['PaymentStatus'] ??
            map['bookingStatus'] ??
            map['status'] ??
            'pending')
        .toString();

    String status = 'Pending';
    final String lower = rawStatus.toLowerCase();
    if (lower == 'completed' || lower == 'paid') {
      status = 'Completed';
    } else if (lower == 'pending') {
      status = 'Pending';
    } else if (lower == 'cancelled' || lower == 'canceled' || lower == 'failed') {
      status = 'Cancelled';
    } else {
      status = rawStatus;
    }

    double amt = _parsePrice(
      map['amount'] ??
          map['totalPrice'] ??
          map['price'] ??
          map['cost'] ??
          map['total'] ??
          map['servicePrice'] ??
          map['priceTotal'],
    );

    if (amt <= 0.0 && map['services'] is List) {
      for (var item in (map['services'] as List)) {
        if (item is Map) {
          amt += _parsePrice(
            item['price'] ??
                item['totalPrice'] ??
                item['amount'] ??
                item['cost'] ??
                item['priceTotal'],
          );
        }
      }
    }

    String dateStr =
        map['date']?.toString() ?? map['time']?.toString() ?? 'Today';
    if (map['createdAt'] is Timestamp) {
      final DateTime dt = (map['createdAt'] as Timestamp).toDate();
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }

    return TransactionModel(
      id: docId,
      userName: name,
      paymentMethod: method,
      paymentStatus: status,
      amount: amt,
      date: dateStr,
      serviceName: map['serviceName']?.toString() ?? '',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userName,
    String? paymentMethod,
    String? paymentStatus,
    double? amount,
    String? date,
    String? serviceName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      serviceName: serviceName ?? this.serviceName,
    );
  }

  static double _parsePrice(dynamic val) {
    if (val is num) return val.toDouble();
    if (val != null) {
      final str = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(str) ?? 0.0;
    }
    return 0.0;
  }
}
