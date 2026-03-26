import 'package:flutter/material.dart';
import '../models/borrower.dart';

class BorrowerDetailScreen extends StatelessWidget {
  final Borrower borrower;

  const BorrowerDetailScreen({Key? key, required this.borrower}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrower Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${borrower.firstName} ${borrower.lastName}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Contact: ${borrower.contactNumber}'),
            Text('Address: ${borrower.address}'),
            Text('Reference: ${borrower.referenceContact}'),
            const SizedBox(height: 16),
            Text('Status: ${borrower.status}'),
            Text('Created at: ${borrower.createdAt.toLocal()}'),
            Text('Updated at: ${borrower.updatedAt.toLocal()}'),
          ],
        ),
      ),
    );
  }
}
