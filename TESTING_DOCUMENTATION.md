# Cartify Software Testing and Test Cases

## 1. Introduction to Software Testing

Software testing was applied to verify that Cartify's implemented
authentication, catalogue, local persistence, shopping and administration
behaviour conforms to its intended requirements. The testing process combines
automated Dart tests for deterministic logic and Hive persistence with
manual/integration test procedures for Firebase, Android UI, Firestore and
device-dependent behaviour.

This document distinguishes executed tests from proposed manual tests. A test
is marked **Executed - PASS** only where it was run in the current repository
and produced the stated result. Tests that require a Firebase project,
connected Android phone, or interactive UI are marked **Not Executed** until
the team records them using the evidence templates.

## 2. Project Analysis

### 2.1 Architecture and technologies

Cartify is a Flutter Android application using:

- Flutter and Dart for the user interface and application runtime.
- Provider for application state (`AuthProvider`, `ProductProvider`,
  `CartProvider`, `ProfileProvider` and `ThemeProvider`).
- Hive/Hive Flutter for local users, products, cart items, orders, addresses,
  reviews, coupons, wishlist identifiers, settings and cached catalogue data.
- Firebase Authentication for email/password, Google and phone OTP
  authentication paths.
- Cloud Firestore for the remote `products` catalogue and administrator
  product operations.
- `crypto` for the current SHA-256 local password hash.
- `uuid` for local order identifiers.
- Flutter's `flutter_test` package for automated tests.

### 2.2 Verified modules and functionality

| Module | Verified implementation |
|---|---|
| Application bootstrap | `main.dart` initializes Firebase and Hive, registers adapters, opens boxes, fetches products and creates Provider instances. |
| Validation and hashing | `Validators` validates name, email, password and 10-digit phone input; `PasswordHelper` computes SHA-256 hashes. |
| Authentication | `AuthProvider` contains Firebase email/password, Google and phone OTP flows, local login fallback, session persistence and logout. `SignupScreen` currently creates local Hive accounts directly after validation. |
| Catalogue | `ProductProvider` loads cached Hive products, refreshes from Firestore, maps missing numeric fields to defaults, searches by name/description/category and filters by category. |
| Customer shopping | Home, search, product detail, wishlist, cart, checkout and order-success screens are implemented. |
| Local transaction flow | Checkout requires a default address, supports `SAVE10`, `SAVE20` and `FLAT50`, writes a local `Order`, clears the active user's cart and shows order success. |
| Profile and account data | Profile editing, password change, address CRUD/default selection, theme persistence and account deletion are implemented through Hive. |
| Orders | Orders are filtered by active user, displayed newest first, shown in detail and can be reordered into the cart. |
| Administration | Admin login uses the client-side password `ADMIN123`; the panel contains Dashboard, Products, Orders, Users, Inventory, Reviews and Coupons tabs. |
| Admin data operations | Product and inventory operations use Firestore; users, orders, reviews and coupons are read or modified locally through Hive. |

### 2.3 Partially implemented or limited functionality

The following are implemented paths with limitations, not fully production-ready
features:

- Firebase Google and phone authentication require provider configuration and
  a real device/project; they were not verified by the automated suite.
- `SignupScreen` writes to local Hive directly, while a separate
  `AuthProvider.signup` Firebase method exists. This creates two signup paths.
- Firestore product loading has a Hive fallback, but Firestore rules currently
  contain `allow read, write: if true;`.
- Admin authorization is a hardcoded client-side password, not server-side
  role authorization.
- Checkout and orders are local/mock transactions; no payment gateway or
  remote order service is implemented.
- Wishlist storage is a shared local box and is not filtered by active user.
- Firebase, Android UI, performance and security claims require manual or
  integration evidence.

## 3. Testing Methodology

An iterative testing approach was used:

1. Inspect source modules and identify input, state, persistence and remote
   boundaries.
2. Execute deterministic unit and local-persistence tests.
3. Use positive, negative and boundary-value cases for validators,
   authentication helpers, cart calculations and coupons.
4. Define manual integration tests for Firebase, Firestore, Android UI and
   administrator workflows.
5. Record evidence with test steps, device, network state, expected result,
   actual result and status.
6. Run static analysis separately from functional tests so lint findings are
   not incorrectly reported as functional failures.

