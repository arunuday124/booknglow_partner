import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/bookings_controller.dart';
import '../model/booking_model.dart';

/// Dedicated "See All" Bookings View built with StatelessWidget & GetX
class AllBookingsView extends GetView<BookingsController> {
  const AllBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final BookingsController controller = Get.put(BookingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF041C16), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'All Appointments',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF041C16)),
            onPressed: controller.showFilterOptions,
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFF0F0F0),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _FilterChipsSection(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: const _AllBookingsListSection(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal Filter Chips Section
class _FilterChipsSection extends GetView<BookingsController> {
  const _FilterChipsSection();

  @override
  Widget build(BuildContext context) {
    final filters = [
      'All',
      'Pending',
      'Accepted',
      'Rescheduled',
      'Completed',
      'Cancelled'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      color: const Color(0xFFF8F9F8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Obx(
          () => Row(
            children: filters.map((filter) {
              final isSelected = controller.selectedFilter.value == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      controller.selectedFilter.value = filter;
                    }
                  },
                  selectedColor: const Color(0xFF041C16),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF041C16)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// List Section displaying all filtered bookings
class _AllBookingsListSection extends GetView<BookingsController> {
  const _AllBookingsListSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.filteredBookings;

      if (list.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 12),
              Text(
                'No bookings found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'There are no bookings matching the selected filter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final booking = list[index];
          return _AllBookingCardItem(booking: booking);
        },
      );
    });
  }
}

/// Individual Booking Card for All Bookings Page
class _AllBookingCardItem extends GetView<BookingsController> {
  final BookingModel booking;

  const _AllBookingCardItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent strip
              Container(
                width: 5,
                color: booking.status == 'Accepted'
                    ? const Color(0xFF22C55E)
                    : (booking.status == 'Rescheduled'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFF5E4D7)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ClientAvatarItem(booking: booking),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.clientName,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF041C16),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_outlined,
                                      size: 15,
                                      color: Color(0xFF4B5563),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${booking.time}, ${booking.date}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF4B5563),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _StatusBadgeItem(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),
                      const SizedBox(height: 16),
                      // Multiple Services Bullet List
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: booking.services.map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF041C16),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    service,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF041C16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (booking.totalPrice > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Price',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '₹${booking.totalPrice.toInt()}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF041C16),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (booking.notes != null &&
                          booking.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          booking.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4B5563),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons: State Dependent
                      if (booking.status == 'Accepted') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    controller.confirmCompleteBooking(booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF166534),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Completed',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    controller.confirmCancelBooking(booking),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFFDC2626),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFFDC2626),
                                    width: 1.2,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (booking.status == 'Completed' ||
                          booking.status == 'Cancelled') ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: booking.status == 'Completed'
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: booking.status == 'Completed'
                                  ? const Color(0xFFBBF7D0)
                                  : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                booking.status == 'Completed'
                                    ? Icons.task_alt_rounded
                                    : Icons.cancel_outlined,
                                size: 18,
                                color: booking.status == 'Completed'
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF991B1B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                booking.status == 'Completed'
                                    ? 'Appointment Completed'
                                    : 'Appointment Cancelled',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: booking.status == 'Completed'
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    controller.acceptBooking(booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF041C16),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Accept',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    controller.rescheduleBooking(booking),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF041C16),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                    width: 1.2,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Reschedule',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF041C16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _ClientAvatarItem extends StatelessWidget {
  final BookingModel booking;

  const _ClientAvatarItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.avatarUrl != null && booking.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE5E7EB),
        backgroundImage: NetworkImage(booking.avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {},
        child: null,
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE5E7EB),
      child: Text(
        booking.initials,
        style: GoogleFonts.playfairDisplay(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF041C16),
        ),
      ),
    );
  }
}

class _StatusBadgeItem extends StatelessWidget {
  final String status;

  const _StatusBadgeItem({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor = const Color(0xFFECECEC);
    Color textColor = const Color(0xFF374151);
    IconData iconData = Icons.hourglass_empty_rounded;

    if (status == 'Accepted') {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      iconData = Icons.check_circle_outline;
    } else if (status == 'Completed') {
      bgColor = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF065F46);
      iconData = Icons.task_alt_rounded;
    } else if (status == 'Cancelled') {
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFF991B1B);
      iconData = Icons.cancel_outlined;
    } else if (status == 'Rescheduled') {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
      iconData = Icons.edit_calendar_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
