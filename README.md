# Cartify

Cartify is an offline-first Android shopping application built with Flutter.
It combines a Firestore-backed product catalogue with Hive-based local
persistence for shopping and account data.

> **Project status:** Academic prototype for CSE3005 Software Engineering.

## Overview

Cartify is designed for customers who need a lightweight shopping experience
even when connectivity is limited. The product catalogue is fetched from
Cloud Firestore and cached locally in Hive. Local shopping data remains
available across app restarts.

The project covers:

- Customer registration, login and local session persistence
- Product browsing, category filtering and local search
- Product details, reviews and ratings
- Cart, wishlist and saved addresses
- Coupon-enabled mock checkout
- Local order creation, order history and reorder
- Profile editing, password change and account deletion
- Light and dark themes
- Administrator dashboard and store-management tools

Cartify is a **single-store** application. Real payment gateways, push
notifications, multi-vendor support and geo-fencing are outside the current
scope.

## Features

### Customer features

- Email/password authentication through Firebase, with local offline support
- SHA-256 hashing for locally stored prototype credentials
- Product catalogue loaded from Firestore and cached in Hive
- Category filtering and search by product name, description and category
- Product details with stock information and reviews
- Add, remove and update cart quantities
- Wishlist management
- Address book with default-address selection
- Coupon application during checkout
- Mock/local checkout and order confirmation
- Order history, order details and reorder
- Profile editing and password change
- Offline password recovery using a security question
- Persistent light/dark theme selection

### Administrator features

The administrator panel contains seven sections:

1. Dashboard
2. Products
3. Orders
4. Users
5. Inventory
6. Reviews
7. Coupons

Product CRUD operations use Cloud Firestore. Local order and account-related
data is handled through Hive.

## Technology stack

| Area | Technology |
|---|---|
| Platform | Android 6.0+ |
| UI | Flutter and Dart |
| State management | Provider |
| Authentication | Firebase Authentication |
| Remote catalogue | Cloud Firestore |
| Local persistence | Hive and Hive Flutter |
| Password hashing | `crypto` package with SHA-256 |
| IDs | `uuid` package |
| Testing | Flutter test |

## Architecture

The project follows a feature-oriented structure:

```text
lib/
├── main.dart                  # Firebase, Hive and provider bootstrap
├── models/                    # Hive entities and generated adapters
├── providers/                 # Application state and data coordination
├── screens/
│   ├── auth/                 # Login, signup and password recovery
│   ├── shop/                 # Catalogue, cart, checkout and wishlist
│   ├── orders/               # Order history and order details
│   ├── profile/              # Profile, addresses and account settings
│   └── admin/                # Dashboard and seven admin sections
├── services/                 # Hive and authentication helpers
├── utils/                    # Validation and password helpers
└── seed-folder/              # Optional Firestore catalogue seed script
```

### Data ownership

| Data | Source |
|---|---|
| Product catalogue | Cloud Firestore, cached in Hive |
| Users and session | Firebase Authentication and Hive |
| Cart | Hive |
| Orders | Hive |
| Addresses | Hive |
| Wishlist | Hive |
| Reviews | Hive |
| Coupons | Hive |
| Theme/settings | Hive |

Checkout is a mock/local flow. It does not connect to Razorpay, Stripe or
another real payment provider.

## Requirements

Install the following before running the project:

- Flutter SDK
- Dart SDK included with Flutter
- Android SDK and Android Studio or VS Code
- Android emulator or physical Android device
- A Firebase project with Authentication and Firestore enabled
- Node.js only if using the optional seed script

Check the local setup with:

```bash
flutter doctor
flutter devices
```

## Installation

```bash
git clone <repository-url>
cd quickcart
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Firebase configuration

1. Create or select a Firebase project.
2. Enable Email/Password Authentication.
3. Enable Cloud Firestore.
4. Register the Android application with package name:

   ```text
   com.example.quickcart
   ```

5. Place the Android Firebase configuration file at:

   ```text
   android/app/google-services.json
   ```

The project already contains a Firebase configuration file for the configured
development project. Do not publish Firebase configuration or service-account
credentials in a public repository.

### Optional catalogue seed

The optional seed script is located at `lib/seed-folder/seed.js`. Run it only
after configuring the Firebase Admin SDK credentials locally:

```bash
cd lib/seed-folder
node seed.js
```

Never commit `serviceAccountKey.json`.

## Run on Android

Connect a physical phone with USB debugging enabled, or start an emulator:

```bash
flutter devices
flutter run
```

To select a specific device:

```bash
flutter run -d <device-id>
```

Build a release APK with:

```bash
flutter build apk --release
```

The output is generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Test and validation

Run the complete test suite:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

The automated tests cover:

- Input validation
- Password hashing and confirmation
- Discount and coupon calculations
- Cart totals
- Local authentication and session persistence
- User-scoped cart persistence
- Profile updates
- Theme persistence

Firebase, Firestore, Android-device, performance and security flows also
require manual or integration verification.

## Project documentation

Additional academic evidence is available in:

- [Project documentation](docs/project_documentation.md)
- [Academic audit](docs/cartify_software_engineering_academic_audit.docx)
- [Project management evidence](docs/cartify_project_management_evidence.docx)
- [Quality and maintenance evidence](docs/cartify_quality_maintenance_evidence.docx)
- [AI-assisted engineering evidence](docs/cartify_ai_assisted_engineering_evidence.docx)
- [Final submission checklist](docs/cartify_final_submission_checklist.docx)

The academic package also includes the feasibility study, SRS, MoSCoW
prioritization, use-case diagram, DFDs, sequence diagram and order
state-transition diagram.

## Scope and limitations

### Included

- Single-store Android shopping
- Firestore product catalogue
- Hive offline cache and local transactions
- Customer and administrator workflows
- Mock checkout

### Excluded from the current version

- Real-time push notifications
- Real payment gateway integration
- Multi-vendor marketplace support
- Geo-fencing

The application is an academic prototype and is not presented as
production-ready. Before production deployment, authentication, admin
authorization, Firestore rules, credential storage, error handling and
automated integration coverage require additional hardening.

## Development approach

Development followed an iterative, feature-driven approach:

1. Flutter and Provider study
2. Initial project planning and feasibility review
3. Cartify architecture and Hive data models
4. Catalogue and product discovery
5. Cart, checkout, orders and profile
6. Administrator panel
7. Testing, documentation and final validation

## License

This project is intended for academic and internship evaluation. Refer to the
project owner or organisation for permission before redistribution.
