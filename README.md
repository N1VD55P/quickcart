QuickCart
1. Project Title & Badges

Project Title: QuickCart

One-line Tagline: A Flutter-powered offline-first Android shopping app with Firebase-backed product catalogue, Hive local storage, and a built-in admin panel.

Badges:

Show Image
Show Image
Show Image
Show Image
Show Image

2. Abstract

QuickCart is a Flutter-based, offline-first e-commerce Android application developed during a Practice School II internship at Devherds Software Solutions, Mohali, Punjab, from June 2026 to July 2026. The app addresses the need for a lightweight yet fully functional mobile retail experience that works reliably even with limited connectivity. It uses Cloud Firestore for remote product catalogue data and Hive for all local persistence including users, cart items, orders, addresses, reviews, wishlists, coupons, and settings. State is managed through the Provider package, and authentication is handled via Firebase Authentication with SHA-256 hashed local credentials for offline scenarios. The application also includes a seven-tab admin panel for managing products, orders, users, inventory, reviews, and coupons. QuickCart was built over approximately six weeks of active development — after two weeks of advanced Flutter study and a one-week pivot from an earlier project — and delivers a fully functional Android storefront prototype demonstrating practical mobile engineering, cloud and offline storage integration, reactive state management, and secure authentication flows.

3. Table of Contents
1. Project Title & Badges
2. Abstract
4. Introduction to the Problem Domain
5. Overview of the Organisation / Project Context
6. Features & Functionality
7. Tech Stack & Architecture
8. System Architecture Diagram
9. Folder Structure
10. Installation & Setup Guide
11. Environment Variables / Configuration
12. Week-by-Week Development Timeline
13. Methodology / Development Approach
14. Results & Outcomes
15. Challenges Faced & Solutions
16. Conclusions & Recommendations
17. Course Outcomes & Learning Outcomes
18. References
19. License
20. Acknowledgements
4. Introduction to the Problem Domain
Domain

QuickCart belongs to the e-commerce and retail technology domain. It is a consumer-facing Android storefront covering product discovery, account management, cart and checkout workflows, and order tracking.

Problem Statement

Many retail users need a fast, offline-resilient mobile shopping experience. Existing web-first solutions struggle on low-connectivity Android devices and require repeated loading of all data. QuickCart solves this by fetching the product catalogue from Firestore once and storing all transactional data — cart, orders, addresses, reviews — locally in Hive, giving users a smooth experience regardless of connectivity.

Why Mobile

Mobile is the right choice because retail users want quick product access, saved addresses, wishlist management, and fast checkout while on the move. Persistent local storage via Hive further enhances the experience by retaining session and transaction data across app restarts.

Target Users
Regular Android shoppers who want fast product browsing and a simple checkout flow.
Users who need persistent wishlists, saved addresses, and order history in one place.
Admin users who need to manage products, orders, and inventory from within the app.
5. Overview of the Organisation / Project Context
Organisation Profile

This application was built at Devherds Software Solutions, a software development company based in Mohali, Punjab, India. Devherds focuses on building digital products and mobile solutions for clients across various domains.

Project Context

QuickCart was assigned as the main PS-II internship project after an initial project (a QR/barcode-based Smart Data Collection and Inspection App) was found to be too technically complex to complete within the remaining internship window. QuickCart was scoped as a well-rounded Flutter project that could demonstrate all required concepts — state management, local storage, cloud integration, authentication, and admin functionality — within the available time.

Business Relevance

The project demonstrates a complete mobile commerce frontend suitable for use as a prototype or starting point for a retail platform. It covers the full customer journey from registration through to order placement and history, plus an admin module for backend operations.

