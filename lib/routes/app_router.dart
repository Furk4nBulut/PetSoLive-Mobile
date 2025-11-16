// Uygulama rotaları burada olacak 

import 'package:flutter/material.dart';
import '../presentation/screens/pets_screen.dart';
import '../presentation/screens/lost_pets_screen.dart';
import '../presentation/screens/help_requests_screen.dart';
import '../presentation/screens/lost_pet_ad_screen.dart';
import '../presentation/screens/help_request_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/blocs/account_cubit.dart';
import '../injection_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/screens/add_help_request_screen.dart';
import '../presentation/blocs/help_request_cubit.dart';
import '../presentation/screens/add_pet_screen.dart';

/// Uygulamanın tüm rotalarını merkezi olarak yöneten sınıf.
/// Yeni bir ekran eklemek için sadece buraya case eklemen yeterli.
class AppRouter {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/pets':
        return MaterialPageRoute(builder: (_) => const PetsScreen());
      case '/lost_pets':
        return MaterialPageRoute(builder: (_) => const LostPetsScreen());
      case '/help_requests':
        return MaterialPageRoute(builder: (_) => const HelpRequestsScreen());
      case '/lost_pet_ad': {
        final adId = settings.arguments;
        if (adId is int) {
          return MaterialPageRoute(builder: (_) => LostPetAdScreen(adId: adId));
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('404 - Kayıp ilanı bulunamadı')),
            ),
          );
        }
      }
      case '/help_request': {
        final reqId = settings.arguments;
        if (reqId is int) {
          return MaterialPageRoute(builder: (_) => HelpRequestScreen(requestId: reqId));
        } else {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('404 - Yardım talebi bulunamadı')),
            ),
          );
        }
      }
      case '/add_help_request':
        return MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<HelpRequestCubit>()),
            ],
            child: const AddHelpRequestScreen(),
          ),
        );
      case '/add_pet':
        return MaterialPageRoute(builder: (_) => const AddPetScreen());
      case '/login':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AccountCubit>(),
            child: const LoginScreen(),
          ),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<AccountCubit>(),
            child: const RegisterScreen(),
          ),
        );
      // case '/help_request':
      //   final reqId = settings.arguments as int?;
      //   return MaterialPageRoute(builder: (_) => HelpRequestScreen(requestId: reqId));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('404 - Sayfa bulunamadı')),
          ),
        );
    }
  }
}

// Kullanım örneği:
// Navigator.of(context).pushNamed('/pets');
// MaterialApp'da: onGenerateRoute: AppRouter.generateRoute, 

// Global route observer for navigation events
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
