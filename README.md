# Shopping — Price Filter + Pagination (Supabase)

A Flutter shop backed by a Supabase `products` table. Customers narrow the list with a **price range slider** and **category chips**, and browse **6 products per page**. Products can also be added, edited, and deleted. Every filter and page change is a **Supabase query**, and a **Cubit (`flutter_bloc`)** manages the state.

The Pokédex midterm is still on the `midterm-exam` branch.

## Setup

1. **Create the table.** In the Supabase dashboard, open **SQL Editor → New query**, paste all of [`supabase/schema.sql`](supabase/schema.sql), and click **Run**. It creates the `products` table, its RLS policies, a price index, and 24 sample products. Running it again is safe.
2. **Add your keys.** Copy `supabase.example.json` to `supabase.json` (git ignores it) and fill in the **Project URL** and **publishable / anon key** shown by the dashboard's **Connect** button. Never put the secret or `service_role` key in the app.
3. **Run.** In VS Code, press **F5**; the "Shop (Supabase)" launch configuration passes `supabase.json` for you. From a terminal:

   ```sh
   flutter pub get
   flutter run --dart-define-from-file=supabase.json
   ```

   Without keys, the app opens a "Connect to Supabase" screen that lists these steps.

Building for **Windows desktop** requires Windows Developer Mode (`start ms-settings:developers`), because `supabase_flutter` uses plugins. Chrome, Edge, and Android don't need it.

## Activity requirements

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

`user action → ShopCubit method → Supabase query → emit(new ShopState) → BlocBuilder → updated UI`

- Moving the slider or picking a category starts again at page 1. The slider queries once, when the thumb is released.
- When the slider covers every price, no price filter is sent, so a new product above the old maximum still appears.
- Products are sorted by price, then by `id`, so equal prices never put a product on two pages.
- If the current page disappears, such as after deleting the only product on the last page, the shop shows the new last page. Supabase answers a page past the end with HTTP 416 (`PGRST103`); the repository then counts the matches instead.
- After an add, edit, or delete, the slider limits and categories reload. A slider that covered every price grows or shrinks with the new prices; a narrowed one keeps its selection.
- If a slow response arrives after a newer request, it is ignored, so quick page clicks can't show the wrong page.
- RLS doesn't raise an error when it blocks an update or delete; it just changes 0 rows. The repository checks for that and shows a message.

## Code guide

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Connects to Supabase and provides `ShopCubit` to the app |
| `lib/config/supabase_config.dart` | Reads the URL and key passed with `--dart-define-from-file` |
| `lib/models/product.dart` | `Product`, `ProductDraft`, `PriceRange`, and `ProductPage` |
| `lib/data/product_repository.dart` | The interface the Cubit uses, and its error type |
| `lib/data/supabase_product_repository.dart` | Every Supabase query, and readable error messages |
| `lib/state/shop_state.dart` | Immutable state: current page, totals, slider range, category |
| `lib/state/shop_cubit.dart` | Loading, paging, filtering, and add/edit/delete |
| `lib/screens/shop_screen.dart` | Layout, dialogs, and loading, empty, and error states |
| `lib/screens/setup_required_screen.dart` | Shown when the Supabase keys are missing |
| `lib/widgets/` | Price slider, category chips, pagination bar, product card, and product form |
| `supabase/schema.sql` | Table, RLS policies, index, and sample data |

## Tests

```sh
flutter analyze
flutter test
```

The tests use an in-memory copy of the 24 sample products, so they run without Supabase:

- **Cubit:** paging, price and category filters, moving back a page after a delete, slider limits after edits, errors and retry, and out-of-order responses.
- **Supabase repository:** the real Supabase client with a mocked HTTP layer, checking the exact query parameters sent, the HTTP 416 fallback, and the RLS, missing-table, API-key, and offline messages.
- **Widgets:** paging, dragging the slider, category chips, the add/edit/delete dialogs, form validation, retry, and the setup screen.