## 4. Types of Testing Used

| Testing type | Relevance to Cartify |
|---|---|
| Functional testing | Verifies login, catalogue, cart, checkout, orders, profiles and admin workflows. |
| Input validation testing | Required for name, email, password, phone, password confirmation, coupon and admin password inputs. |
| Positive testing | Confirms valid credentials, valid products, valid coupons and valid cart operations. |
| Negative testing | Confirms invalid credentials, duplicate accounts, invalid coupons, missing address and invalid OTP handling. |
| Boundary-value testing | Covers minimum password length, exact ten-digit phone length, empty cart, quantity changes and zero/flat discount limits. |
| Authentication testing | Required because the project integrates Firebase email/password, Google and phone authentication plus local fallback. |
| Authorization/security review | Required because administrator access and Firestore rules control protected operations; current implementation has prototype limitations. |
| Database/persistence testing | Required for Hive users, sessions, carts, products, orders, addresses, reviews, coupons, wishlist and settings. |
| API/cloud integration testing | Required for Firebase Authentication and Firestore catalogue/product operations. |
| UI/manual testing | Required for navigation, forms, Android rendering, admin tabs and user-visible error messages. |
| Error-handling testing | Required for Firebase failures, offline catalogue loading, invalid credentials, invalid coupons, missing addresses and failed product operations. |
| Static analysis | Used to identify maintainability and API-usage issues in the Dart code. |

Performance testing is relevant for startup, Firestore catalogue loading,
cached catalogue loading and local checkout completion, but no timing result is
claimed in this document because no measured timings were executed here.

## 5. Test Environment and Tools

| Item | Verified value |
|---|---|
| Flutter | 3.47.9 stable |
| Dart | 3.13.7 |
| DevTools | 2.60.0 |
| Test framework | Flutter `flutter_test` |
| Static analysis | `flutter analyze` |
| Primary IDE | Visual Studio Code |
| Development OS | CachyOS 7.3.4-1-cachyos Linux |
| Development CPU/RAM | Intel Core i7-14700HX, 16 GB RAM |
| Android test record | I2403, Android 16, device ID previously recorded as `10BF1D0UJ0005KQ` |
| Repository | https://github.com/N1VD55P/quickcart |

The current execution environment detected only the Linux desktop. Android
manual cases therefore remain unexecuted in this run unless a fresh device
session is recorded.

## 6. Detailed Test Cases

### 6.1 Executed automated test cases

The following cases are represented by `test/widget_test.dart` and
`test/local_persistence_test.dart`. The complete command `flutter test`
completed with **35 tests passed**.

