import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/documents/screens/dashboard_screen.dart';

class DocVaultApp extends StatelessWidget {
  const DocVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
