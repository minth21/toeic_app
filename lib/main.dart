import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/auth/views/splash_screen.dart';
import 'constants/app_constants.dart';
import 'features/settings/viewmodels/theme_viewmodel.dart';
import 'features/practice/viewmodels/practice_viewmodel.dart';
import 'features/home/viewmodels/dashboard_viewmodel.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/settings/viewmodels/language_viewmodel.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageViewModel()),
        ChangeNotifierProvider(create: (_) => PracticeViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      ],
      child: Consumer2<ThemeViewModel, LanguageViewModel>(
        builder: (context, themeViewModel, languageViewModel, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            // Locale Configuration
            locale: languageViewModel.locale,
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Theme Configuration
            themeMode: themeViewModel.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                onPrimary: AppColors.textOnPrimary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
                primaryContainer: AppColors.pastelBlue,
                onPrimaryContainer: AppColors.primary,
                surfaceTint: Colors.white,
                error: AppColors.error,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.background,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              textTheme: GoogleFonts.interTextTheme().copyWith(
                displayLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                displayMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                displaySmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                titleLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
                bodyMedium: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              cardColor: AppColors.surface,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.darkSurface,
                surfaceTint: AppColors.darkSurface,
                error: AppColors.error,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.darkBackground,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
                  .copyWith(
                    displayLarge: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    displayMedium: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    displaySmall: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    headlineLarge: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    headlineMedium: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    headlineSmall: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titleLarge: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titleMedium: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: AppColors.darkSurface,
                foregroundColor: Colors.white,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.darkSurface,
              ),

              cardColor:
                  AppColors.darkCardBackground, // For backward compatibility
            ),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.15)),
                child: child!,
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
