import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/booking_model.dart';

import '../view/all_bookings.dart';

/// GetX Controller managing bookings state and actions
class BookingsController extends GetxController {
  // Reactive list of bookings
  final RxList<BookingModel> bookingsList = <BookingModel>[].obs;

  // Selected filter option ('All', 'Pending', 'Today', 'Tomorrow')
  final RxString selectedFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialBookings();
  }

  /// Loads initial booking requests matching the design requirement
  void loadInitialBookings() {
    bookingsList.assignAll([
      BookingModel(
        id: 'bk_001',
        clientName: 'Arunuday Debnath',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        initials: 'AD',
        time: '11:00 AM',
        date: '04 Aug 2026',
        services: ['Hair Cut', 'Hair Spa', 'Head Massage'],
        totalPrice: 1499.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_002',
        clientName: 'Sarah Jenkins',
        avatarUrl: null,
        initials: 'SJ',
        time: '2:30 PM',
        date: '05 Aug 2026',
        services: ['Balayage Color', 'Hair Styling', 'Deep Conditioning'],
        totalPrice: 3500.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_003',
        clientName: 'Priya Sharma',
        avatarUrl: null,
        initials: 'PS',
        time: '3:15 PM',
        date: '04 Aug 2026',
        services: ['Keratin Treatment', 'Hair Trim'],
        totalPrice: 2800.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_004',
        clientName: 'Michael Brown',
        avatarUrl: null,
        initials: 'MB',
        time: '4:00 PM',
        date: '04 Aug 2026',
        services: ['Beard Trim', 'Gentlemen Beard Styling'],
        totalPrice: 650.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_005',
        clientName: 'Ananya Verma',
        avatarUrl: null,
        initials: 'AV',
        time: '10:00 AM',
        date: '05 Aug 2026',
        services: ['Facial Glow', 'Threading'],
        totalPrice: 999.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_006',
        clientName: 'David Miller',
        avatarUrl: null,
        initials: 'DM',
        time: '11:30 AM',
        date: '05 Aug 2026',
        services: ['Hair Cut', 'Scalp Treatment'],
        totalPrice: 1200.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_007',
        clientName: 'Rohan Gupta',
        avatarUrl: null,
        initials: 'RG',
        time: '1:00 PM',
        date: '05 Aug 2026',
        services: ['Classic Haircut', 'Hair Color Touchup'],
        totalPrice: 1800.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_008',
        clientName: 'Emma Watson',
        avatarUrl: null,
        initials: 'EW',
        time: '3:00 PM',
        date: '05 Aug 2026',
        services: ['Pedicure Spa', 'Manicure Care'],
        totalPrice: 1600.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_009',
        clientName: 'Vikram Mehta',
        avatarUrl: null,
        initials: 'VM',
        time: '4:30 PM',
        date: '05 Aug 2026',
        services: ['Haircut', 'Head Massage'],
        totalPrice: 850.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_010',
        clientName: 'Kavita Patel',
        avatarUrl: null,
        initials: 'KP',
        time: '5:15 PM',
        date: '05 Aug 2026',
        services: ['Hydra Facial', 'Eyebrow Shaping'],
        totalPrice: 2200.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_011',
        clientName: 'Alexander White',
        avatarUrl: null,
        initials: 'AW',
        time: '6:00 PM',
        date: '05 Aug 2026',
        services: ['Hair Coloring', 'Hair Wash'],
        totalPrice: 1950.0,
        status: 'Pending',
        isNew: true,
      ),
      BookingModel(
        id: 'bk_012',
        clientName: 'Sanya Malhotra',
        avatarUrl: null,
        initials: 'SM',
        time: '6:45 PM',
        date: '05 Aug 2026',
        services: ['Bridal Makeup Consultation'],
        totalPrice: 5000.0,
        status: 'Pending',
        isNew: true,
      ),
    ]);
  }

  /// Getter for pending requests count badge
  int get pendingCount =>
      bookingsList.where((b) => b.status == 'Pending').length;

  /// Main page list: capped at 10 new pending bookings
  List<BookingModel> get recentPendingBookings {
    return bookingsList.where((b) => b.status == 'Pending').take(10).toList();
  }

  /// Filtered list based on selected filter (for See All page)
  List<BookingModel> get filteredBookings {
    final filter = selectedFilter.value;
    if (filter == 'Pending' ||
        filter == 'Accepted' ||
        filter == 'Rescheduled' ||
        filter == 'Completed' ||
        filter == 'Cancelled') {
      return bookingsList.where((b) => b.status == filter).toList();
    } else if (filter == 'Today') {
      return bookingsList
          .where((b) => b.date.contains('04 Aug') || b.date == 'Today')
          .toList();
    } else if (filter == 'Tomorrow') {
      return bookingsList
          .where((b) => b.date.contains('05 Aug') || b.date == 'Tomorrow')
          .toList();
    }
    return bookingsList;
  }

  /// Action: Navigate to See All Page
  void navigateToAllBookings() {
    Get.to(() => const AllBookingsView());
  }

  /// Action: Accept Booking
  void acceptBooking(BookingModel booking) {
    final index = bookingsList.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookingsList[index] = booking.copyWith(status: 'Accepted', isNew: false);
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
  }

  /// Confirmation Popup before Completing Booking ("Is the service and payment completed?")
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

  /// Confirmation Popup before Cancelling Booking ("Do you really want to cancel?")
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
  void completeBooking(BookingModel booking) {
    final index = bookingsList.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookingsList[index] = booking.copyWith(status: 'Completed', isNew: false);
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
  }

  /// Action: Cancel Booking
  void cancelBooking(BookingModel booking) {
    final index = bookingsList.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookingsList[index] = booking.copyWith(status: 'Cancelled', isNew: false);
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF041C16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Propose a new time for ${booking.clientName} (${booking.serviceName})',
              style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280)),
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

  void _updateBookingTime(BookingModel booking, String time, String date) {
    final index = bookingsList.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      bookingsList[index] = booking.copyWith(
        time: time,
        date: date,
        status: 'Rescheduled',
        isNew: false,
      );
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
    }
  }

  /// Action: See All Bookings
  void onSeeAllPressed() {
    selectedFilter.value = 'All';
    Get.snackbar(
      'All Bookings',
      'Displaying all booking requests',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
    );
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
