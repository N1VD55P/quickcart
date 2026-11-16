# Cartify Project Documentation

## Project Overview
Cartify is a Flutter storefront app that uses Hive for local persistence,
Provider for cart state, and a feature-oriented screen structure. Firebase
Authentication handles online identity, Cloud Firestore provides the product
catalogue, and Hive stores the offline catalogue cache and local transactional
data. Firebase configuration is supplied locally and is intentionally excluded
from version control.

## Architecture
The codebase is organized by feature instead of by a strict layered architecture.

- `lib/main.dart` initializes Flutter, Hive, all adapters, and all boxes, then launches the app at `SplashScreen`.
- `lib/screens/` contains the feature UI, split into `auth`, `shop`, `orders`, and `profile`.
- `lib/models/` contains all Hive-persisted entities: `Product`, `User`, `CartItem`, `Order`, `Address`, and `Review`.
- `lib/providers/` contains `CartProvider`, `AuthProvider`, `ProfileProvider`, `ProductProvider`, and `ThemeProvider`.
- `lib/services/` contains `AuthService` and `HiveService`, but most screens access Hive directly rather than going through these abstractions.
- `lib/utils/` holds validation and password hashing helpers.
- `lib/screens/shop/widgets/` and `lib/providers/widgets/` contain reusable UI pieces for the home feed and cart.

The app uses imperative navigation with `Navigator.push`, `pushReplacement`, and `pushAndRemoveUntil`. There is no named route table, router, or dedicated navigation service.

## Data Model And Storage
All persistent data is stored locally in Hive.

- `users` stores `User` records.
- `products` stores `Product` records.
- `cart` stores `CartItem` records.
- `orders` stores `Order` records.
- `addresses` stores `Address` records.
- `reviews` stores `Review` records.
- `settings` stores session keys such as `currentUser`.
- `wishlist` stores product identifiers as `String` values, even though `HiveService.wishlist` is typed as `Box<Product>`.

The models are simple Hive objects with generated adapters. Firestore is the remote source for the product catalogue; the typed Hive `products` box provides the offline catalogue cache, while transactional data remains local.

## Screen-By-Screen Explanation

### Auth Flow

#### Splash Screen
`SplashScreen` is a timed entry screen that waits two seconds and then navigates to `LoginScreen`. It is purely transitional and does not inspect authentication state before routing.

#### Login Screen
`LoginScreen` validates email and password, attempts Firebase Authentication,
falls back to the local Hive `users` box when Firebase is unavailable, saves
the signed-in email into `settings.currentUser`, and navigates to `HomeScreen`.

#### Signup Screen
`SignupScreen` creates a user record in Hive after checking for duplicate email addresses. It stores name, email, password hash, and security answer. The confirm-password field is present in the UI and uses a validator, but the signup submit path itself does not enforce password matching separately.

#### Forgot Password Screen
`ForgotPasswordScreen` is a three-step reset flow: find account by email, verify security answer, and set a new password. The password reset path validates the confirmation field correctly before saving the new hash.

### Shop Flow

#### Home Screen
`HomeScreen` is the main authenticated shell. It seeds demo products into Hive if the products box is empty, shows a greeting based on the current user, and hosts the bottom navigation. Home content includes banners and category chips. Search is handled as an overlay rather than a separate route.

#### Banner Slider
`BannerSlider` cycles through promotional cards automatically and only uses local UI data. It does not drive any commerce logic.

#### Category Chips
`CategoryChips` filters products by category, renders a two-column grid, lets users open product details, and supports wishlist toggling plus quick add-to-cart from the catalog grid.

#### Search Overlay
`SearchOverlay` performs local full-text filtering across product name, description, and category. Results open the product detail screen.

#### Product Detail Screen
`ProductDetailScreen` shows product details, stock state, average rating, review list, a review composer, and an add-to-cart action. Reviews are stored in Hive and filtered by product ID.

#### Wishlist Screen
`WishlistScreen` resolves wishlisted product IDs against the products box, lets users remove items, add single items to cart, and move all wishlist items to cart. It uses a Hive string box for the wishlist state.

#### Cart Screen
`CartScreen` displays the live cart using `CartProvider`, shows total price, and routes to checkout.