6. Features & Functionality
Core Features
Secure signup and login with SHA-256 hashed passwords stored locally in Hive.
Offline password recovery using a locally stored security question and answer.
Product catalogue fetched once from Cloud Firestore and cached in memory.
Home screen with category filter chips, a promotional banner slider, and product grid.
Local search across product names and metadata using cached data.
Product detail screen with images, ratings, stock status, and reviews.
Cart management with add, remove, quantity increase/decrease, and running total.
Wishlist with real-time UI updates through ValueListenableBuilder and Hive.
Checkout flow with address selection, coupon application, and mock payment.
Order creation, order success confirmation, and order history with reorder capability.
User profile management including edit, password change, and full account deletion.
Address book with add, edit, delete, and default address selection.
Product reviews stored locally with average rating display on product pages.
Seven-tab Admin Panel: Dashboard, Products (Firestore CRUD), Orders, Users, Inventory, Reviews, and Coupons.
Secondary Features
Splash screen with automatic routing based on saved session state.
Theme switching with persistence via a Hive-backed theme provider.
Responsive category filter chips and promotional banner components.
Cascade account deletion that clears all related Hive boxes on account removal.
Local session persistence so returning users are taken directly to the home screen.
Admin / Backend Features
Admin login screen with a fixed admin password.
AdminHomeScreen with a seven-tab IndexedStack covering all management areas.
Dashboard tab showing live stats pulled from both Hive and Firestore.
Products tab with full Firestore CRUD operations displayed via StreamBuilder.
Orders tab with order status management backed by Hive.
Firestore product seed script (lib/seed-folder/seed.js) for loading demo catalogue data.
7. Tech Stack & Architecture
Platform and Language
Flutter 3.x / Dart 3.x
Target platform: Android 6.0 and above
State Management
Provider — using ChangeNotifier, MultiProvider, context.read, context.watch, and notifyListeners().
Key providers: AuthProvider, CartProvider, ProfileProvider, ProductProvider, ThemeProvider.
Backend and API Layer
Firebase Authentication for email/password sign-in and account creation.
Cloud Firestore for the product catalogue (read-heavy, loaded once at startup).
No custom server or REST API — all backend services are Firebase-managed.
Database and Persistence
Cloud: Cloud Firestore (products collection).
Local: Hive with typed adapters generated via build_runner.
Hive boxes: users, cart, orders, addresses, reviews, wishlist, settings, coupons.
Authentication
Firebase Authentication for account creation and sign-in.
SHA-256 password hashing for locally stored credentials.
Offline-capable password recovery using a stored security question.
Session tracking via settings.currentUser in Hive.
Key Dependencies
Package	Purpose
firebase_core	Firebase app initialisation
firebase_auth	User authentication
cloud_firestore	Product catalogue storage and retrieval
hive	Local database engine
hive_flutter	Hive Flutter integration
hive_generator	Adapter code generation
provider	State management
build_runner	Code generation for Hive adapters
crypto	SHA-256 password hashing
uuid	Unique order and record ID generation
image_picker	Profile and product image selection
Architecture Style

Feature-oriented layered architecture, closest to a lightweight MVVM pattern. Screens handle presentation, Provider classes manage state and data coordination, and Services abstract Hive and Firebase access.

8. System Architecture Diagram (Text-Based)
Android User
     │
     ▼
Flutter UI Screens
(auth / shop / orders / profile / admin)
     │
     ▼
Provider State Layer
(AuthProvider, CartProvider, ProductProvider, ProfileProvider, ThemeProvider)
     │
     ├──────────────────────────────┐
     ▼                              ▼
Firebase Services             Hive Local Storage
  ├── Firebase Auth            ├── users box
  └── Cloud Firestore          ├── cart box
       └── products            ├── orders box
           collection          ├── addresses box
                               ├── reviews box
                               ├── wishlist box
                               ├── settings box
                               └── coupons box
9. Folder Structure
text
quickcart/
├── pubspec.yaml                     # Flutter dependencies and app metadata
├── firebase.json                    # Firebase CLI project configuration
├── firestore.rules                  # Firestore security rules
├── firestore.indexes.json           # Firestore composite index definitions
├── android/
│   └── app/
│       ├── google-services.json     # Firebase Android configuration (keep secret)
│       └── build.gradle.kts
├── lib/
│   ├── main.dart                    # Entry point: Firebase init, Hive init, providers
│   ├── models/                      # Hive data models and generated .g.dart adapters
│   │   ├── user.dart
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   ├── address.dart
│   │   ├── review.dart
│   │   └── product.dart
│   ├── providers/                   # State management layer
│   │   ├── auth_provider.dart
│   │   ├── cart_provider.dart
│   │   ├── profile_provider.dart
│   │   ├── theme_provider.dart
│   │   └── Product_Provider.dart
│   ├── screens/
│   │   ├── auth/                    # Splash, Login, Signup, Forgot Password
│   │   ├── shop/                    # Home, Product Detail, Cart, Checkout, Wishlist, Search
│   │   ├── orders/                  # Order History, Order Detail
│   │   ├── profile/                 # Profile, Edit, Password, Address Book, Delete Account
│   │   └── admin/                   # Admin Login, Admin Home, all 7 admin tabs
│   ├── services/
│   │   ├── auth_service.dart        # Hive-backed local auth logic
│   │   └── hive_service.dart        # Hive box access helpers
│   ├── utils/                       # Validators, password helpers
│   ├── widgets/                     # Shared reusable widgets
│   └── seed-folder/
│       └── seed.js                  # Node.js script to seed Firestore with demo products
└── test/
    └── widget_test.dart
