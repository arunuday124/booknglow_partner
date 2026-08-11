/// Represents a single bookable time slot in the salon's schedule.
class TimeSlotModel {
  /// Human-readable label, e.g. "10:30 AM"
  final String label;

  /// true when a confirmed/accepted/pending booking already occupies this slot
  final bool isBooked;

  /// Firestore booking document ID when [isBooked] is true
  final String? bookingId;

  const TimeSlotModel({
    required this.label,
    this.isBooked = false,
    this.bookingId,
  });

  TimeSlotModel copyWith({bool? isBooked, String? bookingId}) {
    return TimeSlotModel(
      label: label,
      isBooked: isBooked ?? this.isBooked,
      bookingId: bookingId ?? this.bookingId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotModel &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}
