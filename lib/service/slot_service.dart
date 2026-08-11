import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/booking_model.dart';
import '../model/time_slot_model.dart';

/// Custom exception thrown when the target slot is already locked by another booking.
class SlotAlreadyBookedException implements Exception {
  final String slotLabel;
  const SlotAlreadyBookedException(this.slotLabel);

  @override
  String toString() =>
      'SlotAlreadyBookedException: $slotLabel is already booked/locked.';
}

/// Stateless service that handles all slot-availability logic.
///
/// Slots are locked directly via the `isLocked: true` field inside the `bookings` collection.
class SlotService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── 1. Slot Generation ────────────────────────────────────────────────────

  /// Generates all slot labels between [opening] and [closing] at
  /// [intervalMinutes] intervals (default 30 min).
  ///
  /// Example: opening=10:00 AM, closing=8:00 PM →
  ///   ["10:00 AM", "10:30 AM", ..., "08:00 PM"]
  static List<String> generateSlots(
    TimeOfDay opening,
    TimeOfDay closing, {
    int intervalMinutes = 30,
  }) {
    final List<String> slots = [];

    int currentMinutes = opening.hour * 60 + opening.minute;
    final int closingMinutes = closing.hour * 60 + closing.minute;

    while (currentMinutes <= closingMinutes) {
      slots.add(_minutesToLabel(currentMinutes));
      currentMinutes += intervalMinutes;
    }

    return slots;
  }

  /// Converts total minutes from midnight into a "H:MM AM/PM" label.
  static String _minutesToLabel(int totalMinutes) {
    final int hour24 = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    final String period = hour24 < 12 ? 'AM' : 'PM';
    final int hour12 = hour24 == 0
        ? 12
        : hour24 > 12
            ? hour24 - 12
            : hour24;
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  // ── 2. Booked-Slot Query ──────────────────────────────────────────────────

  /// One-shot fetch: returns the set of locked slot labels for
  /// [salonId] + [date].
  static Future<Set<String>> fetchBookedSlots(
    String salonId,
    String date, {
    String? excludeBookingId,
  }) async {
    final snapshot = await _db
        .collection('bookings')
        .where('salonId', isEqualTo: salonId)
        .get();

    return _extractBookedTimes(
      snapshot.docs,
      date,
      excludeBookingId: excludeBookingId,
    );
  }

  /// Real-time stream: emits an updated set of locked slot labels whenever
  /// a booking document changes for [salonId] + [date].
  static Stream<Set<String>> watchBookedSlots(
    String salonId,
    String date, {
    String? excludeBookingId,
  }) {
    return _db
        .collection('bookings')
        .where('salonId', isEqualTo: salonId)
        .snapshots()
        .map((snapshot) => _extractBookedTimes(
              snapshot.docs,
              date,
              excludeBookingId: excludeBookingId,
            ));
  }

  /// Filters docs to matching date where `isLocked == true`.
  static Set<String> _extractBookedTimes(
    List<QueryDocumentSnapshot> docs,
    String targetDate, {
    String? excludeBookingId,
  }) {
    final Set<String> booked = {};
    for (final doc in docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final data = doc.data() as Map<String, dynamic>;

      // A slot is locked if isLocked == true in the booking doc
      final bool isLocked = data['isLocked'] == true ||
          (data['isLocked']?.toString().toLowerCase() == 'true');
      if (!isLocked) continue;

      final String docDate =
          (data['date'] ?? data['bookingDate'] ?? data['appointmentDate'] ?? '')
              .toString()
              .trim();
      if (_isSameDate(docDate, targetDate)) {
        final String time = (data['time'] ?? '').toString().trim();
        if (time.isNotEmpty) {
          booked.add(time);
        }
      }
    }
    return booked;
  }

  /// Extracts locked time slot strings from an in-memory list of [BookingModel]s.
  /// Runs in 0ms with zero network or Firestore queries.
  static Set<String> extractBookedTimesFromModels(
    List<BookingModel> bookings,
    String targetDate, {
    String? excludeBookingId,
  }) {
    final Set<String> booked = {};
    for (final b in bookings) {
      if (excludeBookingId != null && b.id == excludeBookingId) continue;
      // Slot is locked only if isLocked == true
      if (!b.isLocked) continue;

      if (_isSameDate(b.date, targetDate)) {
        final String time = b.time.trim();
        if (time.isNotEmpty) {
          booked.add(time);
        }
      }
    }
    return booked;
  }

  // ── 3. Merged Slot List & Helpers ─────────────────────────────────────────

  /// Returns a merged list of [TimeSlotModel]s from generated slots + booked times.
  static List<TimeSlotModel> mergeSlots(
    List<String> generatedSlots,
    Set<String> bookedTimes,
  ) {
    return generatedSlots.map((label) {
      final bool booked = bookedTimes.any(
        (t) => _normaliseTimeLabel(t) == _normaliseTimeLabel(label),
      );
      return TimeSlotModel(label: label, isBooked: booked);
    }).toList();
  }

  /// Finds the **next available** slot strictly after [selectedLabel].
  static TimeSlotModel? findNextAvailable(
    List<TimeSlotModel> slots,
    String selectedLabel,
  ) {
    final String normSelected = _normaliseTimeLabel(selectedLabel);

    // Find the position of the conflicted slot
    int startIndex = slots.indexWhere(
      (s) => _normaliseTimeLabel(s.label) == normSelected,
    );

    // If we can't find the exact label (format mismatch), parse it as minutes
    // and find the nearest slot by time value instead.
    if (startIndex == -1) {
      final int? selectedMins = labelToMinutes(selectedLabel);
      if (selectedMins != null) {
        for (int i = 0; i < slots.length; i++) {
          final int? slotMins = labelToMinutes(slots[i].label);
          if (slotMins != null && slotMins >= selectedMins) {
            startIndex = i;
            break;
          }
        }
      }
    }

    if (startIndex == -1) return null;

    // Walk forward, skip all booked slots
    for (int i = startIndex + 1; i < slots.length; i++) {
      if (!slots[i].isBooked) return slots[i];
    }

    return null;
  }

  /// Filters a list of [TimeSlotModel]s to only keep upcoming slots if [date] is today.
  /// For future dates (tomorrow onwards), all generated slots are preserved.
  static List<TimeSlotModel> filterUpcomingSlots(
    List<TimeSlotModel> slots,
    DateTime date, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final bool isToday = date.year == current.year &&
        date.month == current.month &&
        date.day == current.day;

    if (!isToday) return slots;

    final int currentMinutes = current.hour * 60 + current.minute;
    return slots.where((slot) {
      final int? slotMins = labelToMinutes(slot.label);
      if (slotMins == null) return true;
      return slotMins > currentMinutes;
    }).toList();
  }

  /// Converts a time label ("1:30 PM", "13:30") to minutes since midnight.
  static int? labelToMinutes(String label) {
    try {
      final clean = label.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return null;
      int hour = int.parse(parts[0]);
      final int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return null;
    }
  }

  // ── 4. Normalisation Helpers ─────────────────────────────────────────────

  /// Normalises a time label for robust comparison.
  /// Strips leading zeros from the hour so "01:30 PM" == "1:30 PM",
  /// uppercases the AM/PM suffix, and collapses whitespace.
  static String normaliseTimeLabel(String raw) => _normaliseTimeLabel(raw);

  static String _normaliseTimeLabel(String raw) {
    final clean = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    return clean.replaceFirstMapped(
      RegExp(r'^0*(\d+:.*)'),
      (m) => m.group(1)!,
    );
  }

  /// Returns true if [docDate] represents the same calendar day as [targetDate].
  static bool isSameDate(String docDate, String targetDate) =>
      _isSameDate(docDate, targetDate);

  static bool _isSameDate(String docDate, String targetDate) {
    if (docDate.isEmpty || targetDate.isEmpty) return false;
    if (docDate.trim() == targetDate.trim()) return true;

    final dt1 = _parseAnyDate(docDate);
    final dt2 = _parseAnyDate(targetDate);

    if (dt1 != null && dt2 != null) {
      return dt1.year == dt2.year &&
          dt1.month == dt2.month &&
          dt1.day == dt2.day;
    }

    final d1Norm = docDate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final d2Norm =
        targetDate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return d1Norm == d2Norm;
  }

  static DateTime? _parseAnyDate(String raw) {
    try {
      final iso = DateTime.tryParse(raw.trim());
      if (iso != null) return iso;

      final parts = raw.trim().split(RegExp(r'[-/.]'));
      if (parts.length == 3) {
        final p = parts.map((e) => int.tryParse(e)).toList();
        if (p.every((v) => v != null)) {
          if (p[0]! > 1000) return DateTime(p[0]!, p[1]!, p[2]!);
          if (p[2]! > 1000) return DateTime(p[2]!, p[1]!, p[0]!);
        }
      }

      const months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final wordParts = raw.trim().toLowerCase().split(RegExp(r'[\s,]+'));
      int? day, month, year;
      for (final part in wordParts) {
        if (months.containsKey(part)) {
          month = months[part];
        } else {
          final n = int.tryParse(part);
          if (n != null) {
            if (n > 1000) {
              year = n;
            } else if (day == null) {
              day = n;
            } else {
              year ??= n;
            }
          }
        }
      }
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }
}
