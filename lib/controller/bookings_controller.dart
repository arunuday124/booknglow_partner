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
      _allPendingBookings.assignAll(docs);
      _refreshQueue();
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    }
  }

  /// Returns main queue list (max 5 pending bookings)
  List<BookingModel> get recentPendingBookings => pendingQueueBookings;

  /// Builds a Firestore query for the "See All" page using FirestoreListView with 10-10 pagination
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
        if (lowerStatus == 'completed' || lowerStatus == 'cancelled' || lowerStatus == 'canceled') {
          final String targetPaymentStatus = lowerStatus == 'completed' ? 'completed' : 'canceled';

          // Update strictly the 'paymentStatus' field in matching transaction document
          final txnDoc = await _firestore.collection('transactions').doc(booking.id).get();
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

  /// Action: Accept Booking
  Future<void> acceptBooking(BookingModel booking) async {
    await updateBookingStatus(booking, 'Accepted');
    Get.snackbar(
      'Booking Accepted',
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
