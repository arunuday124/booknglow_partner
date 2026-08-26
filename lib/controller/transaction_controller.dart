import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/bookings_controller.dart';
import '../model/transaction_model.dart';

class TransactionController extends GetxController {
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  /// Filtered list based on selected tab ('All', 'Completed', 'Pending', 'Failed')
  List<TransactionModel> get filteredTransactions {
    if (selectedFilter.value == 'All') {
      return transactions;
    }
    return transactions
        .where(
          (t) =>
              t.paymentStatus.toLowerCase() ==
              selectedFilter.value.toLowerCase(),
        )
        .toList();
  }

  /// Calculates total revenue from completed transactions
  double get totalRevenue {
    return transactions
        .where(
          (t) =>
              t.paymentStatus.toLowerCase() == 'completed' ||
              t.paymentStatus.toLowerCase() == 'paid',
        )
        .fold(0.0, (acc, item) => acc + item.amount);
  }

  /// Manual scroll-down pull-to-refresh
  Future<void> refreshTransactions() async {
    await fetchTransactions(force: true);
    Get.snackbar(
      'Refreshed',
      'Transactions updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF041C16),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Updates transaction payment status in-memory without extra network re-fetch
  void updateTransactionStatusInMemory(
    String bookingId,
    String targetPaymentStatus,
  ) {
    final index = transactions.indexWhere(
      (t) => t.id == bookingId,
    );
    if (index != -1) {
      final old = transactions[index];
      String displayStatus = 'Pending';
      final lower = targetPaymentStatus.toLowerCase();
      if (lower == 'completed' || lower == 'paid') {
        displayStatus = 'Completed';
      } else if (lower == 'cancelled' ||
          lower == 'canceled' ||
          lower == 'failed') {
        displayStatus = 'Cancelled';
      }
      transactions[index] = old.copyWith(paymentStatus: displayStatus);
    }
  }

  /// Fetches transactions from Firestore for authenticated salon owner
  Future<void> fetchTransactions({bool force = false}) async {
    if (!force && transactions.isNotEmpty) {
      return; // Preserve in-memory cache without reloading
    }

    try {
      if (transactions.isEmpty || force) {
        isLoading.value = true;
      }
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String salonId = currentUser?.uid ?? '';

      if (salonId.isNotEmpty) {
        final Map<String, TransactionModel> loadedMap = {};

        // 1. Ensure BookingsController is registered and active
        if (!Get.isRegistered<BookingsController>()) {
          Get.put(BookingsController());
        }
        final bookingsCtrl = Get.find<BookingsController>();

        // 2. Reuse in-memory bookings cache (0 network calls)
        if (bookingsCtrl.allBookings.isNotEmpty) {
          for (var b in bookingsCtrl.allBookings) {
            String status = 'Pending';
            final lower = b.status.toLowerCase();
            if (lower == 'completed' || lower == 'paid') {
              status = 'Completed';
            } else if (lower == 'cancelled' || lower == 'canceled') {
              status = 'Cancelled';
            }
            loadedMap[b.id] = TransactionModel(
              id: b.id,
              userName: b.clientName.isNotEmpty ? b.clientName : 'Guest User',
              paymentMethod:
                  b.paymentMethod.isNotEmpty ? b.paymentMethod : 'UPI',
              paymentStatus: status,
              amount: b.totalPrice,
              date: '${b.time} • ${b.date}',
              serviceName: b.serviceName,
            );
          }
        }

        // 3. Query transactions collection for current salon (only for extra transaction-specific records)
        final QuerySnapshot txnQuery = await FirebaseFirestore.instance
            .collection('transactions')
            .where('salonId', isEqualTo: salonId)
            .get();

        for (var doc in txnQuery.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final String idKey = (data['bookingId'] ?? doc.id).toString();
          loadedMap[idKey] = TransactionModel.fromMap(data, idKey);
        }

        transactions.assignAll(loadedMap.values.toList());
      } else {
        transactions.clear();
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
}