10. Installation & Setup Guide
Prerequisites
Flutter SDK (3.x) installed and added to PATH.
Android Studio or VS Code with Flutter and Dart plugins.
Android SDK with at least one emulator (API 23 / Android 6.0+) or a physical Android device.
A Firebase project with Authentication and Cloud Firestore enabled.
Node.js (for the optional Firestore seed script).
Steps

1. Clone the repository

bash
git clone [YOUR REPOSITORY URL]
cd quickcart

2. Install Flutter dependencies

bash
flutter pub get

3. Generate Hive adapters

bash
dart run build_runner build --delete-conflicting-outputs

4. Add Firebase configuration

Place your google-services.json inside android/app/.
Confirm your Firebase project has Authentication and Firestore enabled.

5. (Optional) Seed Firestore with demo products

bash
cd lib/seed-folder
node seed.js

6. Run on Android

bash
flutter run

7. Build a release APK

bash
flutter build apk
11. Environment Variables / Configuration
File	Purpose	Sensitive?
android/app/google-services.json	Firebase Android configuration	Yes — do not commit to public repositories
firebase.json	Firebase CLI project settings	No
.firebaserc	Firebase project alias	No
firestore.rules	Firestore security rules	No, but review before production
lib/seed-folder/serviceAccountKey.json	Firebase Admin SDK key for seeding	Yes — never commit this file

No .env file is used. All Firebase config is handled through google-services.json and the Firebase Flutter SDK.

12. Week-by-Week Development Timeline
Week	Dates	Theme	Key Activities
Week 1	1 June – 7 June 2026	Advanced Flutter Study	Studied null safety, async/await, Futures, Streams, widget lifecycle, keys, multi-screen navigation, layouts, themes, and custom widgets.
Week 2	8 June – 14 June 2026	State Management & UI Planning	Studied setState limitations, Provider package (ChangeNotifier, Consumer, MultiProvider), practised with counter and theme-switcher examples, sketched app UI flow.
Week 3	15 June – 21 June 2026	First Project (SDCI) Begins	Planned architecture for the QR/barcode-based SDCI project. Built Signup, Login, and Splash screens with SHA-256 hashing and session routing.
Week 4	22 June – 28 June 2026	Navigation, Hive & Pivot Decision	Implemented navigation and routing for SDCI. Set up Hive in main.dart, registered TypeAdapters, ran build_runner. Built a mini side project combining Hive, Provider, and CRUD to consolidate learning.
Week 5	29 June – 5 July 2026	QuickCart Begins	Decided to pivot from SDCI to QuickCart. Designed full app flow, defined all Hive models (User, CartItem, Order, Address, Review, Coupon) with HiveType IDs, set up lib/ folder structure, built CartProvider.
Week 6	6 July – 12 July 2026	Core Screens Built	Built ProductProvider (Firestore fetch + in-memory cache), Home screen with grid/filters/banner/search, Wishlist screen with ValueListenableBuilder, set up Firebase project and added google-services.json.
Week 7	13 July – 19 July 2026	Checkout, Orders & Profile	Built Product Detail, Cart, Checkout with address/coupon/mock payment, Order Success, Order History, cascade account deletion, and Profile management screens.
Week 8	20 July – 26 July 2026	Admin Panel, Polish & Wrap-Up	Built Admin Login, AdminHomeScreen (7-tab IndexedStack), Dashboard (Hive + Firestore stats), Products tab (Firestore CRUD via StreamBuilder), Orders tab. Spent final days refining UI, fixing bugs, and writing documentation.
13. Methodology / Development Approach
Approach

An iterative, feature-driven approach was used. The app was built in layers — authentication and data models first, then browsing, then cart and checkout, then profile and admin — so each piece could be tested before the next was added.

Version Control

Git was used throughout. A single main branch was used for this internship project, with logical commit groupings per feature.

Testing
Manual end-to-end testing of all user journeys (signup, login, browse, cart, checkout, order, profile, admin).
Edge cases tested: empty product lists, empty cart, invalid coupon, missing address at checkout, account deletion.
Flutter widget test scaffold is present for future automated coverage.
CI/CD

No automated CI/CD pipeline is configured. A future setup could use GitHub Actions or Codemagic for lint, test, and APK build automation.

14. Results & Outcomes
Delivered

A fully working Android shopping application covering the complete retail user journey from registration to order placement, plus a seven-tab admin panel.

