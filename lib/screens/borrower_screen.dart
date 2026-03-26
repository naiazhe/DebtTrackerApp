import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/borrower.dart';
import '../services/borrower_service.dart';
import '../services/user_service.dart';
import '../screens/borrower_detail_screen.dart';
import '../widgets/loading_widget.dart';

class BorrowerScreen extends StatefulWidget {
  const BorrowerScreen({Key? key}) : super(key: key);

  @override
  State<BorrowerScreen> createState() => _BorrowerScreenState();
}

class _BorrowerScreenState extends State<BorrowerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userService = context.read<UserService>();
      final borrowerService = context.read<BorrowerService>();
      final userId = userService.currentUser?.userId;
      if (userId != null) {
        await borrowerService.loadBorrowers(userId);
      }
    });
  }

  Future<void> _showBorrowerForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final contactController = TextEditingController();
    final addressController = TextEditingController();
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Borrower'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  TextFormField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Number')),
                  TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                  TextFormField(controller: referenceController, decoration: const InputDecoration(labelText: 'Reference Contact')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final userId = context.read<UserService>().currentUser?.userId;
                if (userId == null) return;
                final borrower = Borrower(
                  userId: userId,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  contactNumber: contactController.text.trim(),
                  address: addressController.text.trim(),
                  referenceContact: referenceController.text.trim(),
                  status: 'active',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                final navigator = Navigator.of(ctx);
                final borrowerService = context.read<BorrowerService>();
                await borrowerService.addBorrower(borrower);
                await borrowerService.loadBorrowers(userId);
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borrowerService = context.watch<BorrowerService>();

    if (borrowerService.isLoading) {
      return const LoadingWidget(message: 'Loading borrowers...');
    }

    return SafeArea(
      child: Stack(
        children: [
          borrowerService.borrowers.isEmpty
              ? const Center(child: Text('No borrowers yet. Tap + to add one.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: borrowerService.borrowers.length,
                  itemBuilder: (context, index) {
                    final item = borrowerService.borrowers[index];
                    return ListTile(
                      title: Text('${item.firstName} ${item.lastName}'),
                      subtitle: Text(item.contactNumber.isNotEmpty ? item.contactNumber : 'No contact'),
                      trailing: Text(item.status),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BorrowerDetailScreen(borrower: item),
                        ));
                      },
                    );
                  },
                ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showBorrowerForm(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
