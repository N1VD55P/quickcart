# QuickCart Project Documentation

## Project Overview
QuickCart is a Flutter storefront app that uses Hive for local persistence, Provider for cart state, and a feature-oriented screen structure. The application is fully client-side: users sign up, log in, browse products, manage a wishlist and cart, place orders, save addresses, write reviews, and manage their profile without any backend API.

## Architecture
The codebase is organized by feature instead of by a strict layered architecture.

- `lib/main.dart` initializes Flutter, Hive, all adapters, and all boxes, then launches the app at `SplashScreen`.
- `lib/screens/` contains the feature UI, split into `auth`, `shop`, `orders`, and `profile`.
- `lib/models/` contains all Hive-persisted entities: `Product`, `User`, `CartItem`, `Order`, `Address`, and `Review`.
- `lib/providers/` contains `CartProvider` plus two empty placeholder providers for auth and profile.
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

The models are simple Hive objects with generated adapters. They support local CRUD, but there is no backend sync, no remote catalog, and no network-dependent state.

## Screen-By-Screen Explanation

### Auth Flow

#### Splash Screen
`SplashScreen` is a timed entry screen that waits two seconds and then navigates to `LoginScreen`. It is purely transitional and does not inspect authentication state before routing.

#### Login Screen
`LoginScreen` validates email and password, searches the Hive `users` box, compares a SHA-256 password hash, saves the signed-in email into `settings.currentUser`, and navigates to `HomeScreen`.

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
- Products are seeded into Hive from a local list inside `HomeScreen`.
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

## Missing Features
- No backend API or remote data source.
- No true auth provider or profile provider implementation, despite placeholder files.
- No route management layer.
- No cart or wishlist scoping by user, beyond cleanup on account deletion.
- No stock enforcement on add-to-cart or checkout.
- No order fulfillment progression beyond the static status labels used in the UI.
- No robust password policy or salted password storage.
- No meaningful automated test coverage; `test/widget_test.dart` is empty.
- No admin workflows for product management, order management, or coupon management.

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
- Implement a real auth/profile provider layer or remove the empty placeholders.
- Introduce centralized navigation and reusable form components.
- Reduce duplicated styling across auth, profile, and shop screens.

### Phase 4: Production Readiness
- Replace local-only storage with a backend or sync layer if the product needs multi-device support.
- Add stronger security for credentials and recovery flows.
- Add analytics, error handling, and richer test coverage.

## Notes
This documentation reflects the current codebase as implemented in `lib/` and `test/`. It describes the app as a local-first Flutter storefront with working purchase flows, but it is not yet production-ready because the persistence, authentication, and testing layers are still simple and mostly local.
