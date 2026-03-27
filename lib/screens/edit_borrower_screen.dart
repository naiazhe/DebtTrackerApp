import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/user_service.dart';

class EditBorrowerScreen extends StatefulWidget {
  final Borrower borrower;

  const EditBorrowerScreen({Key? key, required this.borrower}) : super(key: key);

  @override
  State<EditBorrowerScreen> createState() => _EditBorrowerScreenState();
}

class _EditBorrowerScreenState extends State<EditBorrowerScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();

  static const Color normalColor = Color(0xFF0070A8);

  String? _firstNameError;
  String? _lastNameError;
  String? _contactError;
  String? _addressError;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.borrower.firstName;
    _lastNameController.text = widget.borrower.lastName;
    _contactController.text = widget.borrower.contactNumber;
    _addressController.text = widget.borrower.address;
    _referenceController.text = widget.borrower.referenceContact;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  bool _isValidPhoneNumber(String phone) {
    final trimmed = phone.trim();
    return RegExp(r'^\+63\d{10}$').hasMatch(trimmed) || RegExp(r'^09\d{9}$').hasMatch(trimmed);
  }

  String _normalizePhoneNumber(String phone) {
    final trimmed = phone.trim();
    if (trimmed.startsWith('+63') && trimmed.length == 13) {
      return '0${trimmed.substring(3)}';
    }
    return trimmed;
  }

  bool _isSamePhoneNumber(String a, String b) {
    return _normalizePhoneNumber(a) == _normalizePhoneNumber(b);
  }

  bool _isDuplicateName(List<Borrower> borrowers) {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.toLowerCase();
    return borrowers.any((b) {
      if (b.borrowerId == widget.borrower.borrowerId) return false;
      return '${b.firstName} ${b.lastName}'.toLowerCase() == fullName;
    });
  }

  bool _isContactNumberUnique(List<Borrower> borrowers) {
    final normalized = _normalizePhoneNumber(_contactController.text.trim());
    return !borrowers.any((b) {
      if (b.borrowerId == widget.borrower.borrowerId) return false;
      return _normalizePhoneNumber(b.contactNumber) == normalized;
    });
  }

  Future<void> _save(List<Borrower> existingBorrowers) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _firstNameError = _firstNameController.text.trim().isEmpty ? 'First Name is required' : null;
      _lastNameError = _lastNameController.text.trim().isEmpty ? 'Last Name is required' : null;

      if (_lastNameError == null && _firstNameError == null && _isDuplicateName(existingBorrowers)) {
        _lastNameError = 'Borrower with this name already exists';
      }

      final contactValue = _contactController.text.trim();
      if (contactValue.isEmpty) {
        _contactError = 'Contact Number is required';
      } else if (!_isValidPhoneNumber(contactValue)) {
        _contactError = 'Invalid mobile number. Use +63 or 09 format (e.g., 09123456789)';
      } else if (!_isContactNumberUnique(existingBorrowers)) {
        _contactError = 'Contact Number already exists';
      } else if (_isSamePhoneNumber(contactValue, _referenceController.text.trim())) {
        _contactError = 'Contact Number and Reference Contact Number must not be the same';
      } else {
        _contactError = null;
      }

      _addressError = _addressController.text.trim().isEmpty ? 'Address is required' : null;

      final referenceValue = _referenceController.text.trim();
      if (referenceValue.isEmpty) {
        _referenceError = 'Reference Contact Number is required';
      } else if (!_isValidPhoneNumber(referenceValue)) {
        _referenceError = 'Invalid mobile number. Use +63 or 09 format (e.g., 09123456789)';
      } else if (_isSamePhoneNumber(referenceValue, _contactController.text.trim())) {
        _referenceError = 'Contact Number and Reference Contact Number must not be the same';
      } else {
        _referenceError = null;
      }
    });

    if (_firstNameError != null || _lastNameError != null || _contactError != null || _addressError != null || _referenceError != null) {
      return;
    }

    try {
      final borrowerService = context.read<BorrowerService>();
      final userId = context.read<UserService>().currentUser?.userId ?? widget.borrower.userId;

      final updatedBorrower = Borrower(
        borrowerId: widget.borrower.borrowerId,
        userId: widget.borrower.userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        referenceContact: _referenceController.text.trim(),
        status: widget.borrower.status,
        createdAt: widget.borrower.createdAt,
        updatedAt: DateTime.now(),
      );

      await borrowerService.updateBorrower(updatedBorrower);
      await borrowerService.loadBorrowers(userId);

      if (!mounted) return;
      Navigator.of(context).pop(updatedBorrower);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update borrower: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        title: const Text('Edit Borrower', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: normalColor),
        actions: [
          TextButton(
            onPressed: () => _save(borrowerService.borrowers),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information'),
              _buildInputCard(
                icon: Icons.person,
                error: _firstNameError,
                child: TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) {
                    if (_firstNameError != null) {
                      setState(() => _firstNameError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                icon: Icons.person_outline,
                error: _lastNameError,
                child: TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) {
                    if (_lastNameError != null) {
                      setState(() => _lastNameError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Contact Details'),
              _buildInputCard(
                icon: Icons.phone,
                error: _contactError,
                child: TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    hintText: 'e.g., 09123456789',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) {
                    if (_contactError != null) {
                      setState(() => _contactError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildInputCard(
                icon: Icons.location_on,
                error: _addressError,
                child: TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) {
                    if (_addressError != null) {
                      setState(() => _addressError = null);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Reference Contact'),
              _buildInputCard(
                icon: Icons.phone_forwarded,
                error: _referenceError,
                child: TextField(
                  controller: _referenceController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Reference Contact Number',
                    hintText: 'e.g., 09123456789',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) {
                    if (_referenceError != null) {
                      setState(() => _referenceError = null);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00273B),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required Widget child,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Icon(icon, color: normalColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
