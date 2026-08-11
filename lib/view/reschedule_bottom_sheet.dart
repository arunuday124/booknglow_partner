import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/bookings_controller.dart';
import '../controller/profile_controller.dart';
import '../model/booking_model.dart';
import '../model/time_slot_model.dart';
import '../service/slot_service.dart';

/// Interactive Bottom Sheet allowing the salon partner to choose a dynamic
/// available date and time slot to reschedule an appointment.
class RescheduleBottomSheet extends StatefulWidget {
  final BookingModel booking;

  const RescheduleBottomSheet({
    super.key,
    required this.booking,
  });

  @override
  State<RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<RescheduleBottomSheet> {
  late DateTime _selectedDate;
  String? _selectedSlotLabel;
  bool _isLoadingSlots = true;
  bool _isSubmitting = false;

  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);
  String _openingLabel = '9:00 AM';
  String _closingLabel = '9:00 PM';

  List<TimeSlotModel> _slots = [];

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final List<String> _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _initInitialDate();
    _loadSalonHoursAndSlots();
  }

  void _initInitialDate() {
    final now = DateTime.now();
    // Default to today, or if booking has a valid future date, try parsing it
    DateTime initial = DateTime(now.year, now.month, now.day);
    if (widget.booking.date.isNotEmpty) {
      final parsed = _parseBookingDate(widget.booking.date);
      if (parsed != null && !parsed.isBefore(initial)) {
        initial = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    _selectedDate = initial;
  }

  DateTime? _parseBookingDate(String raw) {
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
    } catch (_) {}
    return null;
  }

  Future<void> _loadSalonHoursAndSlots() async {
    setState(() => _isLoadingSlots = true);

    // 1. Try to load from ProfileController memory cache (0 network calls)
    if (Get.isRegistered<ProfileController>()) {
      final profile = Get.find<ProfileController>();
      if (profile.openingTime.value != null &&
          profile.closingTime.value != null) {
        _openingTime = profile.openingTime.value!;
        _closingTime = profile.closingTime.value!;
        _openingLabel = profile.formatTime(_openingTime);
        _closingLabel = profile.formatTime(_closingTime);
        await _fetchSlotsForSelectedDate();
        return;
      }
    }

    final bookingsCtrl = Get.find<BookingsController>();
    final salonId = widget.booking.salonId.isNotEmpty
        ? widget.booking.salonId
        : bookingsCtrl.currentSalonId;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('salons')
          .doc(salonId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final openStr = (data['openingHours'] ?? '9:00 AM').toString();
        final closeStr = (data['closingHours'] ?? '9:00 PM').toString();
        _openingLabel = openStr;
        _closingLabel = closeStr;

        final parsedOpen = _parseTimeOfDay(openStr);
        final parsedClose = _parseTimeOfDay(closeStr);
        if (parsedOpen != null) _openingTime = parsedOpen;
        if (parsedClose != null) _closingTime = parsedClose;
      }
    } catch (e) {
      debugPrint('Error loading salon hours for reschedule: $e');
    }

    await _fetchSlotsForSelectedDate();
  }

  Future<void> _fetchSlotsForSelectedDate() async {
    setState(() => _isLoadingSlots = true);
    final bookingsCtrl = Get.find<BookingsController>();
    final salonId = widget.booking.salonId.isNotEmpty
        ? widget.booking.salonId
        : bookingsCtrl.currentSalonId;

    final dateStr = _formatDateForFirestore(_selectedDate);

    try {
      Set<String> bookedTimes;

      // Check if BookingsController has bookings in memory (0 network calls)
      if (bookingsCtrl.allBookings.isNotEmpty) {
        bookedTimes = SlotService.extractBookedTimesFromModels(
          bookingsCtrl.allBookings,
          dateStr,
          excludeBookingId: widget.booking.id,
        );
      } else {
        bookedTimes = await SlotService.fetchBookedSlots(
          salonId,
          dateStr,
          excludeBookingId: widget.booking.id,
        );
      }

      final generated = SlotService.generateSlots(
        _openingTime,
        _closingTime,
        intervalMinutes: 30,
      );

      final merged = SlotService.mergeSlots(generated, bookedTimes);
      final upcomingOnly =
          SlotService.filterUpcomingSlots(merged, _selectedDate);

      setState(() {
        _slots = upcomingOnly;
        _isLoadingSlots = false;
        // If current selectedSlotLabel is no longer available on this date, reset it
        if (_selectedSlotLabel != null) {
          final found = upcomingOnly.firstWhereOrNull(
            (s) => s.label == _selectedSlotLabel && !s.isBooked,
          );
          if (found == null) {
            _selectedSlotLabel = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching slots for reschedule: $e');
      setState(() => _isLoadingSlots = false);
    }
  }

  TimeOfDay? _parseTimeOfDay(String raw) {
    try {
      final clean = raw.trim().toUpperCase();
      final isPm = clean.contains('PM');
      final isAm = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digits.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return null;
      int hour = int.parse(parts[0]);
      final int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatDateForFirestore(DateTime dt) {
    return '${_monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDateDisplay(DateTime dt) {
    return '${_dayNames[dt.weekday - 1]}, ${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';
  }

  bool _isDateToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Future<void> _pickDateFromCalendar() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 90));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF041C16),
              onPrimary: Colors.white,
              onSurface: Color(0xFF041C16),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _selectedSlotLabel = null;
      });
      _fetchSlotsForSelectedDate();
    }
  }

  Future<void> _handleConfirmReschedule() async {
    if (_selectedSlotLabel == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final bookingsCtrl = Get.find<BookingsController>();
    final formattedDate = _formatDateForFirestore(_selectedDate);

    await bookingsCtrl.rescheduleBookingWithSlot(
      widget.booking,
      _selectedSlotLabel!,
      formattedDate,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final datesList = List.generate(
      30,
      (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i)),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Drag Handle ───────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header: Title & Close Button ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reschedule Appointment',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF041C16),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a new date and available time slot',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Current Booking Info Card ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF041C16),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.booking.initials,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEFE0D3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.clientName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            widget.booking.serviceName.isNotEmpty
                                ? widget.booking.serviceName
                                : 'Salon Service',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Current: ${widget.booking.time}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Scrollable Body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Select Date Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Date',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          InkWell(
                            onTap: _pickDateFromCalendar,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Color(0xFF041C16),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Custom Date',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF041C16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal 30-day Date Selector
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: datesList.length,
                        itemBuilder: (context, index) {
                          final date = datesList[index];
                          final isSelected = date.year == _selectedDate.year &&
                              date.month == _selectedDate.month &&
                              date.day == _selectedDate.day;
                          final isToday = date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;

                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedSlotLabel = null;
                                });
                                _fetchSlotsForSelectedDate();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF041C16)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF041C16)
                                        : isToday
                                            ? const Color(0xFF041C16)
                                            : const Color(0xFFE5E7EB),
                                    width: isSelected || isToday ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x33041C16),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _dayNames[date.weekday - 1],
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFFB0C4BE)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
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
                                    const SizedBox(height: 1),
                                    Text(
                                      _monthNames[date.month - 1],
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
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Operating Hours & Slots Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Text(
                            'Available Slots',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E4D7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_openingLabel - $_closingLabel',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C2D12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Slots Grid / Loading State
                    if (_isLoadingSlots)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF041C16),
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.event_busy_outlined,
                                size: 40,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDateToday(_selectedDate)
                                    ? 'No upcoming slots remaining today'
                                    : 'No slots available for this date',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isDateToday(_selectedDate)
                                    ? 'All slots for today have passed. Please choose a future date above.'
                                    : 'Please choose another date above.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.3,
                          ),
                          itemCount: _slots.length,
                          itemBuilder: (context, index) {
                            final slot = _slots[index];
                            final bool isBooked = slot.isBooked;
                            final bool isSelected =
                                _selectedSlotLabel == slot.label;

                            return GestureDetector(
                              onTap: isBooked
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedSlotLabel = slot.label;
                                      });
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF041C16)
                                      : isBooked
                                          ? const Color(0xFFF3F4F6)
                                          : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF041C16)
                                        : isBooked
                                            ? const Color(0xFFE5E7EB)
                                            : const Color(0xFF86EFAC),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x33041C16),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : isBooked
                                              ? Icons.lock_rounded
                                              : Icons.access_time_rounded,
                                      size: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : isBooked
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF16A34A),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      slot.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : isBooked
                                                ? const Color(0xFF9CA3AF)
                                                : const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Bottom Action Panel ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                children: [
                  // Selected Slot Summary
                  if (_selectedSlotLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New Time: $_selectedSlotLabel  •  ${_formatDateDisplay(_selectedDate)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedSlotLabel != null && !_isSubmitting
                          ? _handleConfirmReschedule
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF041C16),
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _selectedSlotLabel != null
                                  ? 'CONFIRM RESCHEDULE'
                                  : 'SELECT A TIME SLOT',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: _selectedSlotLabel != null
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
