import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controller/transaction_controller.dart';
import '../model/transaction_model.dart';

/// Transaction Details View built using GetView (StatelessWidget) and GetX
class TransactionDetailsView extends GetView<TransactionController> {
  const TransactionDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject permanent TransactionController so it persists across page opens/closes
    if (!Get.isRegistered<TransactionController>()) {
      Get.put(TransactionController(), permanent: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF041C16), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Transaction Details',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF041C16),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF041C16),
          backgroundColor: Colors.white,
          onRefresh: controller.refreshTransactions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SummaryHeaderCard(),
                    SizedBox(height: 20),
                    _FilterTabsRow(),
                    SizedBox(height: 20),
                    _TransactionListSection(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Summary Metric Card Header (Stateless)
class _SummaryHeaderCard extends GetView<TransactionController> {
  const _SummaryHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF041C16),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A041C16),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL REVENUE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFFB0C4BE),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE0D3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Partner Earnings',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C4E3D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Text(
              '₹${controller.totalRevenue.toStringAsFixed(0)}',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1E463C), height: 1),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniMetricItem(
                  label: 'Transactions',
                  value: '${controller.transactions.length}',
                ),
                _MiniMetricItem(
                  label: 'Completed',
                  value: '${controller.transactions.where((t) => t.paymentStatus.toLowerCase() == 'completed' || t.paymentStatus.toLowerCase() == 'paid').length}',
                ),
                _MiniMetricItem(
                  label: 'Pending',
                  value: '${controller.transactions.where((t) => t.paymentStatus.toLowerCase() == 'pending').length}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini Metric Item (Stateless)
class _MiniMetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFFB0C4BE),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Filter Tabs Row (Stateless)
class _FilterTabsRow extends GetView<TransactionController> {
  const _FilterTabsRow();

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Completed', 'Pending', 'Failed'];

    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((filter) {
            final isSelected = controller.selectedFilter.value == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => controller.setFilter(filter),
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF041C16),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF041C16) : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Transaction List Section (Stateless)
class _TransactionListSection extends GetView<TransactionController> {
  const _TransactionListSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Color(0xFF041C16)),
          ),
        );
      }

      final list = controller.filteredTransactions;

      if (list.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text(
                'No Transactions Found',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'There are no transactions matching the selected filter.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final transaction = list[index];
          return _TransactionCard(transaction: transaction);
        },
      );
    });
  }
}

/// Single Transaction Card Item Widget (Stateless)
class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final statusColorData = _getStatusColors(transaction.paymentStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: User Name, ID & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Name & ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.userName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${transaction.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Text(
                '₹${transaction.amount.toStringAsFixed(0)}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF041C16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment Method & Date Row
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 15, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                'Method: ${transaction.paymentMethod}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // Bottom Row: Date & Payment Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction.date,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              // Payment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColorData.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.paymentStatus.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColorData.textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StatusColorData _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return _StatusColorData(
          bgColor: const Color(0xFFE6F4EA),
          textColor: const Color(0xFF137333),
        );
      case 'pending':
        return _StatusColorData(
          bgColor: const Color(0xFFFEF7E0),
          textColor: const Color(0xFFB06000),
        );
      case 'failed':
        return _StatusColorData(
          bgColor: const Color(0xFFFCE8E6),
          textColor: const Color(0xFFC5221F),
        );
      default:
        return _StatusColorData(
          bgColor: const Color(0xFFF3F4F6),
          textColor: const Color(0xFF4B5563),
        );
    }
  }
}

class _StatusColorData {
  final Color bgColor;
  final Color textColor;
  _StatusColorData({required this.bgColor, required this.textColor});
}