| Test Case ID | Module | Test Scenario | Test Input / Preconditions | Test Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|---|
| TC-001 | Validation | Reject empty name | Empty string or whitespace | Call `Validators.validateName` | Returns a required-name error | Required-name error returned | Executed - PASS |
| TC-002 | Validation | Accept valid name | `Desh Kumar` | Call name validator | Returns null | Returned null | Executed - PASS |
| TC-003 | Validation | Reject empty email | Empty string | Call email validator | Returns required-email error | Required-email error returned | Executed - PASS |
| TC-004 | Validation | Reject malformed email | `notanemail`, `missing@domain`, `@nodomain.com` | Call email validator | Returns invalid-email error | Invalid-email errors returned | Executed - PASS |
| TC-005 | Validation | Accept and trim valid email | `  user@domain.com  ` | Call email validator | Returns null | Returned null | Executed - PASS |
| TC-006 | Validation | Reject empty password | Empty string | Call password validator | Returns required-password error | Required-password error returned | Executed - PASS |
| TC-007 | Validation | Reject short password | `123`, `abc` | Call password validator | Returns minimum-length error | Minimum-length errors returned | Executed - PASS |
| TC-008 | Validation | Accept six-character password boundary | `123456` | Call password validator | Returns null | Returned null | Executed - PASS |
| TC-009 | Validation | Reject invalid phone length/content | Empty, 3 digits, 11 digits and `98765abc10` | Call phone validator | Returns invalid-phone error | Invalid-phone errors returned | Executed - PASS |
| TC-010 | Validation | Accept ten-digit phone boundary | `9876543210` | Call phone validator | Returns null | Returned null | Executed - PASS |
| TC-011 | Password helper | Produce a non-empty hash | `mypassword` | Hash the password | Hash is non-empty | Non-empty hash produced | Executed - PASS |
| TC-012 | Password helper | Hash determinism | Same password twice | Hash `quickcart123` twice | Hashes are equal | Hashes matched | Executed - PASS |
| TC-013 | Password helper | Distinguish passwords | `password1`, `password2` | Hash both values | Hashes differ | Hashes differed | Executed - PASS |
| TC-014 | Password helper | Verify SHA-256 output length | `testpassword` | Hash password and check length | Length is 64 characters | Length was 64 | Executed - PASS |
| TC-015 | Password helper | Do not expose plaintext in hash | `mysecretpassword` | Check hash content | Plaintext is absent | Plaintext absent | Executed - PASS |
| TC-016 | Password confirmation | Reject empty confirmation | Password `password123`, empty confirmation | Run confirmation validator | Returns error | Error returned | Executed - PASS |
| TC-017 | Password confirmation | Reject mismatch | `password123` vs `wrongpassword` | Run confirmation validator | Returns mismatch error | Mismatch error returned | Executed - PASS |
| TC-018 | Password confirmation | Accept matching values | Same password in both fields | Run confirmation validator | Returns null | Returned null | Executed - PASS |
| TC-019 | Product pricing | Calculate discount percentage | 1299/2199, 599/999, 349/499 | Calculate rounded discount | 41%, 40%, 30% | Expected values returned | Executed - PASS |
| TC-020 | Product pricing | No discount at equal prices | 999/999 | Calculate discount | Returns 0% | Returned 0% | Executed - PASS |
| TC-021 | Cart calculation | Calculate one-item total | Price 1299, quantity 1 | Calculate total | Returns 1299 | Returned 1299 | Executed - PASS |
| TC-022 | Cart calculation | Calculate multi-item total | 1299×2 plus 599×1 | Calculate total | Returns 3197 | Returned 3197 | Executed - PASS |
| TC-023 | Cart calculation | Calculate empty-cart total | Empty list | Calculate total | Returns 0 | Returned 0 | Executed - PASS |
| TC-024 | Cart calculation | Calculate quantity total | 999×3 | Calculate total | Returns 2997 | Returned 2997 | Executed - PASS |
| TC-025 | Coupon calculation | Apply SAVE10 | Subtotal 1000 | Apply coupon | Discount is 100 | Returned 100 | Executed - PASS |
| TC-026 | Coupon calculation | Apply FLAT50 | Subtotal 1000 | Apply coupon | Discount is 50 | Returned 50 | Executed - PASS |
| TC-027 | Coupon calculation | Apply SAVE20 | Subtotal 500 | Apply coupon | Discount is 100 | Returned 100 | Executed - PASS |
| TC-028 | Coupon calculation | Reject invalid coupon | `INVALID`, subtotal 1000 | Apply coupon | Discount is 0 | Returned 0 | Executed - PASS |
| TC-029 | Local authentication | Hash password and persist session | Temporary Hive boxes and valid user | Sign up through `AuthService`, then log in | Signup succeeds, hash changes and current user is stored | All assertions passed | Executed - PASS |
| TC-030 | Local authentication | Reject duplicate email | Two users with same email | Sign up both users | First succeeds; second returns false | Duplicate rejected | Executed - PASS |
| TC-031 | User-scoped cart | Exclude another user's items from totals | Items for `a@example.com` and `b@example.com`; active user A | Read `CartProvider` totals | Only A's item is included | One item and total 100 observed | Executed - PASS |
| TC-032 | User-scoped cart | Increment active user's duplicate product | Active user A and fixture product | Add same product twice | One cart item with quantity 2 | Quantity became 2 | Executed - PASS |
| TC-033 | User-scoped cart | Clear only active user's cart | Items for users A and B | Call `clearCart` as A | A's item is deleted; B's remains | B's item remained | Executed - PASS |
| TC-034 | Profile persistence | Load and update active profile | Hive user and active session | Load profile, update name and phone | Provider and Hive record contain updates | Updated values observed | Executed - PASS |
| TC-035 | Theme persistence | Persist dark-mode selection | Empty settings box | Toggle theme | Provider and settings contain true | Dark mode persisted as true | Executed - PASS |

### 6.2 Proposed manual and integration test cases

