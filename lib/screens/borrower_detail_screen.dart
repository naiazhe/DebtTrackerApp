import 'package:flutter/material.dart';
import '../models/borrower.dart';
import 'edit_borrower_screen.dart';

class BorrowerDetailScreen extends StatefulWidget {
  final Borrower borrower;

  const BorrowerDetailScreen({Key? key, required this.borrower}) : super(key: key);

  @override
  State<BorrowerDetailScreen> createState() => _BorrowerDetailScreenState();
}

class _BorrowerDetailScreenState extends State<BorrowerDetailScreen> {
  late Borrower _borrower;

  @override
  void initState() {
    super.initState();
    _borrower = widget.borrower;
  }

  Future<void> _openEditScreen() async {
    final updatedBorrower = await Navigator.of(context).push<Borrower>(
      MaterialPageRoute(
        builder: (_) => EditBorrowerScreen(borrower: _borrower),
      ),
    );

    if (!mounted || updatedBorrower == null) return;
    setState(() {
      _borrower = updatedBorrower;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Borrower updated successfully')),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0070A8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('Borrower Details', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0070A8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0070A8)),
            onPressed: _openEditScreen,
            tooltip: 'Edit Borrower',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF0070A8),
                      child: Text(
                        _borrower.firstName.isNotEmpty ? _borrower.firstName[0].toUpperCase() : 'B',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_borrower.firstName} ${_borrower.lastName}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${_borrower.status[0].toUpperCase()}${_borrower.status.substring(1)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoTile(icon: Icons.phone, label: 'Contact Number', value: _borrower.contactNumber),
              _buildInfoTile(icon: Icons.location_on, label: 'Address', value: _borrower.address),
              _buildInfoTile(icon: Icons.phone_forwarded, label: 'Reference Contact', value: _borrower.referenceContact),
              _buildInfoTile(icon: Icons.calendar_today, label: 'Created At', value: _formatDate(_borrower.createdAt)),
              _buildInfoTile(icon: Icons.update, label: 'Updated At', value: _formatDate(_borrower.updatedAt)),
            ],
          ),
        ),
      ),
    );
  }
}
