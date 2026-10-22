# Pokédex — Midterm Exam

A Flutter Pokédex using **BLoC through `flutter_bloc` and Cubit** as its single application state management approach. It extends the existing PokéAPI project and its list of the first 30 Pokémon.

## Run

```sh
flutter pub get
flutter run
```

Choose a connected Android device/emulator or an available desktop/browser target. For a browser on Windows:

```sh
flutter run -d edge
```

Internet access is required for Pokémon data and artwork. The first request also loads Pokémon details for real type data. Subsequent refreshes fetch the list again and reuse the details cached in memory.

## Exam features

| Requirement | Implementation |
| --- | --- |
| Async Pokémon loading, loading/success/error states | `PokedexCubit.fetch()` and `PokedexStatus`; the home page renders the current status |
| Refresh using the existing fetch method | Both the AppBar button and pull-to-refresh call `cubit.fetch`; retry also uses it |
| Add, edit, remove a nickname | Nickname dialog calls `saveNickname` or `removeNickname`; original names stay visible |
| Expand/collapse favorites panel | `FavoritesPanel` is always accessible above the grid, including during filtering, loading, and errors |
| Immediate favorite updates and heart indicators | Cards and the panel read the same `favoriteUrls` set; `toggleFavorite` emits updated state |
| Filter by actual Pokémon types and clear the filter | Detail responses supply `types`; dropdown includes loaded types and an All types option |
| Empty/error handling and resource cleanup | Empty list/panel/filter messages, retry action, HTTP timeouts, controller disposal and Cubit/service cleanup |

Favorites and nicknames survive refresh and type changes within the current app session. They reset after restarting the application; disk persistence is not implemented. The type filter applies to the loaded first 30 Pokémon, including both types of dual-type Pokémon.

The favorites panel starts collapsed. Tap its header to expand or collapse it. Opening the panel keeps the main grid visible, and the panel displays all favorites independently of the type filter.

## Code guide

| File | Responsibility |
| --- | --- |
| `lib/main.dart` | Creates the app-wide Cubit with `BlocProvider` and starts fetching |
| `lib/models/pokemon.dart` | Pokémon identity, names, artwork URLs, and actual type data |
| `lib/services/pokemon_service.dart` | HTTP requests, JSON parsing, detail cache, and meaningful API errors |
| `lib/state/pokedex_state.dart` | Immutable state plus derived favorites, visible list, and available types |
| `lib/state/pokedex_cubit.dart` | Fetching lifecycle and all nickname/favorite/filter/panel actions |
| `lib/screens/pokedex_list_screen.dart` | Home page, loading/error/empty views, refresh, and type selector |
| `lib/widgets/pokemon_grid.dart` | Responsive card grid |
| `lib/widgets/pokemon_card.dart` | Image, original name, nickname, types, favorite heart, and editor action |
| `lib/widgets/favorites_panel.dart` | Collapsible favorites using compact versions of the full Pokémon card, with artwork, names, types, nickname editing, and removal |
| `lib/widgets/nickname_editor.dart` | Dialog input and controller lifecycle |

The update flow is `user action → Cubit method → emit(new state) → BlocBuilder → updated UI`. The service handles network details while the Cubit owns when to fetch and what the UI should display. There is no direct `provider` or Riverpod application implementation. `provider` may appear in the lockfile because `flutter_bloc` uses it internally.

## Validate

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

Validation completed with no analyzer issues, all 12 tests passing, and successful web and Android debug builds. A browser preview also loaded all 30 Pokémon with artwork from the live API. The Android APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

The tests cover shared state across refresh and filtering, dual-type filtering, loading and request deduplication, failure/retry, safe disposal, actual type parsing, cache reuse, empty results, and the complete nickname/favorite/filter widget interaction. HTTP responses are mocked for deterministic tests; artwork uses a fallback when unavailable.

## Presentation and submission

Use [VIDEO_PRESENTATION_SCRIPT.md](VIDEO_PRESENTATION_SCRIPT.md) for a timed speaking script and screen actions. It covers the three video topics from the supplied exam PDF and targets approximately 12 minutes, below the 15-minute limit.

The local branch is `midterm-exam`. After reviewing the files and replacing the presentation's name placeholder, commit and push your work:

```sh
git status
git add README.md VIDEO_PRESENTATION_SCRIPT.md lib test pubspec.yaml pubspec.lock android/.gitignore android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements web/index.html web/manifest.json
git commit -m "Implement Pokedex midterm features with BLoC"
git push -u origin midterm-exam
```

Then submit the repository/branch link and your recorded video using your class submission instructions. The exam PDF lists **October 22, 2026, at 11:59 PM** as the deadline; follow your instructor's timezone and any updated announcement.

## References

- [flutter_bloc package documentation](https://pub.dev/packages/flutter_bloc)
- [BLoC documentation](https://bloclibrary.dev/)
- [PokéAPI Pokémon API documentation](https://pokeapi.co/docs/v2#pokemon)
