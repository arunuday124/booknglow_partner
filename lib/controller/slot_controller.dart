import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/bookings_controller.dart';
import '../controller/profile_controller.dart';
import '../model/booking_model.dart';
import '../model/time_slot_model.dart';
import '../service/slot_service.dart';

/// GetX controller for the Slot Availability screen.
///
/// Configured for purely MANUAL updates (no real-time background streams):
///   - Loads data on page open using in-memory cache when possible.
///   - Switching dates recalculates slots instantly in-memory (0 network calls).
///   - Updates ONLY when the user performs a pull-to-refresh (scroll down) or taps the reload button.
class SlotController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<TimeSlotModel> slots = <TimeSlotModel>[].obs;
  final RxBool isLoading = true.obs;

  final RxInt selectedDurationMinutes = 30.obs;

  final Rx<TimeOfDay> openingTime = const TimeOfDay(hour: 10, minute: 0).obs;
  final Rx<TimeOfDay> closingTime = const TimeOfDay(hour: 20, minute: 0).obs;

  final RxString openingLabel = '10:00 AM'.obs;
  final RxString closingLabel = '08:00 PM'.obs;

  // ── Cached bookings for zero-network date switching ──────────────────────

  final List<BookingModel> _cachedBookings = [];
  String _salonId = '';

  // ── Firestore ────────────────────────────────────────────────────────────

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _salonId = _currentSalonId;
    _loadInitialData();
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Change the selected date — recomputes slots instantly from in-memory cache (0 network calls)
  void selectDate(DateTime date) {
    selectedDate.value = date;
    _recomputeSlots();
  }

  /// Change the selected duration filter — recomputes slots and continuous conflict availability
  void selectDuration(int minutes) {
    selectedDurationMinutes.value = minutes;
    _recomputeSlots();
  }

  /// Force a manual refresh (triggered ONLY by pull-to-refresh or reload button)
  Future<void> refreshSlots() async {
    isLoading.value = true;
    try {
      // 1. Re-check salon hours
      await _loadSalonHours(force: false);

      // 2. Synchronize bookings cache with a single clean query
      if (Get.isRegistered<BookingsController>()) {
        final bookingsCtrl = Get.find<BookingsController>();
        await bookingsCtrl.fetchBookings(force: true);
        _cachedBookings.clear();
        _cachedBookings.addAll(bookingsCtrl.allBookings);
      } else {
        final snapshot = await _db
            .collection('bookings')
            .where('salonId', isEqualTo: _salonId)
            .get();
        _cachedBookings.clear();
        _cachedBookings.addAll(
          snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)),
        );
      }

      // 3. Recompute slots in-memory (0 network calls)
      _recomputeSlots();
    } catch (e) {
      debugPrint('SlotController: Error during refreshSlots: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Number of available starting slots for the selected duration.
  int get availableCount => slots.where((s) => s.isSelectable).length;

  /// Number of directly booked / locked slots.
  int get bookedCount => slots.where((s) => s.isBooked).length;

  /// Number of slots unavailable due to duration overlap with a locked slot or closing time.
  int get conflictCount =>
      slots.where((s) => !s.isBooked && !s.isAvailableForDuration).length;

  /// Formatted date string for display (e.g. "Mon, Aug 11").
  String get formattedDate {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = selectedDate.value;
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  /// Firestore date string for the selected date (matches booking documents).
  String get firestoreDateString {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = selectedDate.value;
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// Find the next available slot after [label] that accommodates selected duration.
  TimeSlotModel? nextAvailableAfter(String label) {
    return SlotService.findNextAvailableForDuration(
      slots,
      label,
      selectedDurationMinutes.value,
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String get _currentSalonId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) return user.uid;
    return 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2';
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      await _loadSalonHours();
      await _loadBookingsOnce();
      _recomputeSlots();
    } catch (e) {
      debugPrint('SlotController: Error loading initial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSalonHours({bool force = false}) async {
    // 1. Check ProfileController in memory first (0 network calls)
    if (!force && Get.isRegistered<ProfileController>()) {
      final profile = Get.find<ProfileController>();
      if (profile.openingTime.value != null &&
          profile.closingTime.value != null) {
        openingTime.value = profile.openingTime.value!;
        closingTime.value = profile.closingTime.value!;
        openingLabel.value = profile.formatTime(openingTime.value);
        closingLabel.value = profile.formatTime(closingTime.value);
        return;
      }
    }

    try {
      final doc = await _db.collection('salons').doc(_salonId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String opening = (data['openingHours'] ?? '10:00 AM').toString();
        final String closing = (data['closingHours'] ?? '08:00 PM').toString();
        openingLabel.value = opening;
        closingLabel.value = closing;
        openingTime.value =
            _parseTimeLabel(opening) ?? const TimeOfDay(hour: 10, minute: 0);
        closingTime.value =
            _parseTimeLabel(closing) ?? const TimeOfDay(hour: 20, minute: 0);
      }
    } catch (e) {
      debugPrint('SlotController: Error loading salon hours: $e');
    }
  }

  Future<void> _loadBookingsOnce() async {
    // 1. Check BookingsController in-memory cache first (0 network calls)
    if (Get.isRegistered<BookingsController>()) {
      final bookingsCtrl = Get.find<BookingsController>();
      if (bookingsCtrl.allBookings.isNotEmpty) {
        _cachedBookings.clear();
        _cachedBookings.addAll(bookingsCtrl.allBookings);
        return;
      }
    }

    // 2. Fallback to a single one-shot fetch only if in-memory cache is empty
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('salonId', isEqualTo: _salonId)
          .get();
      _cachedBookings.clear();
      _cachedBookings.addAll(
        snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)),
      );
    } catch (e) {
      debugPrint('SlotController: Error loading bookings once: $e');
    }
  }

  void _recomputeSlots() {
    // 1. Sync from in-memory BookingsController cache if available (0 network calls)
    if (Get.isRegistered<BookingsController>() &&
        Get.find<BookingsController>().allBookings.isNotEmpty) {
      _cachedBookings.clear();
      _cachedBookings.addAll(Get.find<BookingsController>().allBookings);
    }

    final generatedSlots = SlotService.generateSlots(
      openingTime.value,
      closingTime.value,
    );

    final bookedTimes = SlotService.extractBookedTimesFromModels(
      _cachedBookings,
      firestoreDateString,
    );

    final merged = SlotService.mergeSlots(generatedSlots, bookedTimes);
    final evaluated = SlotService.evaluateSlotsForDuration(
      merged,
      selectedDurationMinutes.value,
    );

    slots.assignAll(evaluated);
  }

  static TimeOfDay? _parseTimeLabel(String raw) {
    try {
      final clean = raw.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return null;
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }
}
