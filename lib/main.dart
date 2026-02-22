import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

// Views
import 'views/start_page.dart';
import 'views/home(admin)_page.dart';
import 'views/home_page.dart';
import 'views/login_page.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BookLoopApp());
}

class BookLoopApp extends StatelessWidget {
  const BookLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // =========================
        // SERVICES
        // =========================
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),

        // =========================
        // VIEWMODELS
        // =========================
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) =>
              AuthViewModel(context.read<AuthService>()),
        ),

        ChangeNotifierProvider<PaymentViewModel>(
          create: (context) => PaymentViewModel(
            context.read<AuthService>(),
            context.read<UserService>(),
          ),
        ),

        ChangeNotifierProvider<RegisterViewModel>(
          create: (_) => RegisterViewModel(),
        ),

        // 🔹 PROFILE VIEWMODEL (NUEVO MÓDULO)
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(
            context.read<AuthService>(),
            context.read<UserService>(),
          )..cargarPerfil(), // 👈 Carga automática al iniciar
        ),

        ChangeNotifierProvider<HomeViewModel>(
          create: (context) =>
              HomeViewModel(context.read<AuthService>()),
        ),
      ],

      child: MaterialApp(
        title: 'BookLoop Unimet',
        debugShowCheckedModeBanner: false,

        // =========================
        // LOCALIZACIÓN
        // =========================
        locale: const Locale('es'),
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // =========================
        // TEMA
        // =========================
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
        ),

        // =========================
        // RUTAS
        // =========================
        initialRoute: '/',
        routes: {
          '/': (context) => const StartPage(),
          '/login': (context) => const LoginPage(),
          '/home_page': (context) => const HomePage(),
          '/home_admin': (context) => const HomeAdminPage(),
        },
      ),
    );
  }
}