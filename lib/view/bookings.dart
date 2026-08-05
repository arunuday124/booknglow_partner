import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/bookings_controller.dart';
import '../controller/dashboard_controller.dart';
import '../model/booking_model.dart';

/// Bookings / Appointments View built using GetView (StatelessWidget) and GetX
class BookingsView extends GetView<BookingsController> {
  const BookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controllers
    Get.put(BookingsController());
    Get.put(DashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          "Book'N'Glow",
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 10.0,
            bottom: 20.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AppointmentsTitleSection(),
                  SizedBox(height: 32),
                  _PendingRequestsHeaderSection(),
                  SizedBox(height: 20),
                  _BookingCardsListSection(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title & Subtitle Section ("Appointments")
class _AppointmentsTitleSection extends StatelessWidget {
  const _AppointmentsTitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointments',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your upcoming bookings and client requests.',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Section Header ("Pending Requests", See All button)
class _PendingRequestsHeaderSection extends GetView<BookingsController> {
  const _PendingRequestsHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Pending Requests',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
            height: 1.12,
          ),
        ),
        const Spacer(),
        // See All button
        InkWell(
          onTap: controller.navigateToAllBookings,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF041C16),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF041C16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Reactive List of Booking Cards (Main Page: Queue of Max 5 Pending items)
class _BookingCardsListSection extends GetView<BookingsController> {
  const _BookingCardsListSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingBookings.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Color(0xFF041C16)),
          ),
        );
      }

      final list = controller.recentPendingBookings;
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
                'No pending requests found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You are all caught up with your bookings.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue status & count badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E4D7), // Warm peach background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.pendingCount} New',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C4E3D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final booking = list[index];
              return _BookingCardWidget(booking: booking);
            },
          ),
        ],
      );
    });
  }
}

/// Individual Booking Card (StatelessWidget)
class _BookingCardWidget extends GetView<BookingsController> {
  final BookingModel booking;

  const _BookingCardWidget({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left edge warm peach accent strip
              Container(width: 5, color: const Color(0xFFF5E4D7)),
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Name, Time, Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ClientAvatarWidget(booking: booking),
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
                          _StatusBadgeWidget(status: booking.status),
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
                      // Action Buttons: State Dependent (Accept/Reschedule -> Completed/Cancel -> Completed/Cancelled banner)
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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

/// Client Avatar Widget (Stateless)
class _ClientAvatarWidget extends StatelessWidget {
  final BookingModel booking;

  const _ClientAvatarWidget({required this.booking});

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

/// Status Badge Widget (Stateless)
class _StatusBadgeWidget extends StatelessWidget {
  final String status;

  const _StatusBadgeWidget({required this.status});

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
