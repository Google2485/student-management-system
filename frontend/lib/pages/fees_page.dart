import 'package:flutter/material.dart';

import '../main.dart';
import '../services/fees_api_service.dart';

class FeesPage extends StatefulWidget {
  final bool embedded;

  const FeesPage({super.key, this.embedded = false});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  static const Color primaryColor = Color(0xFF6258E8);
  static const Color backgroundColor = Color(0xFFF7F8FC);

  String? token;

  List<dynamic> feeTypes = [];
  List<dynamic> students = [];
  List<dynamic> payments = [];

  Map<String, dynamic> summary = {};

  bool isLoading = true;
  bool isSaving = false;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      token ??= await ApiService.getToken();

      if (token == null || token!.isEmpty) {
        throw Exception('Login token not found');
      }

      final results = await Future.wait([
        FeesApiService.getFeeTypes(token!),
        FeesApiService.getPaymentHistory(token!),
        FeesApiService.getFeeSummary(token!),
        ApiService.getStudents(token!),
      ]);

      if (!mounted) return;

      setState(() {
        feeTypes = results[0] as List<dynamic>;
        payments = results[1] as List<dynamic>;
        summary = results[2] as Map<String, dynamic>;
        students = results[3] as List<dynamic>;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get totalPaid {
    final value =
        summary['total_paid'] ??
        summary['total_amount'] ??
        summary['total_collection'] ??
        0;

    return double.tryParse(value.toString()) ?? 0;
  }

  int get totalPayments {
    final value =
        summary['total_payments'] ??
        summary['total_payment'] ??
        summary['total_transactions'] ??
        payments.length;

    return int.tryParse(value.toString()) ?? 0;
  }

  int get totalFeeTypes => feeTypes.length;

  List<dynamic> get filteredPayments {
    if (searchQuery.isEmpty) return payments;

    return payments.where((payment) {
      final name = payment['student_name']?.toString() ?? '';
      final studentId = payment['student_id']?.toString() ?? '';
      final transactionId = payment['transaction_id']?.toString() ?? '';
      final feeName =
          payment['fee_name']?.toString() ??
          payment['fee_type_name']?.toString() ??
          '';

      final query = searchQuery.toLowerCase();

      return name.toLowerCase().contains(query) ||
          studentId.toLowerCase().contains(query) ||
          transactionId.toLowerCase().contains(query) ||
          feeName.toLowerCase().contains(query);
    }).toList();
  }

  String money(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return '৳${amount.toStringAsFixed(2)}';
  }

  void showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> showFeeTypeDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Fee Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Fee Name',
                  hintText: 'e.g. Semester Fee',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '৳ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());

                if (name.isEmpty || amount == null || amount <= 0) {
                  showMessage('Enter a valid name and amount', error: true);
                  return;
                }

                Navigator.pop(dialogContext);
                await createFeeType(name, amount);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
  }

  Future<void> createFeeType(String name, double amount) async {
    try {
      setState(() {
        isSaving = true;
      });

      await FeesApiService.createFeeType(
        token: token!,
        name: name,
        amount: amount,
      );

      showMessage('Fee type created successfully');
      await loadData();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> showPaymentDialog() async {
    if (students.isEmpty || feeTypes.isEmpty) {
      showMessage('Please add students and fee types first', error: true);
      return;
    }

    dynamic selectedStudent;
    dynamic selectedFeeType;

    final amountController = TextEditingController();
    final transactionController = TextEditingController();

    String paymentMethod = 'Cash';
    DateTime paymentDate = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Collect Payment'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<dynamic>(
                        value: selectedStudent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                        ),
                        items: students.map((student) {
                          return DropdownMenuItem<dynamic>(
                            value: student,
                            child: Text(
                              '${student['name']} (${student['student_id'] ?? student['id']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedStudent = value;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<dynamic>(
                        value: selectedFeeType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Fee Type',
                        ),
                        items: feeTypes.map((fee) {
                          return DropdownMenuItem<dynamic>(
                            value: fee,
                            child: Text(
                              '${fee['name']} - ${money(fee['amount'])}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          dialogSetState(() {
                            selectedFeeType = value;

                            if (value != null) {
                              amountController.text =
                                  value['amount']?.toString() ?? '';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount',
                          prefixText: '৳ ',
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                          DropdownMenuItem(
                            value: 'Mobile Banking',
                            child: Text('Mobile Banking'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            dialogSetState(() {
                              paymentMethod = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Payment Date'),
                        subtitle: Text(
                          '${paymentDate.year}-'
                          '${paymentDate.month.toString().padLeft(2, '0')}-'
                          '${paymentDate.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            dialogSetState(() {
                              paymentDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: transactionController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID (Optional)',
                          hintText: 'Enter transaction ID',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );

                          if (selectedStudent == null ||
                              selectedFeeType == null ||
                              amount == null ||
                              amount <= 0) {
                            showMessage(
                              'Please fill all required fields',
                              error: true,
                            );
                            return;
                          }

                          final studentId = int.tryParse(
                            (selectedStudent['id'] ??
                                    selectedStudent['student_id'])
                                .toString(),
                          );

                          final feeTypeId = int.tryParse(
                            selectedFeeType['id'].toString(),
                          );

                          if (studentId == null || feeTypeId == null) {
                            showMessage(
                              'Invalid student or fee type',
                              error: true,
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);

                          await collectPayment(
                            studentId: studentId,
                            feeTypeId: feeTypeId,
                            amount: amount,
                            paymentDate: paymentDate,
                            paymentMethod: paymentMethod,
                            transactionId: transactionController.text.trim(),
                          );
                        },
                  child: const Text('Submit Payment'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    transactionController.dispose();
  }

  Future<void> collectPayment({
    required int studentId,
    required int feeTypeId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      setState(() {
        isSaving = true;
      });

      final date =
          "${paymentDate.year}-"
          "${paymentDate.month.toString().padLeft(2, '0')}-"
          "${paymentDate.day.toString().padLeft(2, '0')}";

      await FeesApiService.collectPayment(
        token: token!,
        studentId: studentId,
        feeTypeId: feeTypeId,
        amount: amount,
        paymentDate: date,
        paymentMethod: paymentMethod,
        transactionId: transactionId.isEmpty ? null : transactionId,
      );

      showMessage('Payment collected successfully');
      await loadData();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEF4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25253A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF858599), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget feeTypesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fee Types',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: isSaving ? null : showFeeTypeDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Fee'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (feeTypes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(15),
              child: Center(child: Text('No fee types created yet')),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: feeTypes.map((fee) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee['name']?.toString() ?? 'Fee',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money(fee['amount']),
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget paymentHistorySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payment History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search payment...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filteredPayments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: Text('No payments found')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8F8FC),
                ),
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Fee Type')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Transaction')),
                ],
                rows: filteredPayments.map((item) {
                  final payment = Map<String, dynamic>.from(item);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          payment['student_name']?.toString() ??
                              payment['name']?.toString() ??
                              payment['student_id']?.toString() ??
                              '-',
                        ),
                      ),
                      DataCell(
                        Text(
                          payment['fee_name']?.toString() ??
                              payment['fee_type_name']?.toString() ??
                              '-',
                        ),
                      ),
                      DataCell(
                        Text(
                          money(payment['amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(payment['payment_date']?.toString() ?? '-'),
                      ),
                      DataCell(
                        Text(payment['payment_method']?.toString() ?? '-'),
                      ),
                      DataCell(
                        Text(payment['transaction_id']?.toString() ?? '-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.embedded ? Colors.transparent : backgroundColor,
      padding: const EdgeInsets.all(24),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fees & Payments',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF25253A),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage student fees and payments',
                              style: TextStyle(
                                color: Color(0xFF858599),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isSaving ? null : showPaymentDialog,
                        icon: const Icon(Icons.add_card),
                        label: const Text('Collect Payment'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      summaryCard(
                        'Total Collection',
                        money(totalPaid),
                        Icons.account_balance_wallet_outlined,
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Total Payments',
                        totalPayments.toString(),
                        Icons.receipt_long_outlined,
                        primaryColor,
                      ),
                      const SizedBox(width: 12),
                      summaryCard(
                        'Fee Types',
                        totalFeeTypes.toString(),
                        Icons.category_outlined,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  feeTypesSection(),
                  const SizedBox(height: 24),
                  paymentHistorySection(),
                ],
              ),
            ),
    );
  }
}
