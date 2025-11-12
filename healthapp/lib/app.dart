import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dashboard/pages/dashboard_page.dart';
import 'features/invoices/pages/invoice_list_page.dart';
import 'features/invoices/pages/invoice_detail_page.dart';
import 'features/invoices/pages/invoice_form_page.dart';
import 'features/payments/pages/payments_page.dart';
import 'features/settings/pages/settings_page.dart';

class HealthBillingApp extends ConsumerWidget {
  const HealthBillingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _router;
    return MaterialApp.router(
      title: 'Healthcare Billing',
      themeMode: ThemeMode.system,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      routerConfig: router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/invoices',
      builder: (context, state) => const InvoiceListPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const InvoiceFormPage(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => InvoiceDetailPage(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => InvoiceFormPage(invoiceId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/payments',
      builder: (context, state) => const PaymentsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

final _lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    primary: const Color(0xFF2E7D32),
    secondary: const Color(0xFF006CFF),
    surface: const Color(0xFFF7FAFC),
    brightness: Brightness.light,
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final _darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E7D32),
    primary: const Color(0xFF2E7D32),
    secondary: const Color(0xFF006CFF),
    surface: const Color(0xFF121417),
    brightness: Brightness.dark,
  ),
);
