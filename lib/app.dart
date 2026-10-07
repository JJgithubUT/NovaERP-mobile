import 'package:flutter/material.dart';
import 'core/config/app_theme.dart';
import 'core/routes/app_routes.dart';

class NovaERPApp extends StatelessWidget {
  const NovaERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NovaERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.raiz,
      routes: AppRoutes.routes,
    );
  }
}