#### Checkout Screen
`CheckoutScreen` requires a default address, supports coupon codes, calculates the final total, creates an `Order`, clears the cart, and routes to the order success screen.

#### Order Success Screen
`OrderSuccessScreen` confirms the order and provides two forward paths: view orders or continue shopping.

### Orders Flow

#### Orders Screen
`OrdersScreen` lists only the current user's orders and sorts them newest first. It shows order ID, date, item preview, status, and total.

#### Order Detail Screen
`OrderDetailScreen` shows a status timeline, ordered items, delivery address, price summary, and reorder action. Reorder re-adds the order items back into the cart by looking up matching products in Hive.

### Profile Flow

#### Profile Screen
`ProfileScreen` shows the active user's initials, name, email, order count, and total spent. It links to edit profile, change password, address book, orders, logout, and delete account.

#### Edit Profile Screen
`EditProfileScreen` edits the current user's name and phone number. Email is read-only.

#### Change Password Screen
`ChangePasswordScreen` verifies the current password, checks that the new password confirmation matches, and updates the stored password hash.

#### Address Book Screen
`AddressBookScreen` manages delivery addresses for the current user. It supports add, edit, delete, and setting one address as default.

#### Delete Account Screen
`DeleteAccountScreen` validates the password before deleting the user and cascading through their orders, addresses, reviews, cart, wishlist, and session key.

## User Flow
The intended user journey is straightforward.

1. Launch the app and land on the splash screen.
2. Sign in or create a local account.
3. Reach the home catalog with banners, category filters, and product cards.
4. Open product details, add items to the cart, wishlist items, or submit reviews.
5. Review the cart and proceed to checkout.
6. Select a saved address and apply a coupon if desired.
7. Place the order and land on the success screen.
8. Inspect order history and reorder from the order detail screen.
9. Manage profile, passwords, and addresses from the profile tab.

## Data Flow
The app is driven by Hive boxes and direct UI reads.

- Auth writes the current user email to `settings.currentUser`.
- Profile, checkout, reviews, addresses, and orders all derive the active user from that session key.
- Products are fetched from Cloud Firestore and cached in the typed Hive `products` box by `ProductProvider`; the cached catalogue remains available when the network is unavailable.
- Cart changes are handled by `CartProvider`, which persists cart records in Hive and notifies listeners.
- Wishlist is stored as string IDs in Hive and resolved back to `Product` records on demand.
- Orders are built from the current cart items and stored as a full snapshot.
- Reviews and addresses are bound to the current user's email.

## Implemented Features
- Local account sign-up, login, and logout.
- Password hashing and password recovery using a security answer.
- Product seeding, browsing, category filtering, and search.
- Wishlist add/remove and move-to-cart behavior.
- Cart quantity management with live totals.
- Coupon application during checkout.
- Saved address selection and address-book management.
- Order creation, order history, order details, and reorder.
- Product reviews and average rating display.
- Profile editing, password change, and account deletion.

## Project Structure And Main Modules

The project is organized as a Flutter Android application:

```text
lib/
├── main.dart                 # Firebase, Hive and Provider bootstrap
├── models/                   # Product, user, cart, order and profile models
├── providers/                # Authentication, products, cart, profile and theme state
├── screens/
│   ├── auth/                 # Login, signup, phone auth and password recovery
│   ├── shop/                 # Catalogue, search, product details, cart and checkout
│   ├── orders/               # Order history, details and reorder
│   ├── profile/              # Profile, addresses and account settings
│   └── admin/                # Dashboard and store-management tabs
├── services/                 # Authentication and Hive helpers
└── utils/                    # Validation and password hashing
```

The main data path is `ProductProvider` -> Firestore catalogue -> Hive cache
for products, while `CartProvider`, `ProfileProvider` and the order screens
manage user-scoped local shopping data.

## Hardware, Software And Development Environment

The following environment details were captured from the development
workspace on 16 November 2026. Storage values are rounded for reporting.

### Development laptop

