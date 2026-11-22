# Orange Essentials — E-Commerce App (Final Exam)

A Flutter shop for everyday essentials with two roles. **Admins** manage products, categories, and orders. **Customers** browse, fill a cart, check out, and review their orders.

| Area | Used here |
| --- | --- |
| State management | Riverpod (`flutter_riverpod`) |
| Backend | Supabase Auth, Postgres, and Row Level Security |
| Sign-in | Email and password, plus Google |
| Images | Supabase Storage |

## Setup

1. **Create the backend.** In Supabase, open **SQL Editor → New query**, paste all of [`supabase/final_exam.sql`](supabase/final_exam.sql), and click **Run**. It creates every table, function, trigger, policy, and the image bucket, and adds 24 sample products to an empty shop. It also upgrades the `products` table from the earlier activities without losing rows. Running it again is safe.

   The final exam's rules block signed-out visitors, so the apps of the earlier activities stop working with the same Supabase project. Use a new project to keep them working.
2. **Turn on Google sign-in.** See [Google sign-in](#google-sign-in).
3. **Add your keys.** Copy `supabase.example.json` to `supabase.json` (git ignores it) and fill in the **Project URL** and **publishable key** from the dashboard's **Connect** button. Never use the secret or `service_role` key in an app.
4. **Run the app.** In VS Code, choose Chrome, Edge, or an Android device and press **F5**. From a terminal:

   ```sh
   flutter pub get
   flutter run -d chrome --web-port=3000 --dart-define-from-file=supabase.json
   ```

5. **Make an admin.** Every account starts as a customer. Sign up in the app, put that email into [`supabase/make_admin.sql`](supabase/make_admin.sql), run it in the SQL Editor, then sign out and in again.

### Google sign-in

1. In Supabase, open **Authentication → Sign In / Providers → Google** and copy the **Callback URL**.
2. In the [Google Cloud console](https://console.cloud.google.com/auth/overview), create or choose a project and open **Google Auth Platform**:
   - **Branding:** fill in the app name and your email.
   - **Audience:** choose **External**.
   - **Data Access:** the scopes `openid`, `userinfo.email`, and `userinfo.profile` are enough.
   - **Clients → Create client → Web application:** add `http://localhost:3000` under **Authorized JavaScript origins**, and the Callback URL from step 1 under **Authorized redirect URIs**.
3. Copy the client's **Client ID** and **Client secret** into the Google page in Supabase, turn the provider on, and **Save**.
4. In Supabase, open **Authentication → URL Configuration**. Set the **Site URL** to `http://localhost:3000`, and add `http://localhost:3000/**` and `io.supabase.shopping://login-callback/` to the **Redirect URLs**.
5. Optional, for testing email sign-up: turn off **Confirm email** under **Authentication → Sign In / Providers → Email**.

Google sign-in works on the web (port 3000) and on Android and iOS, which come back through the `io.supabase.shopping://` link. The Windows desktop app shows the Google button turned off; email works everywhere.

| What you see | Fix |
| --- | --- |
| `Unsupported provider: provider is not enabled` | Turn on Google in Supabase (step 3) and save |
| Google says `redirect_uri_mismatch` | The redirect URI in Google must equal Supabase's Callback URL exactly (step 2) |
| After Google, a page that doesn't load | Run the app on port 3000 and check step 4 |
| "The database is not set up yet" | Run `final_exam.sql` |
| "No profile found" | Run `final_exam.sql`; it also creates profiles for accounts that already exist |

## Requirements

### Authentication, profiles, and the auth gate

| Requirement | Where |
| --- | --- |
| Email and password, plus Google | `AuthService`, `LoginPage`, `SignUpPage` |
| Profile creation | The `handle_new_user()` function and the `on_auth_user_created` trigger. Every account becomes a customer, whatever the app sends |
| Session in sync with the UI | `sessionProvider` follows `onAuthStateChange`. `AuthGate` shows login, the customer's app, or the admin's app, and pages opened on top close when the session ends |

### Admin

| Requirement | Where |
| --- | --- |
| Floating button that opens the Add Product form; Edit and Delete on every card | `AdminProductsPage` |
| Name, description, price, stock, category, image; edit form filled in with current values | `ProductFormPage` |
| Validation: name required, price a number of zero or more, stock a whole number of zero or more | `Validators`, and check constraints in the database |
| Delete only after a dialog that names the product | `AdminProductsPage` |
| Category management | `AdminCategoriesPage` |
| Order list with statuses | `AdminOrdersPage` |

### Customer

| Requirement | Where |
| --- | --- |
| Browse, search, category chips, price slider, 6 products per page | `CatalogView`; every choice is one Supabase query |
| Add to cart instead of management buttons | `ShopPage` |
| Change quantity, remove, running total, item count, never above the stock | `CartPage`, `cartProvider` |
| Cart survives screen changes, and empties after an order and on logout | `cartProvider` |
| Checkout, saved with the status done, then a confirmation with order number and total | `checkoutProvider`, `OrderConfirmationPage` |
| Own orders only, newest first, with status, date, total, and items | `OrderHistoryPage` |

Loading, empty, error, and permission-denied states are shared by every page through `AsyncView` and `ErrorView`.

## Security

### Why hiding a button is not security

Customers never see Add, Edit, or Delete, but that only shapes the interface. The app's publishable key is inside the app, and anyone who signs in gets a token. With those two, a customer can skip the app and send requests straight to the Supabase API, for example to set every price to 0. The app's code can't stop a request it never sees.

Row Level Security runs inside Postgres, on every request, no matter who or what sent it. `is_admin()` looks up the caller's role in the database, so a customer's edit changes nothing even if the buttons were shown. The interface and the policies follow the same rules, but only the policies enforce them.

| Table | Signed out | Customer | Admin |
| --- | --- | --- | --- |
| `profiles` | No access | Read and update own row, never the role | Read all |
| `roles` | No access | Read | Read |
| `categories` | No access | Read | Read, add, edit, delete |
| `products` | No access | Read | Read, add, edit, delete |
| `orders` | No access | Read own | Read all, update status |
| `order_items` | No access | Read items of own orders | Read all |

Two layers protect these rules. Privileges decide which columns can be written at all: through the API, nobody can write `profiles.role_id` or `orders.total`. Policies decide which rows. Only admins can upload or delete product images; viewing an image by its link is public, because product pictures aren't private.

### Checkout integrity

The app sends only product ids and quantities to the `place_order()` function:

```dart
supabase.rpc('place_order', params: {
  'items': [{'product_id': 3, 'quantity': 2}],
});
```

- **All or nothing.** A function runs in one transaction. If any item fails, the order, its items, and the stock changes are all undone.
- **Database values only.** Names, prices, and stock are read from `products` at that moment. Anything else in the request is ignored.
- **No overselling.** Products are locked (`for update`) while they are checked and reduced, so two checkouts can't sell the same stock.
- **Snapshots.** `order_items` keeps the name and price that were paid, even if the product later changes or is deleted.
- **No way around it.** Nobody has permission to insert into `orders` or `order_items` directly.

## Database

```text
auth.users 1───1 profiles *───1 roles
                    1
                    │
                    *
                 orders 1───* order_items *───0..1 products *───1 categories
```

| Function | Purpose |
| --- | --- |
| `handle_new_user()` | Trigger on `auth.users`: creates the customer profile |
| `is_admin()` | Used by the policies to check the caller's role |
| `my_role_id()` | Used by the profiles policy so nobody changes their own role |
| `place_order(items)` | Checkout, in one transaction |

## Code structure

Pages watch providers, providers call services, and only services talk to Supabase.

| Folder | Contents |
| --- | --- |
| `lib/models/` | Plain data classes |
| `lib/services/` | All Supabase requests; `supabase_guard.dart` turns errors into readable messages |
| `lib/providers/` | Riverpod providers: session and role, catalog, cart, checkout, orders, admin actions |
| `lib/pages/` | Screens, grouped into `auth`, `customer`, and `admin` |
| `lib/widgets/` | Shared parts, such as the catalog, filters, cards, and error views |
| `lib/theme/` | Colors, typography (Plus Jakarta Sans), and component styles, light and dark |
| `lib/utils/`, `lib/config/` | Formatting, form checks, and configuration |
| `supabase/` | The backend script and the script that makes an admin |

## Tests

```sh
flutter analyze
flutter test
```

168 tests run without a Supabase project. They cover sign-in and roles, the cart and checkout, filters and paging, admin actions, every page on desktop and phone sizes, and the exact requests sent by the real Supabase client. The in-memory backend follows the same role rules as the policies, so the tests also check what happens when a request is refused.

The font [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) is included under the SIL Open Font License (`assets/fonts/PlusJakartaSans-OFL.txt`).