Measurable Outputs
6 Hive data models: User, CartItem, Order, Address, Review, Coupon.
8 Hive boxes for offline-first data persistence.
5 Provider classes for reactive state management.
7-tab Admin Panel with Firestore CRUD and Hive-backed order management.
10+ user-facing screens across auth, shop, orders, and profile domains.
1 Node.js Firestore seed script for demo catalogue data.
Screenshots Placeholder
[PLACEHOLDER] Splash screen.
[PLACEHOLDER] Signup and Login screens.
[PLACEHOLDER] Home screen with product grid, category chips, and banner.
[PLACEHOLDER] Product Detail screen with reviews and Add to Cart.
[PLACEHOLDER] Cart and Checkout screens.
[PLACEHOLDER] Order Success and Order History screens.
[PLACEHOLDER] Profile and Address Book screens.
[PLACEHOLDER] Admin Dashboard and Products tab.
15. Challenges Faced & Solutions
Challenge	Impact	Solution
SDCI project too complex (camera, barcode scanning, SQLite) to complete in time	Lost 3 weeks of productive development	Pivoted to QuickCart after Diary Presentation 1, scoped to be completable and still comprehensive
Hive adapter generation with build_runner	Missing or broken .g.dart files caused runtime errors	Ran dart run build_runner build --delete-conflicting-outputs and ensured all @HiveType/@HiveField annotations were correct before generating
Synchronising Firebase Auth session with local Hive state	Screens needed a stable local session value after login	Stored current user email in Hive settings box and refreshed providers from it after successful sign-in
Cart totals staying reactive after Hive writes	UI showed stale totals after quantity changes	Centralised all cart mutations inside CartProvider and called notifyListeners() after every Hive write
Loading Firestore products efficiently for home, search, and category screens	Multiple screens needed the same product data without repeated Firestore calls	Used ProductProvider to fetch all products once at startup and cache them in memory, exposing filter and search helpers
Cascade account deletion across multiple Hive boxes	Deleted accounts left stale cart, order, and address data	Implemented a single deletion method that cleared all user-related Hive boxes in sequence and reset the session key
16. Conclusions & Recommendations
Conclusion

QuickCart successfully demonstrates how Flutter can be used to build a production-grade Android commerce application combining cloud-backed product data, fully offline-capable local storage, reactive state management, Firebase authentication, and an in-app admin panel — all within an 8-week internship period.

Recommendations for Future Work
Integrate a real payment gateway (Razorpay, Stripe) to replace the mock payment flow.
Add Firebase Cloud Messaging for order status push notifications.
Extend the admin panel with analytics charts and export functionality.
Add full automated test coverage for auth, cart, checkout, and admin flows.
Tighten Firestore security rules for production deployment.
Make the app available on the Google Play Store with proper signing configuration.
17. Course Outcomes & Learning Outcomes
Learning Outcome	Mapping to This Project
Mobile application development	Designed and built a multi-screen Flutter Android app from scratch
Database and data modelling	Modelled 6 Hive entities and integrated Cloud Firestore for product data
State management	Applied Provider with ChangeNotifier across 5 providers and multiple screens
Authentication and security	Implemented Firebase Auth, SHA-256 password hashing, and offline recovery
Software engineering practice	Used iterative development, modular folder structure, and reusable widgets
Testing and validation	Performed thorough manual testing across all user journeys and edge cases
Professional communication	Documented the full project in a PS-II report-ready format
Technical Skills Gained
Advanced Flutter widget composition, navigation, and layout.
Hive setup, TypeAdapter generation with build_runner, and CRUD operations.
Firebase Authentication and Cloud Firestore integration in Flutter.
Provider-based state design with ChangeNotifier and MultiProvider.
Dart async programming: async/await, Futures, Streams, null safety.
Professional Skills Gained
Scope management and knowing when to pivot a project.
Iterative delivery — building and testing one feature at a time.
Technical documentation for academic and professional audiences.
Time management across weekly internship deliverables.
18. References
Flutter Documentation: https://docs.flutter.dev
Dart Language Documentation: https://dart.dev/guides
Firebase Documentation: https://firebase.google.com/docs
Cloud Firestore: https://firebase.google.com/docs/firestore
Firebase Authentication: https://firebase.google.com/docs/auth
Hive Documentation: https://docs.hivedb.dev
Provider Package: https://pub.dev/packages/provider
Crypto Package: https://pub.dev/packages/crypto
UUID Package: https://pub.dev/packages/uuid
Image Picker Package: https://pub.dev/packages/image_picker
19. License

This project is Proprietary / Internal Use — developed as part of a PS-II internship at Devherds Software Solutions. Not for redistribution without permission.

20. Acknowledgements
Ms. Devanjali Relan, PS-II Faculty Mentor, BML Munjal University.
Devherds Software Solutions team, Mohali, Punjab, for the internship opportunity and guidance.
BML Munjal University, for the Practice School II programme.
The Flutter, Firebase, Hive, and Provider open-source communities.
