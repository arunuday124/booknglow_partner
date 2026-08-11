import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/booking_model.dart';
import '../view/all_bookings.dart';
import 'transaction_controller.dart';

/// GetX Controller managing bookings state and actions with real-time Firestore integration
class BookingsController extends GetxController {
  // Reactive list of bookings for main queue view (max 5 pending bookings)
  final RxList<BookingModel> pendingQueueBookings = <BookingModel>[].obs;

  // Total pending bookings count badge
  final RxInt totalPendingCount = 0.obs;

  // Loading state for main page stream
  final RxBool isLoadingBookings = true.obs;

  // Reactive clock — updates every minute to drive the dynamic "Next Up" card
  final Rx<DateTime> currentTime = DateTime.now().obs;
  Timer? _clockTimer;

  // Selected filter option ('All', 'Pending', 'Accepted', 'Rescheduled', 'Completed', 'Cancelled')
  final RxString selectedFilter = 'All'.obs;

  // Firestore & Auth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns current authenticated salon ID, falling back to default salonId if user is unauthenticated
  String get currentSalonId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2';
  }

  @override
  void onInit() {
    super.onInit();
    _bindPendingQueueStream();
    _startClockTimer();
  }

  /// Fires every 60 seconds so Obx blocks reading [currentTime] rebuild automatically.
  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      currentTime.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  // All pending bookings cache for dynamic queue management
  final RxList<BookingModel> _allPendingBookings = <BookingModel>[].obs;

  /// Refreshes pending queue by filtering active pending items and taking top 5
  void _refreshQueue() {
    final pendingList = _allPendingBookings
        .where((b) => b.status.toLowerCase() == 'pending')
        .toList();

    totalPendingCount.value = pendingList.length;
    // Top 5 pending bookings for the main booking page queue
    pendingQueueBookings.assignAll(pendingList.take(5).toList());
  }

  /// Binds real-time Firestore stream for the main booking page queue.
  void _bindPendingQueueStream() {
    if (pendingQueueBookings.isEmpty) {
      isLoadingBookings.value = true;
    }

    // Listen to bookings collection for current salonId in real-time
    _firestore
        .collection('bookings')
        .where('salonId', isEqualTo: currentSalonId)
        .snapshots()
        .listen(
          (snapshot) {
            isLoadingBookings.value = false;
            final docs = snapshot.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList();
            _sortBookingsByCreatedAtDesc(docs);
            _allPendingBookings.assignAll(docs);
            _refreshQueue();
          },
          onError: (error) {
            isLoadingBookings.value = false;
            _refreshQueue();
            debugPrint('Error listening to bookings stream: $error');
          },
        );
  }

  /// Returns total count of all bookings for the current salon
  int get allBookingsCount => _allPendingBookings.length;

  /// Returns total count of pending bookings
  int get pendingCount => totalPendingCount.value;

  /// Returns all bookings fetched from Firestore
  List<BookingModel> get allBookings => _allPendingBookings;

  /// Returns active upcoming bookings (Pending, Accepted, Rescheduled) from Firestore
  List<BookingModel> get upcomingBookings {
    final list = _allPendingBookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'pending' ||
          s == 'accepted' ||
          s == 'rescheduled' ||
          s == 'confirmed';
    }).toList();
    if (list.isNotEmpty) return list;
    return _allPendingBookings;
  }

  /// Helper method to determine if a BookingModel is scheduled strictly for today's date
  bool _isBookingForToday(BookingModel booking) {
    final now = DateTime.now();

    bool isSameCalendarDay(DateTime dt) {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }

    final dateStr = booking.date.trim();

    // 1. If dateStr is empty, check createdAt timestamp
    if (dateStr.isEmpty) {
      if (booking.createdAt != null) {
        DateTime? createdDate;
        if (booking.createdAt is Timestamp) {
          createdDate = (booking.createdAt as Timestamp).toDate();
        } else if (booking.createdAt is DateTime) {
          createdDate = booking.createdAt as DateTime;
        } else if (booking.createdAt is String) {
          createdDate = DateTime.tryParse(booking.createdAt.toString());
        }

        if (createdDate != null) {
          return isSameCalendarDay(createdDate);
        }
      }
      return false;
    }

    final lowerDate = dateStr.toLowerCase();

    // 2. Check literal "today"
    if (lowerDate.contains('today')) {
      return true;
    }

    // 3. Try parsing ISO / standard DateTime (e.g. "2026-08-06", "2026-08-06T10:30:00")
    final parsedIso = DateTime.tryParse(dateStr);
    if (parsedIso != null) {
      return isSameCalendarDay(parsedIso);
    }

    // 4. Split by dashes, slashes, or dots (e.g., "06-08-2026", "2026/08/06", "6/8/2026")
    final parts = dateStr.split(RegExp(r'[-/.]'));
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);

      if (p0 != null && p1 != null && p2 != null) {
        // Format: YYYY-MM-DD or YYYY/MM/DD
        if (p0 > 1000) {
          return p0 == now.year && p1 == now.month && p2 == now.day;
        }
        // Format: DD-MM-YYYY or MM-DD-YYYY or DD/MM/YYYY
        if (p2 > 1000) {
          if (p2 != now.year) return false;
          if (p0 == now.day && p1 == now.month) return true;
          if (p1 == now.day && p0 == now.month) return true;
          return false;
        }
      }
    }

    // 5. Month name matching (e.g. "6 Aug 2026", "August 6, 2026", "6th August")
    final monthNames = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final currentMonthName = monthNames[now.month - 1];

    if (lowerDate.contains(currentMonthName)) {
      final numbers = RegExp(
        r'\d+',
      ).allMatches(dateStr).map((m) => int.parse(m.group(0)!)).toList();

      final hasDay = numbers.any((n) => n == now.day);
      final hasWrongDay = numbers.any(
        (n) =>
            n >= 1 &&
            n <= 31 &&
            n != now.day &&
            n != now.year &&
            n != (now.year % 100),
      );

      if (hasDay && !hasWrongDay) {
        final yearInStr = numbers.firstWhere(
          (n) => n > 31,
          orElse: () => now.year,
        );
        if (yearInStr == now.year || yearInStr == (now.year % 100)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Returns upcoming bookings ONLY scheduled for today's date
  List<BookingModel> get todaysUpcomingBookings {
    return _allPendingBookings.where((b) {
      final status = b.status.toLowerCase();
      final isUpcomingStatus =
          status == 'pending' ||
          status == 'accepted' ||
          status == 'rescheduled' ||
          status == 'confirmed';
      return isUpcomingStatus && _isBookingForToday(b);
    }).toList();
  }

  /// Parses a booking's [time] string (e.g. "10:30 AM", "14:30", "2:30 PM") into a
  /// [DateTime] anchored on today's date. Returns null when the string is unparseable
  /// or empty (those bookings are excluded from the "Next Up" time-based sort).
  DateTime? _parseBookingTime(BookingModel booking) {
    final raw = booking.time.trim();
    if (raw.isEmpty) return null;

    final now = currentTime.value;
    final today = DateTime(now.year, now.month, now.day);

    // --- 12-hour format: "10:30 AM" / "2:30 PM" / "10 AM" ---
    final amPmRegex = RegExp(
      r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
      caseSensitive: false,
    );
    final amPmMatch = amPmRegex.firstMatch(raw);
    if (amPmMatch != null) {
      int hour = int.parse(amPmMatch.group(1)!);
      final int minute = int.tryParse(amPmMatch.group(2) ?? '0') ?? 0;
      final String period = amPmMatch.group(3)!.toUpperCase();
      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }
      return today.add(Duration(hours: hour, minutes: minute));
    }

    // --- 24-hour format: "14:30" / "9:05" ---
    final h24Regex = RegExp(r'^(\d{1,2}):(\d{2})$');
    final h24Match = h24Regex.firstMatch(raw);
    if (h24Match != null) {
      final int hour = int.parse(h24Match.group(1)!);
      final int minute = int.parse(h24Match.group(2)!);
      if (hour < 24 && minute < 60) {
        return today.add(Duration(hours: hour, minutes: minute));
      }
    }

    return null;
  }

  /// Returns the single booking that should be displayed in the "Next Up" card:
  /// - Must be for today
  /// - Must be confirmed or accepted (pending/rescheduled are excluded)
  /// - Priority 1: The booking that has already started (time <= now) — the most
  ///   recent one before now represents the currently in-progress appointment.
  /// - Priority 2: If no booking has started yet, show the next upcoming one
  ///   (earliest time strictly after now).
  /// - Returns null when there are no confirmed bookings for today (card is hidden)
  BookingModel? get nextUpBooking {
    // Reading currentTime.value makes this getter reactive to the 1-min timer.
    final now = currentTime.value;

    // Only confirmed / accepted bookings qualify for the Next Up card
    final todayList = todaysUpcomingBookings.where((b) {
      final s = b.status.toLowerCase();
      return s == 'confirmed' || s == 'accepted';
    }).toList();

    if (todayList.isEmpty) return null;

    // ── Priority 1: bookings that have already started (time <= now) ──────────
    // Pick the most recent one before now — that is the current appointment.
    final alreadyStarted = todayList.where((b) {
      final t = _parseBookingTime(b);
      if (t == null) return false; // unparseable times fall through to priority 2
      return !t.isAfter(now); // t <= now
    }).toList()
      ..sort((a, b) {
        final ta = _parseBookingTime(a);
        final tb = _parseBookingTime(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta); // descending: latest started first
      });

    if (alreadyStarted.isNotEmpty) return alreadyStarted.first;

    // ── Priority 2: no booking has started yet — show the next upcoming one ───
    final upcoming = todayList.where((b) {
      final t = _parseBookingTime(b);
      // If time is unparseable, treat it as upcoming (show rather than hide)
      if (t == null) return true;
      return t.isAfter(now); // strictly in the future
    }).toList()
      ..sort((a, b) {
        final ta = _parseBookingTime(a);
        final tb = _parseBookingTime(b);
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return ta.compareTo(tb); // ascending: earliest upcoming first
      });

    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Manual refresh for pull-to-refresh
  Future<void> fetchBookings({bool force = false}) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('salonId', isEqualTo: currentSalonId)
          .get();

      final docs = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
      _sortBookingsByCreatedAtDesc(docs);
      _allPendingBookings.assignAll(docs);
      _refreshQueue();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  /// Returns main queue list (max 5 pending bookings)
  List<BookingModel> get recentPendingBookings => pendingQueueBookings;

  /// Returns all bookings filtered by selectedFilter ('All', 'Pending', 'Accepted', 'Rescheduled', 'Completed', 'Cancelled'), sorted by createdAt descending
  List<BookingModel> get filteredAllBookings {
    final filter = selectedFilter.value.trim().toLowerCase();
    final list = _allPendingBookings.toList();
    _sortBookingsByCreatedAtDesc(list);

    if (filter == 'all') {
      return list;
    }

    return list.where((b) {
      final s = b.status.toLowerCase();
      if (filter == 'accepted') {
        return s == 'accepted' || s == 'confirmed';
      }
      if (filter == 'cancelled') {
        return s == 'cancelled' || s == 'canceled';
      }
      return s == filter;
    }).toList();
  }

  /// Builds a Firestore query for the "See All" page
  Query<BookingModel> getFirestoreQuery() {
    Query query = _firestore
        .collection('bookings')
        .where('salonId', isEqualTo: currentSalonId);

    final filter = selectedFilter.value;
    if (filter != 'All' &&
        [
          'Pending',
          'Accepted',
          'Rescheduled',
          'Completed',
          'Cancelled',
        ].contains(filter)) {
      query = query.where('bookingStatus', isEqualTo: filter);
    }

    return query.withConverter<BookingModel>(
      fromFirestore: (snapshot, _) => BookingModel.fromFirestore(snapshot),
      toFirestore: (booking, _) => {},
    );
  }

  /// Sorts bookings list by createdAt timestamp descending (newest bookings first)
  void _sortBookingsByCreatedAtDesc(List<BookingModel> docs) {
    docs.sort((a, b) {
      final dtA = _parseTimestamp(a.createdAt);
      final dtB = _parseTimestamp(b.createdAt);

      if (dtA != null && dtB != null) {
        return dtB.compareTo(dtA);
      }
      if (dtA != null) return -1;
      if (dtB != null) return 1;
      return 0;
    });
  }

  DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  /// Action: Update status in Firestore & Local State
  Future<void> updateBookingStatus(
    BookingModel booking,
    String newStatus,
  ) async {
    try {
      // 1. Update in local state for instant UI update & top 5 queue recalculation
      final index = _allPendingBookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _allPendingBookings[index] = _allPendingBookings[index].copyWith(
          status: newStatus,
        );
        _refreshQueue();
      }

      // 2. Update Firestore document ONLY for this specific booking
      if (booking.id.isNotEmpty && !booking.id.startsWith('bk_')) {
        // Update exact bookings document
        await _firestore.collection('bookings').doc(booking.id).update({
          'bookingStatus': newStatus,
          'status': newStatus,
        });

        // 3. Update transactions collection ONLY when status is Completed or Cancelled
        final String lowerStatus = newStatus.toLowerCase();
        if (lowerStatus == 'completed' ||
            lowerStatus == 'cancelled' ||
            lowerStatus == 'canceled') {
          final String targetPaymentStatus = lowerStatus == 'completed'
              ? 'completed'
              : 'canceled';

          // Update strictly the 'paymentStatus' field in matching transaction document
          final txnDoc = await _firestore
              .collection('transactions')
              .doc(booking.id)
              .get();
          if (txnDoc.exists) {
            await _firestore.collection('transactions').doc(booking.id).update({
              'paymentStatus': targetPaymentStatus,
            });
          } else {
            final txnQuery = await _firestore
                .collection('transactions')
                .where('bookingId', isEqualTo: booking.id)
                .get();

            for (var doc in txnQuery.docs) {
              await _firestore.collection('transactions').doc(doc.id).update({
                'paymentStatus': targetPaymentStatus,
              });
            }
          }

          // Trigger TransactionController refresh if active in memory
          if (Get.isRegistered<TransactionController>()) {
            Get.find<TransactionController>().fetchTransactions(force: true);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update booking status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Action: Confirm Booking (updates Firestore status to 'Confirmed')
  Future<void> confirmBooking(BookingModel booking) async {
    await updateBookingStatus(booking, 'Confirmed');
    Get.snackbar(
      'Booking Confirmed',
      'Appointment for ${booking.clientName} has been confirmed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  /// Confirmation Popup before Completing Booking
  void confirmCompleteBooking(BookingModel booking) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF166534),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Appointment',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Is the service and payment completed for ${booking.clientName}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'No, Not Yet',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        completeBooking(booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Yes, Completed',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirmation Popup before Cancelling Booking
  void confirmCancelBooking(BookingModel booking) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cancel Booking?',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Do you really want to cancel the appointment for ${booking.clientName}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Keep Booking',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        cancelBooking(booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Yes, Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action: Complete Booking
  Future<void> completeBooking(BookingModel booking) async {
    await updateBookingStatus(booking, 'Completed');
    Get.snackbar(
      'Booking Completed',
      'Appointment for ${booking.clientName} has been marked as completed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF166534),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.task_alt_rounded, color: Colors.white),
    );
  }

  /// Action: Cancel Booking
  Future<void> cancelBooking(BookingModel booking) async {
    await updateBookingStatus(booking, 'Cancelled');
    Get.snackbar(
      'Booking Cancelled',
      'Appointment for ${booking.clientName} has been cancelled.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.cancel_outlined, color: Colors.white),
    );
  }

  /// Action: Reschedule Booking
  void rescheduleBooking(BookingModel booking) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reschedule Request',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF041C16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Propose a new time for ${booking.clientName} (${booking.serviceName})',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _updateBookingTime(booking, '10:00 AM', '05 Aug 2026');
                      Get.back();
                    },
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('10:00 AM, 05 Aug'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF041C16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _updateBookingTime(booking, '4:00 PM', '05 Aug 2026');
                      Get.back();
                    },
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('4:00 PM, 05 Aug'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF041C16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  _updateBookingTime(booking, '5:30 PM', '04 Aug 2026');
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF041C16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm New Slot',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBookingTime(
    BookingModel booking,
    String time,
    String date,
  ) async {
    try {
      if (booking.id.isNotEmpty && !booking.id.startsWith('bk_')) {
        await _firestore.collection('bookings').doc(booking.id).update({
          'bookingStatus': 'Rescheduled',
          'time': time,
          'date': date,
        });
      }
      Get.snackbar(
        'Booking Rescheduled',
        'Proposed new time ($time, $date) for ${booking.clientName}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF041C16),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.edit_calendar_outlined, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reschedule booking in Firestore: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Action: Navigate to See All Page
  void navigateToAllBookings() {
    Get.to(() => const AllBookingsView());
  }

  /// Action: Show Filter Dialog
  void showFilterOptions() {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.85),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterOption('All', 'Show all request cards'),
                      _buildFilterOption(
                        'Pending',
                        'Show pending requests only',
                      ),
                      _buildFilterOption('Accepted', 'Show accepted requests'),
                      _buildFilterOption(
                        'Rescheduled',
                        'Show rescheduled requests',
                      ),
                      _buildFilterOption(
                        'Completed',
                        'Show completed requests',
                      ),
                      _buildFilterOption(
                        'Cancelled',
                        'Show cancelled requests',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String option, String subtitle) {
    final isSelected = selectedFilter.value == option;
    return ListTile(
      onTap: () {
        selectedFilter.value = option;
        Get.back();
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? const Color(0xFF041C16) : const Color(0xFF9CA3AF),
      ),
      title: Text(
        option,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF041C16),
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}
