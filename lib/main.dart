import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';


// Views
import 'views/start_page.dart';
import 'views/login_page.dart';
import 'views/home_page.dart';
import 'views/home(admin)_page.dart';
import 'views/admin_dashboard_page.dart';
import 'views/admin_user_management_page.dart';
import 'views/admin_material_management_page.dart';
import 'views/profile_page.dart';
import 'views/edit_profile_page.dart';
import 'views/publish_page.dart';

// Services
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/material_service.dart';
import 'services/admin_material_service.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'viewmodels/register_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/publish_viewmodel.dart';
import 'viewmodels/admin_material_viewmodel.dart';
import 'viewmodels/admin_user_management_viewmodel.dart';

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
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<MaterialService>(create: (_) => MaterialService()),
        Provider<AdminMaterialService>(create: (_) => AdminMaterialService()),

        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthService>()),
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
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(
            context.read<AuthService>(),
            context.read<UserService>(),
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            context.read<MaterialService>(), 
          ),
        ),
        ChangeNotifierProvider<AdminMaterialViewModel>(
          create: (context) => AdminMaterialViewModel(
            context.read<AdminMaterialService>(),
          ),
        ),
        ChangeNotifierProvider<PublishViewModel>(
          create: (context) => PublishViewModel(context.read<MaterialService>()), // 2. Registramos el cerebro
        ),
      ],
      child: MaterialApp(
        title: 'BookLoop Unimet',
        debugShowCheckedModeBanner: false,

        // Localización
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

        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          

          
        ),

        initialRoute: '/',
        routes: {
          '/': (context) => const StartPage(),
          '/login': (context) => const LoginPage(),
          '/home_page': (context) => const HomePage(),
          '/home_admin': (context) => const HomeAdminPage(),
          '/admin_dashboard': (context) => AdminDashboardView(
                onBack: () => Navigator.of(context).pop(),
                onOpenMenu: () async {},
              ),
          '/admin_users': (context) => ChangeNotifierProvider(
                create: (_) => AdminUserManagementViewModel(),
                child: const AdminUserManagementPage(),
              ),
          '/admin_materials': (context) => ChangeNotifierProvider(
                create: (context) => AdminMaterialViewModel(
                  context.read<AdminMaterialService>(),
                ),
                child: const AdminMaterialManagementPage(),
              ),
          '/profile': (context) => const ProfilePage(),
          '/edit_profile': (context) => const EditProfilePage(),
          '/publish': (context) => PublishPage(),
        },
      ),
    );
  }
}