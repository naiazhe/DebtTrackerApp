import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/user_service.dart';
import '../utils/message_helpers.dart';

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
      showErrorMessage(context, 'Failed to update borrower: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: AppBar(
            title: const Text('Edit Borrower', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: normalColor),
            actions: [
              TextButton(
                onPressed: () => _save(borrowerService.borrowers),
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _firstNameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF0070A8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _firstNameError,
                      ),
                      onChanged: (_) {
                        if (_firstNameError != null) {
                          setState(() => _firstNameError = null);
                        }
                      },
                    ),
                  ),
                  if (_firstNameError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(_firstNameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _lastNameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0070A8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _lastNameError,
                      ),
                      onChanged: (_) {
                        if (_lastNameError != null) {
                          setState(() => _lastNameError = null);
                        }
                      },
                    ),
                  ),
                  if (_lastNameError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(_lastNameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Contact Details'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                        hintText: 'e.g., 09123456789',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF0070A8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _contactError,
                      ),
                      onChanged: (_) {
                        if (_contactError != null) {
                          setState(() => _contactError = null);
                        }
                      },
                    ),
                  ),
                  if (_contactError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(_contactError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _addressController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        labelText: 'Address',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                        prefixIcon: const Align(
                          alignment: Alignment.topCenter,
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Icon(Icons.location_on, color: Color(0xFF0070A8)),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _addressError,
                      ),
                      onChanged: (_) {
                        if (_addressError != null) {
                          setState(() => _addressError = null);
                        }
                      },
                    ),
                  ),
                  if (_addressError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(_addressError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Reference Contact'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _referenceController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Reference Contact Number',
                        labelStyle: const TextStyle(color: Color(0xFF0070A8)),
                        hintText: 'e.g., 09123456789',
                        prefixIcon: const Icon(Icons.phone_forwarded, color: Color(0xFF0070A8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _referenceError,
                      ),
                      onChanged: (_) {
                        if (_referenceError != null) {
                          setState(() => _referenceError = null);
                        }
                      },
                    ),
                  ),
                  if (_referenceError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(_referenceError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ],
                ],
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
