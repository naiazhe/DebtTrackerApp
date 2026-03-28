import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/user_service.dart';
import '../screens/borrower_detail_screen.dart';
import '../utils/message_helpers.dart';

class AddBorrowerScreen extends StatefulWidget {
  const AddBorrowerScreen({Key? key}) : super(key: key);

  @override
  State<AddBorrowerScreen> createState() => _AddBorrowerScreenState();
}

class _AddBorrowerScreenState extends State<AddBorrowerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();
  final _contactFocusNode = FocusNode();
  final _referenceFocusNode = FocusNode();

  static const Color normalColor = Color(0xFF0070A8);

  String? _firstNameError;
  String? _lastNameError;
  String? _contactError;
  String? _addressError;
  String? _referenceError;
  bool _hasAttemptedSubmit = false;

  void _handleContactFocusChange() {
    if (!mounted || _contactFocusNode.hasFocus) return;
    final borrowers = context.read<BorrowerService>().borrowers;
    setState(() {
      _contactError = _validateContactNumber(
        _contactController.text,
        borrowers,
        showRequired: _hasAttemptedSubmit,
      );
    });
  }

  void _handleReferenceFocusChange() {
    if (!mounted || _referenceFocusNode.hasFocus) return;
    final borrowers = context.read<BorrowerService>().borrowers;
    setState(() {
      _referenceError = _validateReferenceContact(
        _referenceController.text,
        showRequired: _hasAttemptedSubmit,
      );
      _contactError = _validateContactNumber(
        _contactController.text,
        borrowers,
        showRequired: _hasAttemptedSubmit,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _contactFocusNode.addListener(_handleContactFocusChange);
    _referenceFocusNode.addListener(_handleReferenceFocusChange);
  }

  @override
  void dispose() {
    _contactFocusNode.removeListener(_handleContactFocusChange);
    _referenceFocusNode.removeListener(_handleReferenceFocusChange);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    _contactFocusNode.dispose();
    _referenceFocusNode.dispose();
    super.dispose();
  }

  bool _isValidPhoneNumber(String phone) {
    phone = phone.trim();
    // Format 1: +63XXXXXXXXXX (starts with +63, followed by 10 digits)
    if (RegExp(r'^\+63\d{10}$').hasMatch(phone)) {
      return true;
    }
    // Format 2: 09XXXXXXXXX (starts with 09, total 11 digits)
    if (RegExp(r'^09\d{9}$').hasMatch(phone)) {
      return true;
    }
    return false;
  }

  bool _isDuplicateBorrower(String firstName, String lastName, List<Borrower> existingBorrowers) {
    final newName = '${firstName.trim()} ${lastName.trim()}'.toLowerCase();
    return existingBorrowers.any((b) => '${b.firstName} ${b.lastName}'.toLowerCase() == newName);
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

  bool _isContactNumberUnique(String contactNumber, List<Borrower> existingBorrowers) {
    final normalizedInput = _normalizePhoneNumber(contactNumber);
    return !existingBorrowers.any((borrower) => _normalizePhoneNumber(borrower.contactNumber) == normalizedInput);
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'First Name is required';
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Last Name is required';
    return null;
  }

  String? _validateDuplicateBorrower(List<Borrower> existingBorrowers) {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    if (_validateFirstName(firstName) != null || _validateLastName(lastName) != null) {
      return null;
    }
    if (_isDuplicateBorrower(firstName, lastName, existingBorrowers)) {
      return 'Borrower with this name already exists';
    }
    return null;
  }

  String? _validateContactNumber(
    String? value,
    List<Borrower> existingBorrowers, {
    bool showRequired = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return showRequired ? 'Contact Number is required' : null;
    }
    if (!_isValidPhoneNumber(value)) return 'Invalid mobile number. Use +63 or 09 format (e.g., 09123456789)';
    if (!_isContactNumberUnique(value, existingBorrowers)) return 'Contact Number already exists';
    if (_referenceController.text.trim().isNotEmpty && _isSamePhoneNumber(value, _referenceController.text)) {
      return 'Contact Number and Reference Contact Number must not be the same';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    return null;
  }

  String? _validateReferenceContact(String? value, {bool showRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return showRequired ? 'Reference Contact Number is required' : null;
    }
    if (!_isValidPhoneNumber(value)) return 'Invalid mobile number. Use +63 or 09 format (e.g., 09123456789)';
    if (_contactController.text.trim().isNotEmpty && _isSamePhoneNumber(value, _contactController.text)) {
      return 'Contact Number and Reference Contact Number must not be the same';
    }
    return null;
  }

  void _updateNameErrors(List<Borrower> existingBorrowers, {required bool isLastNameChanged}) {
    final firstNameError = _validateFirstName(_firstNameController.text);
    String? lastNameError;
    final trimmedLastName = _lastNameController.text.trim();

    if (isLastNameChanged || trimmedLastName.isNotEmpty) {
      lastNameError = _validateLastName(_lastNameController.text);
    }

    final duplicateError = _validateDuplicateBorrower(existingBorrowers);

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError ?? duplicateError;
    });
  }

  Future<void> _submit(List<Borrower> existingBorrowers) async {
    setState(() {
      _hasAttemptedSubmit = true;
      _firstNameError = _validateFirstName(_firstNameController.text);
      _lastNameError = _validateLastName(_lastNameController.text) ?? _validateDuplicateBorrower(existingBorrowers);
      _contactError = _validateContactNumber(
        _contactController.text,
        existingBorrowers,
        showRequired: true,
      );
      _addressError = _validateAddress(_addressController.text);
      _referenceError = _validateReferenceContact(
        _referenceController.text,
        showRequired: true,
      );
    });

    if (_firstNameError != null || _lastNameError != null || _contactError != null || _addressError != null || _referenceError != null) {
      return;
    }

    try {
      final userService = context.read<UserService>();
      final borrowerService = context.read<BorrowerService>();
      final userId = userService.currentUser?.userId;

      if (userId == null) {
        throw Exception('User not found');
      }

      final borrower = Borrower(
        userId: userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        referenceContact: _referenceController.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newBorrowerId = await borrowerService.addBorrower(borrower);
      await borrowerService.loadBorrowers(userId);

      final createdBorrower = Borrower(
        borrowerId: newBorrowerId,
        userId: borrower.userId,
        firstName: borrower.firstName,
        lastName: borrower.lastName,
        contactNumber: borrower.contactNumber,
        address: borrower.address,
        referenceContact: borrower.referenceContact,
        status: borrower.status,
        createdAt: borrower.createdAt,
        updatedAt: borrower.updatedAt,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BorrowerDetailScreen(borrower: createdBorrower)),
      );
    } catch (e) {
      if (mounted) {
        showErrorMessage(context, 'Failed to save borrower: $e');
      }
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
            title: const Text('Add Borrower', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            iconTheme: const IconThemeData(color: normalColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            actions: [
              TextButton(
                onPressed: () => _submit(borrowerService.borrowers),
                child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Personal Information'),
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
                  child: TextFormField(
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
                    onChanged: (_) => _updateNameErrors(borrowerService.borrowers, isLastNameChanged: false),
                  ),
                ),
                const SizedBox(height: 12),
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
                  child: TextFormField(
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
                    onChanged: (_) => _updateNameErrors(borrowerService.borrowers, isLastNameChanged: true),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Contact Details'),
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
                  child: TextFormField(
                    controller: _contactController,
                    focusNode: _contactFocusNode,
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
                        setState(() {
                          _contactError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
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
                  child: TextFormField(
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
                    onChanged: (value) {
                      setState(() {
                        _addressError = _validateAddress(value);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Reference Contact'),
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
                  child: TextFormField(
                    controller: _referenceController,
                    focusNode: _referenceFocusNode,
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
                        setState(() {
                          _referenceError = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
            children: [
              Icon(icon, color: normalColor, size: 20),
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
        ]
      ],
    );
  }
}