These cases are specific to implemented workflows but were not executed in
the current headless run. Their status must remain **Not Executed** until the
team performs the steps on the configured Firebase project and Android phone.

| Test Case ID | Module | Test Scenario | Test Input / Preconditions | Test Steps | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|---|---|
| TC-036 | Firebase Authentication | Sign up and log in with Firebase email/password | Firebase Email/Password enabled; fresh test account | Use Signup, then Login with same credentials | Account is created and login reaches Home | Not Executed | Not Executed |
| TC-037 | Authentication fallback | Log in using local account when Firebase is unavailable | Existing local Hive account; disable network/Firebase failure | Enter valid local credentials | Local login succeeds and session is stored | Not Executed | Not Executed |
| TC-038 | Authentication error handling | Reject wrong Firebase/local password | Existing account and incorrect password | Submit login | User remains on login and sees invalid-credentials message | Not Executed | Not Executed |
| TC-039 | Google authentication | Complete Google sign-in | Google provider configured on Android device | Tap Google sign-in and select test account | User is saved locally and reaches Home | Not Executed | Not Executed |
| TC-040 | Phone authentication | Verify a valid OTP | Phone provider configured; test number available | Request OTP, enter received code | User is authenticated and reaches the app | Not Executed | Not Executed |
| TC-041 | Phone authentication | Reject invalid OTP | OTP request completed; incorrect code | Enter incorrect code | Invalid OTP error is displayed | Not Executed | Not Executed |
| TC-042 | Catalogue/Firestore | Load remote products | Firestore `products` collection contains valid documents | Launch app with network | Product cards appear and cache is refreshed | Not Executed | Not Executed |
| TC-043 | Catalogue fallback | Show cached catalogue offline | Previously loaded Hive cache; disable network | Launch/reload catalogue offline | Cached products remain visible; unavailable message only appears when no cache exists | Not Executed | Not Executed |
| TC-044 | Catalogue validation | Handle missing Firestore numeric fields | Product document missing price/originalPrice/stock | Load catalogue | Missing numeric values map to zero rather than crashing | Not Executed | Not Executed |
| TC-045 | Search and category | Search and filter catalogue | Products loaded | Search by name, description, category and select category | Matching products/categories are shown | Not Executed | Not Executed |
| TC-046 | Product details | Add product and submit review | Product loaded; authenticated user | Open detail, add cart item, submit review | Cart updates and review appears for current user/product | Not Executed | Not Executed |
| TC-047 | Wishlist | Add/remove and move wishlist item to cart | Product loaded; authenticated user | Toggle wishlist, remove item, move item to cart | Wishlist state changes and cart receives product | Not Executed | Not Executed |
| TC-048 | Cart | Update and remove cart quantities | Product in active cart | Increase, decrease to one, decrease again, remove | Totals update; quantity one deletion removes item | Not Executed | Not Executed |
| TC-049 | Checkout validation | Prevent checkout without address | Active cart and no address | Open checkout and place order | User sees address-required message; no order is written | Not Executed | Not Executed |
| TC-050 | Checkout/coupons | Apply valid and invalid coupons | Active cart subtotal | Try `SAVE10`, `FLAT50`, `SAVE20` and invalid code | Valid discount displays; invalid code is rejected | Not Executed | Not Executed |
| TC-051 | Checkout/orders | Place local order | Active cart and default address | Place order | Local order has ID, user, items, total, status `Placed`; cart clears | Not Executed | Not Executed |
| TC-052 | Orders | View and reorder an order | Existing local order and matching products | Open order history/detail and tap reorder | Correct order is shown and items return to cart | Not Executed | Not Executed |
| TC-053 | Profile/address | Manage default address | Authenticated user | Add, edit, set default and delete address | Address CRUD works and only one selected default is used by checkout | Not Executed | Not Executed |
| TC-054 | Profile/security | Change password | Existing local user | Try wrong current password, then valid current/new matching password | Wrong password rejected; valid change persists | Not Executed | Not Executed |
| TC-055 | Account deletion | Delete account after confirmation | Existing local user with related records | Enter wrong password, then correct password and confirm | Wrong password rejected; correct deletion removes user's records and returns to login | Not Executed | Not Executed |
| TC-056 | Admin authentication | Accept and reject admin password | Admin login screen | Try incorrect password, then `ADMIN123` in prototype environment | Wrong input shows error; correct input opens AdminHomeScreen | Not Executed | Not Executed |
| TC-057 | Admin navigation | Visit all seven tabs | Successful admin login | Tap Dashboard, Products, Orders, Users, Inventory, Reviews, Coupons | Each tab renders its corresponding screen | Not Executed | Not Executed |
| TC-058 | Admin products | Create, update and delete Firestore product | Firestore configured; admin panel open | Submit product form, edit it, delete with confirmation | Firestore reflects create/update/delete and errors are shown on failure | Not Executed | Not Executed |
| TC-059 | Admin inventory | Update stock | Existing Firestore product | Change stock and confirm | Firestore stock changes and inventory UI refreshes | Not Executed | Not Executed |
| TC-060 | Admin local records | Manage users, orders, reviews and coupons | Local Hive records available | Use each corresponding tab's supported actions | Supported records display and delete/update actions behave as implemented | Not Executed | Not Executed |
| TC-061 | UI/theme | Persist light/dark theme through restart | App settings available | Toggle theme, close/reopen app | Selected theme remains active | Not Executed | Not Executed |
| TC-062 | Android/device | Verify Android rendering and navigation | I2403 Android 16 device; debug/release APK | Install, launch, rotate/scroll through core screens | No blocking layout/crash issue occurs in tested flows | Not Executed | Not Executed |
| TC-063 | Performance | Measure startup and catalogue timings | Android device and fixed network state | Repeat cold startup, first catalogue load and cached load three times | Timings are recorded without claiming an unsupported threshold | Not Executed | Not Executed |
| TC-064 | Security review | Review authentication, admin and Firestore controls | Source and Firebase Console access | Inspect providers, rules, client admin password and repository secret scan | Findings and limitations are recorded; no secret values are attached | Not Executed | Not Executed |