| Component | Verified specification |
|---|---|
| Processor | Intel Core i7-14700HX |
| CPU layout | 20 physical cores / 28 logical threads |
| Memory | 16 GB RAM (approximately 15 GiB reported by the operating system) |
| Storage | 512 GB-class NVMe SSD (473 GB mounted capacity reported) |
| Operating system | CachyOS 7.3.4-1-cachyos, Linux |

### Android test device

| Component | Verified specification |
|---|---|
| Model/device identifier | I2403 |
| Android version | Android 16 |
| Connection record | Previously detected by Flutter as device `10BF1D0UJ0005KQ` |

The Android phone was not connected during the environment capture on
16 November 2026; therefore, the device row should be supported by the
attached device screenshot or test log in the final submission.

### Development software

| Software | Version or detail |
|---|---|
| Flutter | 3.47.9, stable channel |
| Dart | 3.13.7 |
| DevTools | 2.60.0 |
| IDE | Visual Studio Code (active workspace IDE) |
| Android project support | Android Studio-compatible Gradle project |
| Source control | Git and GitHub |
| Repository | https://github.com/N1VD55P/quickcart |
| Android application ID | `com.example.quickcart` |

The repository includes Android Studio project metadata, but the verified
active IDE for this development session was VS Code. If Android Studio was
also used by a team member, record that member's IDE version separately
instead of presenting it as the primary verified environment.

## Development Methodology And Project Timeline

The project followed an **iterative, feature-driven SDLC model**. Work was
organized into short feature phases rather than a single Waterfall sequence:

1. Requirements, feasibility and MoSCoW prioritization
2. Flutter project setup, architecture and Hive data models
3. Authentication, profiles and local persistence
4. Firestore catalogue, search and product details
5. Cart, wishlist, checkout and local orders
6. Administrator dashboard and product management
7. Testing, academic evidence, documentation and repository cleanup

