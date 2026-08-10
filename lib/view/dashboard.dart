import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/bookings_controller.dart';
import '../controller/dashboard_controller.dart';
import '../controller/transaction_controller.dart';
import 'bookings.dart';
import 'profile.dart';
import 'services.dart';

/// Main Dashboard View built using GetView (StatelessWidget) and GetX
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject DashboardController safely
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      body: Obx(
        () => IndexedStack(
          index: controller.selectedNavIndex.value,
          children: const [
            _DashboardHomeTab(),
            BookingsView(),
            ServicesView(),
            ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavigationBarWidget(),
    );
  }
}

/// Dashboard Home Tab Content
class _DashboardHomeTab extends StatelessWidget {
  const _DashboardHomeTab();

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          color: const Color(0xFF041C16),
          onRefresh: () async {
            // Trigger refresh for controllers when user scrolls down (pull-to-refresh)
            if (Get.isRegistered<DashboardController>()) {
              await Get.find<DashboardController>().fetchDashboardMetrics(
                force: true,
              );
            }
            if (Get.isRegistered<BookingsController>()) {
              await Get.find<BookingsController>().fetchBookings(force: true);
            }
            if (Get.isRegistered<TransactionController>()) {
              await Get.find<TransactionController>().fetchTransactions(
                force: true,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _WelcomeTitleSection(),
                SizedBox(height: 20),
                _MetricsRowSection(),
                SizedBox(height: 24),
                _NextUpSection(),
                SizedBox(height: 24),
                _DailyLogsSection(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Welcome Header Section ("Hello, Zen Salon")
class _WelcomeTitleSection extends GetView<DashboardController> {
  const _WelcomeTitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Text(
            'Hello, ${controller.firstName}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF041C16),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Here is an overview of your operations today.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

/// Overview Metrics Cards Row (Revenue, Bookings & Reviews)
class _MetricsRowSection extends GetView<DashboardController> {
  const _MetricsRowSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Revenue Card
        Expanded(
          child: Obx(() {
            if (!Get.isRegistered<TransactionController>()) {
              Get.put(TransactionController(), permanent: true);
            }
            final txnController = Get.find<TransactionController>();
            final double total = txnController.totalRevenue;

            String displayRevenue = '₹ 0';
            if (total >= 100000) {
              displayRevenue = '₹ ${(total / 100000).toStringAsFixed(1)}L';
            } else if (total >= 1000) {
              displayRevenue = '₹ ${(total / 1000).toStringAsFixed(1)}k';
            } else if (total > 0) {
              displayRevenue = '₹ ${total.toStringAsFixed(0)}';
            }

            return _MetricCard(
              title: 'REVENUE',
              icon: Icons.north_east_rounded,
              value: displayRevenue,
              subText: controller.revenueGrowth.value,
              subTextColor: const Color(0xFF16A34A),
            );
          }),
        ),
        const SizedBox(width: 10),
        // Bookings Card
        Expanded(
          child: Obx(() {
            if (!Get.isRegistered<BookingsController>()) {
              Get.put(BookingsController());
            }
            final bookingsCtrl = Get.find<BookingsController>();
            final int total = bookingsCtrl.allBookingsCount;
            final int pending = bookingsCtrl.pendingCount;

            return _MetricCard(
              title: 'BOOKINGS',
              icon: Icons.calendar_today_outlined,
              value: '$total',
              subText: '$pending Pending',
              subTextColor: const Color.fromARGB(
                255,
                217,
                13,
                6,
              ), // Amber / Warm Orange alert color
            );
          }),
        ),
        const SizedBox(width: 10),
        // Reviews Card
        Expanded(
          child: Obx(
            () => _MetricCard(
              title: 'REVIEWS',
              icon: Icons.star_border_rounded,
              value: controller.reviewsRating.value,
              subText: '${controller.totalReviews.value} Ratings',
              subTextColor: const Color(
                0xFF2563EB,
              ), // Vibrant Blue accent color
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual Metric Card Widget (Stateless)
class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final String subText;
  final Color? subTextColor;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.subText,
    this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
              Icon(icon, size: 15, color: const Color(0xFF4B5563)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF041C16),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subTextColor ?? const Color(0xFF5C5346),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Next Up" Appointment Card Section
class _NextUpSection extends StatelessWidget {
  const _NextUpSection();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BookingsController>()) {
      Get.put(BookingsController());
    }
    final bookingsCtrl = Get.find<BookingsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flash_on_rounded,
              size: 18,
              color: Color(0xFF5C5346),
            ),
            const SizedBox(width: 6),
            Text(
              'Next Up',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF041C16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          // Subscribing to currentTime makes this Obx rebuild every minute automatically.
          // ignore: unused_local_variable
          final _ = bookingsCtrl.currentTime.value;
          final nextItem = bookingsCtrl.nextUpBooking;

          if (nextItem == null) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2B23),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    color: Color(0xFFB0C4BE),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No upcoming appointments scheduled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB0C4BE),
                    ),
                  ),
                ],
              ),
            );
          }

          final clientName = nextItem.clientName;
          final service = nextItem.serviceName.isNotEmpty
              ? nextItem.serviceName
              : 'Salon Service';
          final time = nextItem.time.isNotEmpty
              ? nextItem.time
              : (nextItem.date.isNotEmpty ? nextItem.date : 'Today');

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2B23),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0A2B23),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Booking info row ──────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Client Avatar / Initials
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E463C),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        nextItem.initials,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Appointment Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  clientName,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFE0D3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  nextItem.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5C4E3D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB0C4BE),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFFB0C4BE),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: Color(0xFFB0C4BE),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₹${nextItem.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── Divider ───────────────────────────────────────────────
                const SizedBox(height: 14),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF1E463C),
                ),
                const SizedBox(height: 14),
                // ── Action Buttons ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            bookingsCtrl.confirmCompleteBooking(nextItem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0A2B23),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              size: 16,
                              color: Color(0xFF0A2B23),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Completed',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A2B23),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            bookingsCtrl.confirmCancelBooking(nextItem),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0x1AFFFFFF),
                          foregroundColor: const Color(0xFFB0C4BE),
                          elevation: 0,
                          side: const BorderSide(
                            color: Color(0x4DB0C4BE),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              size: 16,
                              color: Color(0xFFB0C4BE),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB0C4BE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Today's Upcoming Bookings List Section
class _DailyLogsSection extends GetView<DashboardController> {
  const _DailyLogsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF5C5346),
            ),
            const SizedBox(width: 6),
            Text(
              "Today's Upcoming Bookings",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF041C16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Obx(() {
                if (!Get.isRegistered<BookingsController>()) {
                  Get.put(BookingsController());
                }
                final bookingsCtrl = Get.find<BookingsController>();

                if (bookingsCtrl.isLoadingBookings.value) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF041C16),
                      ),
                    ),
                  );
                }

                final bookings = bookingsCtrl.todaysUpcomingBookings;

                if (bookings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            size: 40,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No upcoming bookings found for today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, index) {
                    final item = bookings[index];
                    final serviceStr = item.serviceName.isNotEmpty
                        ? item.serviceName
                        : 'Salon Service';
                    final timeStr = item.time.isNotEmpty
                        ? item.time
                        : (item.date.isNotEmpty ? item.date : 'Scheduled');
                    final statusStr = item.status;
                    final isConfirmed =
                        statusStr.toLowerCase() == 'confirmed' ||
                        statusStr.toLowerCase() == 'accepted';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        children: [
                          // Initials Avatar
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF041C16),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.initials,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEFE0D3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Details from Firebase
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.clientName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF041C16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  serviceStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isConfirmed
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusStr,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isConfirmed
                                              ? const Color(0xFF15803D)
                                              : const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              // View All Bookings Button
              InkWell(
                onTap: () {
                  if (Get.isRegistered<BookingsController>()) {
                    Get.find<BookingsController>().navigateToAllBookings();
                  } else {
                    controller.changeNavIndex(1);
                  }
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(
                    'VIEW ALL BOOKINGS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: const Color(0xFF041C16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom Navigation Bar Widget (Stateless)
class _BottomNavigationBarWidget extends GetView<DashboardController> {
  const _BottomNavigationBarWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isSelected: controller.selectedNavIndex.value == 0,
                  onTap: () => controller.changeNavIndex(0),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Bookings',
                  isSelected: controller.selectedNavIndex.value == 1,
                  onTap: () => controller.changeNavIndex(1),
                ),
                _NavItem(
                  icon: Icons.content_cut_outlined,
                  activeIcon: Icons.content_cut_rounded,
                  label: 'Services',
                  isSelected: controller.selectedNavIndex.value == 2,
                  onTap: () => controller.changeNavIndex(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: controller.selectedNavIndex.value == 3,
                  onTap: () => controller.changeNavIndex(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation Bar Item Widget (Stateless)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFE0D3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF5C4E3D)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF5C4E3D)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