## 7. Test Execution Results

### Automated execution

Command executed:

```bash
flutter test
```

Result: **35 tests passed** across `test/widget_test.dart` and
`test/local_persistence_test.dart`.

The automated suite verifies validation, password hashing, confirmation
logic, discount calculations, cart calculations, coupon calculations, local
authentication, duplicate-email handling, user-scoped cart persistence,
profile updates and theme persistence. It does not exercise Firebase,
Firestore, Android rendering or full widget navigation.

### Static analysis

Command executed:

```bash
flutter analyze
```

Result: analysis completed with **29 informational/warning findings** and
exit code 1. Findings include the non-standard
`Product_Provider.dart` filename, deprecated form-field APIs, unnecessary
underscore parameters, missing braces in some control statements and one
unused `_imageLoaded` field. These are reported as code-quality findings, not
functional test passes.

### Manual/integration execution

The manual cases TC-036 to TC-064 were not executed in the current run because
the environment had no connected Android phone and Firebase Console/device
interaction was not available. The project evidence folder contains templates
for recording these tests without fabricating results.

## 8. Summary of Testing

The deterministic application logic and local persistence layer have a
verified baseline: all 35 automated tests passed. The strongest verified
areas are validation, hashing behaviour, cart calculations, local account
session persistence, user-scoped cart behaviour, profile persistence and
theme persistence.

The most important unverified areas are Firebase provider configuration,
Firestore catalogue/product operations, Android UI flows, Google/phone
authentication, administrator workflows, performance timings and the
security posture of deployed Firestore rules. These require the manual test
cases and evidence records listed above.

## 9. Limitations and Future Testing Scope

- Add widget tests for login, signup, checkout, order success and admin
  navigation.
- Add integration tests using Firebase emulators for Authentication and
  Firestore rather than relying only on a live project.
- Replace unrestricted Firestore rules before security sign-off and test
  unauthorised reads/writes.
- Replace client-side admin password authentication with server-side roles or
  Firebase custom claims, then add authorization tests.
- Add tests for Firestore errors, malformed product documents and empty
  catalogue responses.
- Add tests for user-scoped wishlist behaviour; the current implementation
  clears the shared wishlist during account deletion.
- Measure performance on the stated Android device using repeated timed runs.
- Re-run static analysis after resolving the 29 reported findings.
- Add CI execution of `flutter test` and `flutter analyze` for each GitHub
  change.
