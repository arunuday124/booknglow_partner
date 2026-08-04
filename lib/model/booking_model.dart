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
  final String status; // 'Pending', 'Accepted', 'Rescheduled', 'Completed'
  final bool isNew;

  BookingModel({
    required this.id,
    required this.clientName,
    this.avatarUrl,
    required this.initials,
    required this.time,
    required this.date,
    List<String>? services,
    this.totalPrice = 0.0,
    this.notes,
    this.status = 'Pending',
    this.isNew = true,
  }) : _services = services != null ? List<String>.from(services) : const <String>[];

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
    );
  }
}