Git was used for source control throughout development, with the project
published at
[N1VD55P/quickcart](https://github.com/N1VD55P/quickcart). The repository
history shows the first project commit on 19 July 2026 and the latest
documentation/evidence work on 16 November 2026, giving an overall project
period of approximately four months. This should be described as the calendar
development period; individual implementation effort was distributed across
the phases above.

The project did not use formally numbered Scrum sprints. For the report, use
the phase list above as the project's practical iteration structure unless the
team has separate sprint records.

## Required Demonstration Screenshots

The following screenshots should be captured from the running Android app and
attached to the academic submission. Use test accounts and hide email
addresses, tokens, project identifiers and other private information:

### Customer screens

1. Login screen
2. Signup screen
3. Catalogue/home screen with products
4. Product details screen
5. Cart with quantity and total
6. Checkout with address and coupon
7. Order confirmation
8. Order history and order details
9. Profile and address book

### Administrator screens

Capture the admin dashboard and each of the seven tabs:

1. Dashboard
2. Products
3. Orders
4. Users
5. Inventory
6. Reviews
7. Coupons

Record each screenshot in
[`Cartify_Evidence/evidence_index.md`](../Cartify_Evidence/evidence_index.md),
including the test ID, date, device, steps and expected result.

## Test Cases, Results And Devices

Automated evidence is stored in the
[`Cartify_Evidence/`](../Cartify_Evidence/) folder:

The complete academic testing section is available in
[`TESTING_DOCUMENTATION.md`](../TESTING_DOCUMENTATION.md).

- `evidence_flutter_test.txt` records 35 passing Flutter tests, including
  validation, hashing, coupon calculations, local authentication, profile
  persistence, theme persistence and user-scoped cart behavior.
- `evidence_flutter_analyze.txt` records static analysis output. It contains
  informational lints and warnings and should not be described as a
  zero-warning analysis.
- `evidence_devices.txt` records the device detected when the evidence command
  was run. A new device output should be captured for each final submission
  test session.
- `manual_test_record.md` provides the required format for Firebase, Firestore,
  checkout, admin, offline and Android-device tests.

For each manual test, record the app version or commit, Android version,
network state, steps, expected result, actual result, evidence filename and
PASS/FAIL/BLOCKED status.

## Implementation Challenges And Resolutions

| Challenge | Resolution |
|---|---|
| Catalogue must remain usable when the network is unavailable | Products fetched from Firestore are cached in Hive and the cached data is retained when the remote request fails. |
| Local shopping data could be mixed between accounts | Cart records are associated with the active user and cart totals and clearing are filtered by that user. |
| Firebase configuration must not be published with the repository | `google-services.json` is supplied locally and ignored by Git; setup instructions are documented in the README. |
| Product data needs to be manageable by an administrator | The admin Products tab provides Firestore-backed product create, update and delete operations. |
| Evidence must distinguish automated and manual claims | Reproducible command output is stored separately from screenshot and manual-test templates in `Cartify_Evidence`. |
| The application has a broad academic scope | Features were separated into authentication, catalogue, cart, checkout, orders, profile and admin modules with focused providers and screens. |

These resolutions describe the implementation visible in the repository. Add
team-specific challenges only when the team can support them with notes,
commits, screenshots or test records.

## Individual Team Contributions

Replace the placeholders below with the actual names and contributions agreed
by the team. Do not assign work based only on commit count; confirm each
person's contribution with the team.

| Team member | Contribution | Evidence |
|---|---|---|
| Member 1: Neil jain | Project planning and requirements traceability | Submitted reports, diagrams and `docs/` evidence |
| Member 2: Navdeep Singh | Flutter customer flow: authentication, catalogue, product details, feasibility/SRS/MoSCoW analysis cart and checkout | Relevant source files, screenshots |
| Member 3: Nihit | Admin panel, Firebase/Firestore integration, testing, documentation and evidence packaging | Admin screenshots, test outputs and `Cartify_Evidence/` |

### Contribution confirmation

Each member should review the table, correct their row, and confirm the
description before submission. Include the team's agreed names, dates and
signatures if the college requires them.

## Current Limitations
- Firebase configuration and Firestore access require an authenticated project at runtime.
- The admin password is currently configured in the client and should be replaced with Firebase custom claims before production.
- No route management layer.
- Wishlist records are currently stored as product IDs in a shared local box; user-specific wishlist partitioning remains a future hardening task.
- No stock enforcement on add-to-cart or checkout.
- No order fulfillment progression beyond the static status labels used in the UI.
- No robust password policy or salted password storage.
- Automated unit and local-persistence tests exist; Firebase, Firestore,
  Android-device, performance and security claims still require manual or
  integration evidence.
- Real payment gateways, push notifications, multi-vendor support, and geo-fencing are outside the current scope.

## Suggested Improvements
- Introduce a repository/service boundary so screens stop reaching into Hive directly.
- Replace plain SHA-256 password hashing with a salted password strategy.
- Make wishlist storage consistent by storing full product references or by renaming the Hive helper to match the actual data type.
- Scope cart and wishlist to the active user.
- Add route centralization and a single navigation entry point.
- Add validation that signup passwords match before account creation.
- Add tests for auth, cart, checkout, and wishlist behavior.
- Move product seeding out of the UI layer into a dedicated bootstrap or fixture layer.
- Add stock checks and more realistic order lifecycle handling.
- Reduce duplication in shared widget styling and form decoration.

## Recommended Development Roadmap
### Phase 1: Correctness And Structure
- Fix signup confirmation validation and tighten password flows.
- Align wishlist storage and `HiveService` typing.
- Add basic tests for login, signup, cart mutations, and checkout.
- Move repeated Hive access patterns into one repository or service layer.

### Phase 2: Product And Order Reliability
- Add user-scoped cart and wishlist behavior.
- Enforce product stock limits.
- Improve order lifecycle modeling beyond a static status string.
- Separate demo product seeding from runtime UI code.

### Phase 3: Maintainability
- Replace the client-side admin password with Firebase custom claims before production.
- Introduce centralized navigation and reusable form components.
- Reduce duplicated styling across auth, profile, and shop screens.

### Phase 4: Production Readiness
- Replace local-only storage with a backend or sync layer if the product needs multi-device support.
- Add stronger security for credentials and recovery flows.
- Add analytics, error handling, and richer test coverage.

## Notes
This documentation reflects the current codebase as implemented in `lib/` and `test/`. It describes the app as a local-first Flutter storefront with working purchase flows, but it is not yet production-ready because the persistence, authentication, and testing layers are still simple and mostly local.
