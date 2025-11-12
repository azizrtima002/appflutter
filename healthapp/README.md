# Healthcare Billing & Payments (Flutter + SQLite)

Offline-first billing module for clinics with invoices, payments, PDF, and Stripe (PaymentSheet) integration.

## Stack
- Flutter (Material 3, Riverpod, GoRouter)
- SQLite (`sqflite` + migrations)
- PDF (`pdf`, `printing`, `barcode_widget`)
- Stripe (`flutter_stripe` with mock server)

## Run App
1. Flutter: ensure SDK 3.2+ installed
2. Pub get: `flutter pub get`
3. Android: run `flutter run`

## Stripe & Payments
1. Install and start the mock backend:  
   ```
   cd server/mock
   npm install
   npm start
   ```
   By default it listens on `http://localhost:4242`. Android emulators should use `http://10.0.2.2:4242`.
2. Pass your publishable key/backend URL (and optional merchant id / URL scheme) to Flutter at run time so `StripeService` can pick them up:
   ```
   flutter run \
     --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
     --dart-define=STRIPE_BACKEND_URL=http://10.0.2.2:4242 \
     --dart-define=STRIPE_MERCHANT_ID=merchant.com.health.billing \
     --dart-define=STRIPE_URL_SCHEME=flutterstripe
   ```
   Replace with your live values when needed. If the PaymentSheet fails, the app opens the `qrPayUrl` fallback and the error message is surfaced in the UI.
3. Seeing `Cannot GET /` in the browser is normal: the mock only exposes `POST /create-payment-intent`. We now return a friendly message when you hit the root URL.
4. Android-specific: The `flutter_stripe` plugin requires your launcher Activity to extend `FlutterFragmentActivity`. This project already does (`android/app/src/main/kotlin/.../MainActivity.kt`), but if you rename packages make sure the new activity extends `FlutterFragmentActivity` too.

## PDF Printing
- The invoice PDF uses only vector widgets, so there is no longer an embedded PNG (fixes `Invalid IDAT checksum`).
- Printing/sharing relies on the `printing` plugin. On a simulator, pick “Share” to preview; on Android ensure Google Cloud Print/Default Print Service is enabled.

## Features
- Invoices: create, update, cancel; list with filters
- Payments: add/update status/soft delete; auto recalculation of `amount_due`
- PDF: generate A4 with logo, patient, lines, totals, QR; print/share
- Stripe: PaymentSheet; fallback to Payment Link
- Offline-first except Stripe; `needs_sync` flags
- Export/Import JSON (placeholder actions in Settings)

## Structure
See `lib/` with `core`, `domain`, `data`, `features`.

## Tests
- Domain unit tests under `test/domain/usecases/`
- Use fakes (no SQLite) to validate business rules

## Notes
- Every `patients.id` is the primary key (see `lib/data/migrations/v1.sql`), so creating a duplicate ID will fail fast.
- Invoices can now be cancelled **or** permanently deleted from the detail screen menu; deletion wipes associated line items and payments.
- Default currency TND; option for EUR
- Accessibility and Material 3 themed
- No storage of medical/clinical data (billing only)
