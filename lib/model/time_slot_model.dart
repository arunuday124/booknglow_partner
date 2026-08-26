/// Represents a single bookable time slot in the salon's schedule.
class TimeSlotModel {
  /// Human-readable label, e.g. "10:30 AM"
  final String label;

  /// true when a confirmed/accepted/pending booking directly occupies this slot
  final bool isBooked;

  /// Firestore booking document ID when [isBooked] is true
  final String? bookingId;

  /// true if a service with the required duration can start at this slot
  final bool isAvailableForDuration;

  /// Human-readable reason when [isAvailableForDuration] is false
  final String? conflictReason;

  /// true if this slot itself is free but cannot start here because a subsequent required slot is locked
  final bool isOverlappingLocked;

  /// true if this slot is free but not enough consecutive slots remain before closing
  final bool isClosingExceeded;

  const TimeSlotModel({
    required this.label,
    this.isBooked = false,
    this.bookingId,
    this.isAvailableForDuration = true,
    this.conflictReason,
    this.isOverlappingLocked = false,
    this.isClosingExceeded = false,
  });

  /// Slot can be safely selected as a starting slot for the given duration
  bool get isSelectable => !isBooked && isAvailableForDuration;

  TimeSlotModel copyWith({
    bool? isBooked,
    String? bookingId,
    bool? isAvailableForDuration,
    String? conflictReason,
    bool? isOverlappingLocked,
    bool? isClosingExceeded,
  }) {
    return TimeSlotModel(
      label: label,
      isBooked: isBooked ?? this.isBooked,
      bookingId: bookingId ?? this.bookingId,
      isAvailableForDuration:
          isAvailableForDuration ?? this.isAvailableForDuration,
      conflictReason: conflictReason ?? this.conflictReason,
      isOverlappingLocked: isOverlappingLocked ?? this.isOverlappingLocked,
      isClosingExceeded: isClosingExceeded ?? this.isClosingExceeded,
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
