# Shopping — Supabase shop with GitHub sign-in

A Flutter shop backed by Supabase. People sign in with **email and password** or with **GitHub**. Once signed in, they can filter products with a **price range slider** and **category chips**, browse **6 products per page**, and add, edit, or delete products. Every filter and page change is a **Supabase query**, and **Cubits (`flutter_bloc`)** manage the state.

The Pokédex midterm is still on the `midterm-exam` branch.

## Setup

1. **Create the table.** In the Supabase dashboard, open **SQL Editor → New query**, paste all of [`supabase/schema.sql`](supabase/schema.sql), and click **Run**. It creates the `products` table, its RLS policies, a price index, and 24 sample products.
2. **Only signed-in users can change products (recommended).** Run [`supabase/auth.sql`](supabase/auth.sql) the same way. Anyone can still view products. Both scripts are safe to run again.
3. **Turn on GitHub sign-in.** Follow [GitHub sign-in setup](#github-sign-in-setup) below.
4. **Add your keys.** Copy `supabase.example.json` to `supabase.json` (git ignores it) and fill in the **Project URL** and **publishable / anon key** shown by the dashboard's **Connect** button. Never put the secret or `service_role` key in the app.
5. **Run in Chrome or Edge.** In VS Code, pick Chrome or Edge as the device and press **F5**. The "Shop (Supabase)" launch configuration passes `supabase.json` and uses port 3000, which is where Supabase sends you back after GitHub. From a terminal:

   ```sh
   flutter pub get
   flutter run -d chrome --web-port=3000 --dart-define-from-file=supabase.json
   ```

   Without keys, the app opens a "Connect to Supabase" screen that lists these steps.

GitHub sign-in works on **web** and on **Android and iOS**, which return to the app through the `io.supabase.shopping://login-callback/` link. The **Windows desktop** app shows the GitHub button turned off; use email there. Building for Windows desktop also requires Windows Developer Mode (`start ms-settings:developers`).

## GitHub sign-in setup

1. **Copy the callback URL from Supabase.** Open **Authentication → Sign In / Providers → GitHub**. The page shows a **Callback URL**, which looks like `https://<project-ref>.supabase.co/auth/v1/callback`.
2. **Create a GitHub OAuth App.** On GitHub, open **Settings → Developer settings → OAuth Apps → New OAuth App** and enter:
   - **Application name:** Shopping (any name works)
   - **Homepage URL:** `http://localhost:3000`
   - **Authorization callback URL:** the Callback URL from step 1

   Click **Register application**, copy the **Client ID**, then click **Generate a new client secret** and copy the secret.
3. **Turn the provider on in Supabase.** Back on the GitHub provider page, switch on **Enable Sign in with GitHub**, paste the Client ID and the Client Secret, and click **Save**.
4. **Allow the app's return addresses.** Open **Authentication → URL Configuration**:
   - **Site URL:** `http://localhost:3000`
   - **Redirect URLs:** add `http://localhost:3000/**` and `io.supabase.shopping://login-callback/`
5. **Optional, for testing email sign-up:** in **Authentication → Sign In / Providers → Email**, turn off **Confirm email**. New email accounts can then sign in right away instead of waiting for a confirmation email.

To check it worked, sign in with GitHub, then open **Authentication → Users** in Supabase. Your account is listed with GitHub as its provider.

### If something goes wrong

| What you see | Fix |
| --- | --- |
| A page with `Unsupported provider: provider is not enabled` | GitHub isn't switched on in Supabase (step 3), or it wasn't saved |
| GitHub says `The redirect_uri is not associated with this application` | The OAuth App's callback URL must match Supabase's Callback URL exactly (step 2) |
| After GitHub, the browser opens a page that doesn't load | The app isn't running on port 3000, or the URL Configuration from step 4 is missing |
| "Confirm your email first" after creating an email account | Click the link Supabase emailed you, or turn off **Confirm email** (step 5) |

## Activity requirements

### Other Provider Authentication

| Requirement | Implementation |
| --- | --- |
| Select 1 additional 3rd-party provider | **GitHub**, using Supabase's GitHub provider and a GitHub OAuth App |
| Integrate it as an additional authentication option for users | The sign-in screen keeps **email and password** and adds **Continue with GitHub**, which calls `supabase.auth.signInWithOAuth(OAuthProvider.github, redirectTo: ...)` |
| Works for the app's users | Supabase returns to the app with a sign-in code, `supabase_flutter` exchanges it for a session, and the shop opens. The account menu shows the GitHub name, the email, "Signed in with GitHub", and **Sign out** |

### Price Filter + Pagination

| Requirement | Implementation |
| --- | --- |
| Price slider that filters the products | `PriceFilter` is a `RangeSlider` from the cheapest to the priciest product. On release, it calls `ShopCubit.setPriceRange`, which queries `.gte('price', min).lte('price', max)` |
| 6–8 products per page | `ShopState.pageSize = 6` (2×3 on phones, 3×2 on tablets, 6×1 on desktops) |
| Pagination done with a Supabase query | `.range(from, to)` fetches only the current page; `.count(CountOption.exact)` returns the total number of matches, which gives the page count |
| Handled through a state management solution | `ShopCubit` emits a loading state, runs one query, and emits the new page; `BlocBuilder` redraws the screen |
| Update, delete, and filter (from class) | Edit and delete buttons on each card use `.update(...).eq('id', id)` and `.delete().eq('id', id)`; the category chips use `.eq('category', name)`; **Add product** uses `.insert(...)` |

For example, page 2 of the products priced $40–$130 is this query:

```dart
supabase
    .from('products')
    .select()
    .gte('price', 40)
    .lte('price', 130)
    .order('price', ascending: true)
    .order('id', ascending: true)
    .range(6, 11) // rows 7–12; range() includes both ends
    .count(CountOption.exact);
```

## How it works

### Sign-in

`Continue with GitHub → GitHub approves → Supabase → back to the app with a code → session → AuthCubit → AuthGate shows the shop`

- `AuthCubit` follows `supabase.auth.onAuthStateChange`, so the shop opens no matter how the session arrived: the email form, or the browser coming back from GitHub.
- Supabase saves the session, so reopening the app stays signed in until **Sign out**.
- A wrong password, an unconfirmed email, or pressing Cancel on GitHub shows a message on the sign-in screen.
- With `auth.sql`, adding, editing, and deleting need a signed-in user (the `authenticated` role in RLS). Reading stays open.

### Shop

`user action → ShopCubit method → Supabase query → emit(new ShopState) → BlocBuilder → updated UI`

- Moving the slider or picking a category starts again at page 1. The slider queries once, when the thumb is released.
- When the slider covers every price, no price filter is sent, so a new product above the old maximum still appears.
- Products are sorted by price, then by `id`, so equal prices never put a product on two pages.
- If the current page disappears, such as after deleting the only product on the last page, the shop shows the new last page. Supabase answers a page past the end with HTTP 416 (`PGRST103`); the repository then counts the matches instead.
- After an add, edit, or delete, the slider limits and categories reload.
- If a slow response arrives after a newer request, it is ignored, so quick page clicks can't show the wrong page.
- RLS doesn't raise an error when it blocks an update or delete; it just changes 0 rows. The repository checks for that and shows a message.

## Code guide

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Connects to Supabase and provides `AuthCubit` to the app |
| `lib/config/supabase_config.dart` | The URL and key passed with `--dart-define-from-file`, and the mobile return link |
| `lib/models/app_user.dart` | The signed-in person: name, email, picture, and provider |
| `lib/data/auth_repository.dart` | The sign-in interface `AuthCubit` uses |
| `lib/data/supabase_auth_repository.dart` | Email and GitHub sign-in with Supabase Auth, and readable error messages |
| `lib/state/auth_state.dart`, `auth_cubit.dart` | Who is signed in, which button is busy, and messages |
| `lib/screens/auth_gate.dart` | Shows the sign-in screen or the shop |
| `lib/screens/sign_in_screen.dart` | Email and password form, plus **Continue with GitHub** |
| `lib/widgets/account_button.dart` | Profile picture, account details, and **Sign out** |
| `lib/models/product.dart` | `Product`, `ProductDraft`, `PriceRange`, and `ProductPage` |
| `lib/data/supabase_product_repository.dart` | Every products query, and readable error messages |
| `lib/state/shop_state.dart`, `shop_cubit.dart` | Paging, filters, and add/edit/delete |
| `lib/screens/shop_screen.dart` | Layout, dialogs, and loading, empty, and error states |
| `lib/widgets/` | Price slider, category chips, pagination bar, product card, and product form |
| `supabase/schema.sql` | Table, RLS policies, index, and sample data |
| `supabase/auth.sql` | Limits adding, editing, and deleting to signed-in users |
| `android/.../AndroidManifest.xml`, `ios/Runner/Info.plist` | Register the `io.supabase.shopping://` return link |

## Tests

```sh
flutter analyze
flutter test
```

The tests use in-memory fakes, so they run without Supabase or GitHub:

- **Sign-in:** the email form, wrong passwords, email confirmation, GitHub sign-in finishing when the browser returns, a cancelled GitHub sign-in, a saved session, sign-out, and the turned-off GitHub button on desktop.
- **Supabase Auth:** the real Supabase client with a mocked HTTP layer, checking the password sign-in request, the sign-up return link, an email that already has an account, sign-out, offline errors, and the GitHub sign-in URL and its return link.
- **Shop:** paging, price and category filters, add/edit/delete, errors and retry, and the exact products queries sent to Supabase.
