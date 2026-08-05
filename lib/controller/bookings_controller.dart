import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/booking_model.dart';
import '../view/all_bookings.dart';

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

  // Initial sample bookings list to ensure queue functionality works out-of-the-box
  final List<BookingModel> _sampleBookings = [
    BookingModel(
      id: 'bk_1',
      clientName: 'Sarah Jenkins',
      time: '10:30 AM',
      date: 'Today, 04 Aug',
      services: ['Signature HydraFacial', 'Eyebrow Threading'],
      totalPrice: 2499,
      notes: 'Please ensure sensitive skin products are used.',
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_2',
      clientName: 'Priya Sharma',
      time: '11:45 AM',
      date: 'Today, 04 Aug',
      services: ['L\'Oreal Hair Spa', 'Hair Cut & Blowdry'],
      totalPrice: 1850,
      notes: 'Prefers senior stylist if available.',
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_3',
      clientName: 'Anita Roy',
      time: '01:15 PM',
      date: 'Today, 04 Aug',
      services: ['Gel Nail Extensions', 'Classic Manicure'],
      totalPrice: 2100,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_4',
      clientName: 'Emma Watson',
      time: '02:30 PM',
      date: 'Today, 04 Aug',
      services: ['Bridal Makeup Consultation', 'Saree Draping'],
      totalPrice: 4500,
      notes: 'First time client.',
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_5',
      clientName: 'Meera Kapoor',
      time: '03:45 PM',
      date: 'Today, 04 Aug',
      services: ['Deluxe Pedicure', 'Foot Reflexology'],
      totalPrice: 1600,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_6',
      clientName: 'Rahul Verma',
      time: '05:00 PM',
      date: 'Today, 04 Aug',
      services: ['Beard Grooming & Styling', 'Head Massage'],
      totalPrice: 950,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_7',
      clientName: 'Jessica Alba',
      time: '06:15 PM',
      date: 'Today, 04 Aug',
      services: ['Nail Art (Chrome)', 'Cuticle Care'],
      totalPrice: 1400,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_8',
      clientName: 'Deepika P.',
      time: '11:00 AM',
      date: 'Tomorrow, 05 Aug',
      services: ['Full Body Waxing (Rica)', 'Threading'],
      totalPrice: 3200,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_9',
      clientName: 'Zoe Kravitz',
      time: '01:30 PM',
      date: 'Tomorrow, 05 Aug',
      services: ['Fruit Facial', 'Bleach'],
      totalPrice: 1750,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
    BookingModel(
      id: 'bk_10',
      clientName: 'Nina Dobrev',
      time: '04:00 PM',
      date: 'Tomorrow, 05 Aug',
      services: ['Balayage Hair Color', 'Olaplex Treatment'],
      totalPrice: 6800,
      status: 'Pending',
      salonId: 'SIZdJ6s5C0h6ckX7YSjLWEFmXnl2',
    ),
  ];

  /// Refreshes pending queue by filtering active pending items and taking top 5
  void _refreshQueue() {
    final pendingList =
        _allPendingBookings.where((b) => b.status == 'Pending').toList();

    totalPendingCount.value = pendingList.length;
    // Top 5 pending bookings for the main booking page queue
    pendingQueueBookings.assignAll(pendingList.take(5).toList());
  }

  /// Binds real-time Firestore stream for the main booking page queue.
  /// Optimized: Filters `bookingStatus == 'Pending'` and limits to 5 items directly on server side.
  void _bindPendingQueueStream() {
    isLoadingBookings.value = true;

    // Listen to bookings collection for current salonId (server-side limited to 5 pending items)
    _firestore
        .collection('bookings')
        .where('salonId', isEqualTo: currentSalonId)
        .where('bookingStatus', isEqualTo: 'Pending')
        .limit(5)
        .snapshots()
        .listen(
      (snapshot) {
        isLoadingBookings.value = false;
        if (snapshot.docs.isNotEmpty) {
          final pendingDocs =
              snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
          _allPendingBookings.assignAll(pendingDocs);
        } else {
          // Fallback to sample queue if Firestore has no documents yet
          if (_allPendingBookings.isEmpty) {
            _allPendingBookings.assignAll(_sampleBookings.take(5).toList());
          }
        }
        _refreshQueue();
      },
      onError: (error) {
        isLoadingBookings.value = false;
        if (_allPendingBookings.isEmpty) {
          _allPendingBookings.assignAll(_sampleBookings.take(5).toList());
        }
        _refreshQueue();
        debugPrint('Error listening to bookings stream: $error');
      },
    );
  }

  /// Returns total count of pending bookings
  int get pendingCount => totalPendingCount.value;

  /// Returns main queue list (max 5 pending bookings)
  List<BookingModel> get recentPendingBookings => pendingQueueBookings;

  /// Builds a Firestore query for the "See All" page using FirestoreListView with 10-10 pagination
  Query<BookingModel> getFirestoreQuery() {
    Query query =
        _firestore.collection('bookings').where('salonId', isEqualTo: currentSalonId);

    final filter = selectedFilter.value;
    if (filter != 'All' &&
        ['Pending', 'Accepted', 'Rescheduled', 'Completed', 'Cancelled']
            .contains(filter)) {
      query = query.where('bookingStatus', isEqualTo: filter);
    }

    return query.withConverter<BookingModel>(
      fromFirestore: (snapshot, _) => BookingModel.fromFirestore(snapshot),
      toFirestore: (booking, _) => {},
    );
  }

  /// Action: Update status in Firestore & Local State
  Future<void> updateBookingStatus(
      BookingModel booking, String newStatus) async {
    try {
      // 1. Update in local state for instant UI update & top 5 queue recalculation
      final index = _allPendingBookings.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _allPendingBookings[index] =
            _allPendingBookings[index].copyWith(status: newStatus);
        _refreshQueue();
      }

      // 2. Update Firestore document if not mock item
      if (booking.id.isNotEmpty && !booking.id.startsWith('bk_')) {
        await _firestore.collection('bookings').doc(booking.id).update({
          'bookingStatus': newStatus,
          'status': newStatus,
        });
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
