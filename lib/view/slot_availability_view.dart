import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/slot_controller.dart';
import '../model/time_slot_model.dart';
import '../service/slot_service.dart';

/// Full-screen view showing real-time slot availability for the salon.
/// Partners can see which time slots are locked/booked and which are free for any date.
/// Supports pull-to-refresh (scroll-down reload) to keep network calls minimal.
class SlotAvailabilityView extends StatelessWidget {
  const SlotAvailabilityView({super.key});

  @override
  Widget build(BuildContext context) {
    // Register / find SlotController
    if (!Get.isRegistered<SlotController>()) {
      Get.put(SlotController());
    }
    final controller = Get.find<SlotController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF041C16),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Slot Availability',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: false,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF041C16),
            ),
            onPressed: controller.refreshSlots,
            tooltip: 'Refresh slots',
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
        child: RefreshIndicator(
          color: const Color(0xFF041C16),
          backgroundColor: Colors.white,
          displacement: 20,
          onRefresh: controller.refreshSlots,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: const [
              // ── Date Selector ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _DateSelectorSection()),
              // ── Operating Hours Banner ────────────────────────────────────
              SliverToBoxAdapter(child: _OperatingHoursBanner()),
              // ── Service Duration Filter ───────────────────────────────────
              SliverToBoxAdapter(child: _DurationSelectorSection()),
              // ── Stats Bar ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _StatsBar()),
              // ── Slot Grid ─────────────────────────────────────────────────
              _SlotGridSliver(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date Selector ─────────────────────────────────────────────────────────────

class _DateSelectorSection extends GetView<SlotController> {
  const _DateSelectorSection();

  @override
  Widget build(BuildContext context) {
    // Build a list of the next 14 days starting from today
    final today = DateTime.now();
    final dates = List.generate(
      14,
      (i) => today.add(Duration(days: i)),
    );

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      color: const Color(0xFFF8F9F8),
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Obx(
          () => Row(
            children: dates.map((date) {
              final bool isSelected =
                  date.year == controller.selectedDate.value.year &&
                  date.month == controller.selectedDate.value.month &&
                  date.day == controller.selectedDate.value.day;
              final bool isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () => controller.selectDate(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 54,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0A2B23)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0A2B23)
                            : isToday
                                ? const Color(0xFF5C4E3D)
                                : const Color(0xFFE5E7EB),
                        width: isToday && !isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                color: Color(0x330A2B23),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          days[date.weekday - 1],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFB0C4BE)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF041C16),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          months[date.month - 1],
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFB0C4BE)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
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

// ── Operating Hours Banner ────────────────────────────────────────────────────

class _OperatingHoursBanner extends GetView<SlotController> {
  const _OperatingHoursBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF5E4D7),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFFE8C9B0), width: 1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 16,
                color: Color(0xFF92400E),
              ),
              const SizedBox(width: 8),
              Text(
                'Open ${controller.openingLabel.value} – ${controller.closingLabel.value}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C2D12),
                ),
              ),
              const Spacer(),
              Text(
                '30 min intervals',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E),
                ),
              ),
            ],
          ),
        ));
  }
}

// ── Duration Selector Section ─────────────────────────────────────────────────

class _DurationSelectorSection extends GetView<SlotController> {
  const _DurationSelectorSection();

  static const List<int> _durations = [30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                size: 14,
                color: Color(0xFF4B5563),
              ),
              const SizedBox(width: 6),
              Text(
                'Test Service Duration Overlap:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Obx(
              () => Row(
                children: _durations.map((duration) {
                  final bool isSelected =
                      controller.selectedDurationMinutes.value == duration;
                  final String label =
                      duration == 30 ? '30 min (1 slot)' : SlotService.formatDurationDisplay(duration);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => controller.selectDuration(duration),
                      selectedColor: const Color(0xFF041C16),
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF041C16)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends GetView<SlotController> {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const SizedBox.shrink();
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _StatChip(
                label: '${controller.availableCount} Available',
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                textColor: const Color(0xFF15803D),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: '${controller.bookedCount} Locked',
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                textColor: const Color(0xFF991B1B),
                icon: Icons.lock_outline_rounded,
              ),
              if (controller.conflictCount > 0) ...[
                const SizedBox(width: 8),
                _StatChip(
                  label: '${controller.conflictCount} Overlapping Conflict',
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  textColor: const Color(0xFFB45309),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slot Grid Sliver ───────────────────────────────────────────────────────────

class _SlotGridSliver extends GetView<SlotController> {
  const _SlotGridSliver();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(64.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF041C16),
                strokeWidth: 2.5,
              ),
            ),
          ),
        );
      }

      final slots = controller.slots;

      if (slots.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    size: 56,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No slots available',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Operating hours may not be configured.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final slot = slots[index];
              return _SlotTile(slot: slot);
            },
            childCount: slots.length,
          ),
        ),
      );
    });
  }
}

// ── Individual Slot Tile ───────────────────────────────────────────────────────

class _SlotTile extends GetView<SlotController> {
  final TimeSlotModel slot;

  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final bool isDirectlyBooked = slot.isBooked;
    final bool isConflict = !isDirectlyBooked && !slot.isAvailableForDuration;
    final bool isAvailable = slot.isSelectable;

    final Color bgColor = isDirectlyBooked
        ? const Color(0xFFF9FAFB)
        : (isConflict
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFF0FDF4));

    final Color borderColor = isDirectlyBooked
        ? const Color(0xFFE5E7EB)
        : (isConflict
            ? const Color(0xFFFCD34D)
            : const Color(0xFF86EFAC));

    final Color textColor = isDirectlyBooked
        ? const Color(0xFF9CA3AF)
        : (isConflict
            ? const Color(0xFFB45309)
            : const Color(0xFF15803D));

    final String statusText = isDirectlyBooked
        ? 'Locked'
        : (isConflict
            ? (slot.isOverlappingLocked ? 'Overlaps' : 'No Time')
            : 'Available');

    final IconData icon = isDirectlyBooked
        ? Icons.lock_rounded
        : (isConflict
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded);

    return InkWell(
      onTap: () {
        final durationLabel =
            SlotService.formatDurationDisplay(controller.selectedDurationMinutes.value);
        if (isDirectlyBooked) {
          Get.snackbar(
            'Slot Locked',
            '${slot.label} is directly booked and locked.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF991B1B),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: const Icon(Icons.lock_outline, color: Colors.white),
          );
        } else if (isConflict) {
          Get.snackbar(
            'Slot Unavailable for $durationLabel',
            '${slot.label} cannot be selected because ${slot.conflictReason ?? 'a continuous slot is locked'}. Continuous slots are required.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFB45309),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          );
        } else {
          final reqSlots =
              SlotService.getRequiredSlotsCount(controller.selectedDurationMinutes.value);
          Get.snackbar(
            'Slot Available',
            '${slot.label} is fully available for $durationLabel ($reqSlots continuous slots).',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF15803D),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isDirectlyBooked ? 1 : 1.5,
          ),
          boxShadow: isAvailable
              ? const [
                  BoxShadow(
                    color: Color(0x1422C55E),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: textColor,
            ),
            const SizedBox(height: 3),
            Text(
              slot.label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

