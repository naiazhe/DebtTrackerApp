# Debt Tracker App

A Flutter mobile application to manage and track debts, loans, payments, and transactions with offline SQLite persistence.

## Features
- User account (seeded with default user)
- Borrower management (create, view detail)
- Loan management (flat/fixed interest, total payable, remaining balance, status)
- Payment registration and transaction logging
- Dashboard with summary metrics
- Bottom navigation: Home, Borrower, Loan, Transaction, Setting
- SQLite storage via sqflite and clean architecture (models, services, database, screens)

## Getting Started
1. clone repository
2. `cd appdev_debttrack`
3. `flutter pub get`
4. `flutter run`

## Package Dependencies
- sqflite
- path
- provider

## Project Structure
- `lib/main.dart` - app entry, providers, bottom navigation
- `lib/models` - data objects and conversions
- `lib/database` - SQLite helper and CRUD
- `lib/services` - business logic and data layer
- `lib/screens` - UI screens
- `lib/widgets` - reusable widgets

## Notes
- This is a functional skeleton ready for Figma UI updates.
- Input validation and error handling are included.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
