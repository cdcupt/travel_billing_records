# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
swift build                               # Build TravelBillingCore library
swift test                                # Run all tests
swift test --filter ClassificationTests  # Run a single test class
swift test --filter testRuleBasedClassifier  # Run a single test method
```

For the app targets, open in Xcode:
- `apps/ios/TravelBillingiOS/TravelBillingiOS.xcodeproj`
- `apps/macos/TravelBillingMac/TravelBillingMac.xcodeproj`

## Architecture

### TravelBillingCore (SwiftPM library)

Platform-independent logic in `Sources/TravelBillingCore/`:

- **`Models.swift`** — `Trip`, `Bill`, `BillCategory` (transport/accommodation/food/shopping/entertainment/tickets/tips/misc), `BillSourceType`, `ParticipantShare`
- **`Classification.swift`** — `RuleBasedClassifier` maps Chinese keywords to categories; `SimpleTextImporter` extracts amount (regex) and date from free text; `ImportedBillCandidate` is the intermediate result
- **`Statistics.swift`** — `Statistics.summarizeByCategory(for:)` and `Statistics.summarizeDaily(for:)` produce `CategorySummary` / `DailySummary`

Tests are in `Tests/TravelBillingCoreTests/ClassificationTests.swift` and cover classification, text import, and statistics.

### App targets (iOS & macOS)

Each Xcode project duplicates the core logic under its own `Core/` folder (Models, Classification, Statistics) — these files are **not** linked to the SwiftPM library. When modifying shared logic, check both `Sources/TravelBillingCore/` and the app `Core/` copies.

**Persistence** (`Persistence.swift`) uses Core Data with a programmatically built `NSManagedObjectModel` — there is no `.xcdatamodeld` file. `participants` and `tags` are stored as JSON-encoded `Data` blobs. `shouldMigrateStoreAutomatically` is enabled.

**Input pipeline:**
```
text/voice(Speech STT)/image(Vision OCR)
  → SimpleTextImporter → RuleBasedClassifier → Bill → Trip
```

**iOS-only views:** `TripsListView` → `TripDetailView` → `AddBillView` / `AnalyticsView` (Swift Charts). The macOS app has the same view structure minus camera/voice input.

## Key Details

- Default currency is CNY; `Trip` has an `exchangeRate: Double` field for future conversion.
- `SimpleTextImporter.extractDate` is a placeholder — it always returns `Date()`.
- `Bill.amount` is `Decimal`; Core Data stores it as `Double` (converted via `NSDecimalNumber`).
