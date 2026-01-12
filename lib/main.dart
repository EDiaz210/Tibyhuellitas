import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'core/theme/app_theme.dart';
import 'core/services/gemini_service.dart';
import 'core/services/notification_service.dart';
import 'core/repositories/adoption_requests_repository.dart';
import 'core/repositories/user_repository.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/pets/presentation/bloc/pet_bloc.dart';
import 'features/refuges/presentation/bloc/refuge_bloc.dart';
import 'features/pets/presentation/pages/pets_list_page.dart';
import 'features/refuges/presentation/pages/refuges_map_page.dart';
import 'features/assistant/presentation/pages/assistant_page.dart';
import 'features/adoption/presentation/pages/my_adoption_requests_page.dart';
import 'features/refuges/presentation/pages/refuge_home_page.dart';
import 'features/refuges/presentation/pages/add_pet_for_refuge_page.dart';
import 'features/refuges/presentation/pages/edit_pet_for_refuge_page.dart';
import 'features/refuges/presentation/pages/refuge_pets_page.dart';
import 'features/refuges/presentation/pages/refuge_adoption_requests_page.dart';
import 'features/refuges/presentation/pages/refuge_profile_page.dart';
import 'features/auth/presentation/pages/role_selection_page.dart';
import 'injection_container.dart';

// Global Supabase client
late SupabaseClient _supabaseClient;
final getIt = GetIt.instance;

SupabaseClient getSupabaseClient() {
  return _supabaseClient;
}

// Global state for refuge navigation
class RefugeNavigationState extends ChangeNotifier {
  int _selectedIndex = 0;
  
  int get selectedIndex => _selectedIndex;
  
  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}

final refugeNavigationState = RefugeNavigationState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env file not found, using hardcoded values');
  }

  // Initialize Supabase - leer del .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw Exception('SUPABASE_URL not found in .env file');
  }
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception('SUPABASE_ANON_KEY not found in .env file');
  }

  debugPrint('✅ Supabase initialized from .env');

  // Initialize Supabase with deep linking support
  try {
    debugPrint('Initializing Supabase...');
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    // Store client reference globally
    _supabaseClient = Supabase.instance.client;
    
    // Setup auth state listener
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in: ${data.session?.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('👋 User signed out');
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token refreshed');
      }
    });
    
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Supabase: $e');
    rethrow;
  }

  // Configure dependencies
  configureDependencies();

  // Initialize Notification Service
  final notificationService = getIt<NotificationService>();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<LocationBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<PetBloc>()..add(const FetchAllPets()),
        ),
        BlocProvider(
          create: (_) => getIt<RefugeBloc>()..add(const FetchAllRefuges()),
        ),
      ],
      child: MaterialApp(
        title: 'TIBYHUELLITAS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        routes: {
          '/role_selection': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return RoleSelectionPage(
              email: args?['email'] ?? '',
              displayName: args?['displayName'] ?? 'Usuario',
            );
          },
          '/home': (context) => const MainNavigationScreen(),
          '/refuge_home': (context) => const RefugeMainNavigationScreen(),
          '/add_pet_refuge': (context) => const AddPetForRefugePage(),
          '/edit_pet_refuge': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            
            // Si es un Map con 'pet' y 'readOnly' (desde Ver o Editar)
            if (args is Map<String, dynamic> && args.containsKey('pet')) {
              final pet = args['pet'] as Map<String, dynamic>?;
              final readOnly = args['readOnly'] as bool? ?? false;
              return EditPetForRefugePage(pet: pet, readOnly: readOnly);
            } 
            // Si es solo un pet (compatibilidad)
            else if (args is Map<String, dynamic>) {
              return EditPetForRefugePage(pet: args);
            }
            
            return const EditPetForRefugePage();
          },
          '/refuge_pets': (context) => const RefugeMainNavigationScreen(),
          '/refuge_adoption_requests': (context) => const RefugeMainNavigationScreen(),
          '/refuge_requests': (context) => const RefugeMainNavigationScreen(),
          '/refuge_profile': (context) => const RefugeMainNavigationScreen(),
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}
class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const PetsListPage(),                     // Índice 0: Inicio
    const RefugesMapPage(),                   // Índice 1: Mapa
    AssistantPage(                            // Índice 2: Chat IA
      geminiService: getIt<GeminiService>(),
    ),
    const MyAdoptionRequestsPage(),           // Índice 3: Solicitudes
    const ProfilePage(),                      // Índice 4: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chat IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  late UserRepository _userRepository;
  late AdoptionRequestsRepository _adoptionRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = getIt<UserRepository>();
    _adoptionRepository = getIt<AdoptionRequestsRepository>();
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureCurrentPassword = !obscureCurrentPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureNewPassword = !obscureNewPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text.isEmpty ||
                    currentPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor completa todos los campos')),
                  );
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Las contraseñas no coinciden')),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                  );
                  return;
                }

                try {
                  await _userRepository.updatePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Contraseña actualizada correctamente!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();

                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _userRepository.getCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userProfile = snapshot.data;
        final userName = userProfile?.name ?? 'Usuario';
        final userEmail = userProfile?.email ?? 'email@example.com';
        final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              children: [
              // Header con info de usuario
              Container(
                color: const Color(0xFFFF6B35),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Profile sections
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Stats section
                    FutureBuilder<List<AdoptionRequest>>(
                      future: _adoptionRepository.getUserAdoptionRequests(currentUserId),
                      builder: (context, snapshot) {
                        final totalRequests = snapshot.data?.length ?? 0;
                        final approvedRequests = snapshot.data
                                ?.where((r) => r.status == 'approved')
                                .length ??
                            0;
                        final pendingRequests = snapshot.data
                                ?.where((r) => r.status == 'pending')
                                .length ??
                            0;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  label: 'Solicitudes',
                                  value: totalRequests.toString(),
                                ),
                                _StatItem(
                                  label: 'Adoptadas',
                                  value: approvedRequests.toString(),
                                ),
                                _StatItem(
                                  label: 'Pendientes',
                                  value: pendingRequests.toString(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Menu items
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Cambiar Contraseña'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        _showChangePasswordDialog(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Ayuda'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Cerrar Sesión',
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        _handleLogout(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============ REFUGE NAVIGATION SCREEN ============

class RefugeMainNavigationScreen extends StatefulWidget {
  const RefugeMainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<RefugeMainNavigationScreen> createState() =>
      _RefugeMainNavigationScreenState();
}

class _RefugeMainNavigationScreenState
    extends State<RefugeMainNavigationScreen> {
  late final List<Widget> _pages = [
    const RefugeHomePage(),                           // Índice 0: Home del Refugio
    const RefugePetsPage(),                           // Índice 1: Mis Mascotas
    const RefugeAdoptionRequestsPage(),               // Índice 2: Solicitudes
    const RefugeProfilePage(),                        // Índice 3: Perfil del Refugio
  ];

  @override
  void initState() {
    super.initState();
    // Listen to navigation state changes
    refugeNavigationState.addListener(_onNavigationIndexChanged);
  }

  @override
  void dispose() {
    refugeNavigationState.removeListener(_onNavigationIndexChanged);
    super.dispose();
  }

  void _onNavigationIndexChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: IndexedStack(
          index: refugeNavigationState.selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: refugeNavigationState.selectedIndex,
          onTap: (index) {
            String route;
            switch (index) {
              case 0:
                route = '/refuge_home';
                break;
              case 1:
                route = '/refuge_pets';
                break;
              case 2:
                route = '/refuge_adoption_requests';
                break;
              case 3:
                route = '/refuge_profile';
                break;
              default:
                route = '/refuge_home';
            }
            refugeNavigationState.setIndex(index);
            Navigator.pushReplacementNamed(context, route);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1ABC9C),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Mascotas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Solicitudes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ============ LOGIN SCREEN ============

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _performLogin();
  }

  Future<void> _performLogin() async {
    try {
      final supabase = getSupabaseClient();
      
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Detectar rol basado en account_type en tabla users
        final user = supabase.auth.currentUser;
        String routeName = '/home'; // Default para adoptantes

        if (user != null) {
          try {
            // Buscar account_type en tabla users
            final userData = await supabase
                .from('users')
                .select('account_type')
                .eq('id', user.id)
                .single();

            final accountType = userData['account_type'] as String?;
            print('🔍 account_type en BD: $accountType');
            
            if (accountType == 'refugio') {
              routeName = '/refuge_home';
              print('✓ Redirigiendo a refuge_home');
            } else {
              print('✓ Redirigiendo a home (adoptante)');
            }
          } catch (e) {
            print('⚠️ Error detectando tipo de cuenta: $e');
            // Si hay error, ir a /home (default para adoptantes)
          }
        }

        Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: _emailController.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de login: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignInFromMain(BuildContext context) async {
    print('🔵 [MAIN LOGIN] Google button pressed');
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ [MAIN LOGIN] Google Sign-In cancelled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In cancelled')),
          );
        }
        return;
      }

      print('✅ [MAIN LOGIN] Google Sign-In successful: ${googleUser.email}');
      
      if (mounted) {
        // Navegar a la página de selección de rol
        // El usuario se registrará en Supabase cuando seleccione su rol
        Navigator.of(context).pushReplacementNamed(
          '/role_selection',
          arguments: {
            'email': googleUser.email,
            'displayName': googleUser.displayName ?? 'Usuario Google',
          },
        );
      }
    } catch (e) {
      print('❌ [MAIN LOGIN] Google Sign-In error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header con gradiente y patas
              Container(
                width: double.infinity,
                color: const Color(0xFFFF6B35),
                padding: const EdgeInsets.only(top: 60, bottom: 40),
                child: Column(
                  children: [
                    // Dos patas de perro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 48, color: const Color(0xFF1A1A2E)),
                        const SizedBox(width: 20),
                        Icon(Icons.pets, size: 48, color: const Color(0xFF1A1A2E)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Form container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtítulo
                    const Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Email label
                    const Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'tu@email.com',
                        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Password label
                    const Text(
                      'CONTRASEÑA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Password field
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                          onPressed: () {
                            setState(() =>
                                _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 16),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFFF6B35),
                          disabledBackgroundColor: const Color(0xFFFFB088),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Divider with text
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o continúa con',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Google button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _handleGoogleSignInFromMain(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, size: 24, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Register link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: '¿No tienes cuenta? ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SignUpTypeScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFF6B35),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ FORGOT PASSWORD SCREEN ============

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendReset() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _performPasswordReset();
  }

  Future<void> _performPasswordReset() async {
    try {
      final supabase = getSupabaseClient();
      
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://tibyhuellitas.app/auth/reset',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar email: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFFF6B35),
              padding: const EdgeInsets.only(top: 40, bottom: 30, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: _emailSent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F9F5),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1ABC9C),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '¡Email enviado!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hemos enviado un enlace de recuperación a\n${_emailController.text}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor revisa tu correo y sigue las instrucciones\npara resetear tu contraseña.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFFF6B35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Volver al Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No te preocupes, te ayudaremos a recuperarla',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'EMAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'tu@email.com',
                            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                            prefixIcon: const Icon(Icons.email, color: Color(0xFF9CA3AF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendReset,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFFF6B35),
                              disabledBackgroundColor: const Color(0xFFFFB088),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enviar enlace de recuperación',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: '¿Recordaste tu contraseña? ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Inicia sesión',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFFF6B35),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ RESET PASSWORD SCREEN ============

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  
  const ResetPasswordScreen({Key? key, this.accessToken}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _performPasswordReset();
  }

  Future<void> _performPasswordReset() async {
    try {
      final supabase = getSupabaseClient();

      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Contraseña actualizada! Inicia sesión')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFFF6B35),
              padding: const EdgeInsets.only(top: 40, bottom: 30, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva Contraseña',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa tu nueva contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // New password
                  _buildPasswordField(
                    label: 'NUEVA CONTRASEÑA',
                    hint: '••••••••',
                    controller: _passwordController,
                    isObscure: _obscurePassword,
                    onToggle: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm password
                  _buildPasswordField(
                    label: 'CONFIRMAR CONTRASEÑA',
                    hint: '••••••••',
                    controller: _confirmController,
                    isObscure: _obscureConfirm,
                    onToggle: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  const SizedBox(height: 32),
                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleResetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFF6B35),
                        disabledBackgroundColor: const Color(0xFFFFB088),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Actualizar Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF9CA3AF)),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ============ SIGN UP TYPE SCREEN ============

class SignUpTypeScreen extends StatelessWidget {
  const SignUpTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFFF6B35),
              padding: const EdgeInsets.only(top: 40, bottom: 30, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Quién eres?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecciona el tipo de cuenta que deseas crear',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Adoptante card
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignUpAdoptantScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE5CC), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.home, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adoptante',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Busco adoptar una mascota y darle un hogar lleno de amor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF6B35), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Refugio card
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SignUpRefugioScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F9F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCCF0E6), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1ABC9C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.pets, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Refugio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Represento un refugio o fundación de animales',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFF1ABC9C), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ SIGN UP ADOPTANT SCREEN ============

class SignUpAdoptantScreen extends StatefulWidget {
  const SignUpAdoptantScreen({Key? key}) : super(key: key);

  @override
  State<SignUpAdoptantScreen> createState() => _SignUpAdoptantScreenState();
}

class _SignUpAdoptantScreenState extends State<SignUpAdoptantScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _performSignUp();
  }

  Future<void> _performSignUp() async {
    try {
      final supabase = getSupabaseClient();

      // Crear usuario en Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text,
          'phone': _phoneController.text,
          'city': _cityController.text,
          'account_type': 'adoptante',
        },
      );

      if (res.user == null) {
        throw Exception('No se pudo crear la cuenta de usuario');
      }

      print('✅ Adoptante registrado exitosamente');

      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Por favor verifica tu email'),
            backgroundColor: Color(0xFFFF6B35),
            duration: Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de autenticación: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFFF6B35),
              padding: const EdgeInsets.only(top: 40, bottom: 30, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Form
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear cuenta de Adoptante',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Full name
                  _buildTextField(
                    label: 'NOMBRE COMPLETO',
                    hint: 'Juan Pérez',
                    controller: _fullNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  _buildTextField(
                    label: 'EMAIL',
                    hint: 'tu@email.com',
                    controller: _emailController,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password
                  _buildPasswordField(
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  _buildTextField(
                    label: 'TELÉFONO',
                    hint: '+593 912 345 678',
                    controller: _phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // City con GPS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CIUDAD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                hintText: 'Quito',
                                hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
                                prefixIcon: const Icon(Icons.location_city, color: Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFAFA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.gps_fixed, size: 28, color: Color(0xFFFF6B35)),
                                    onPressed: _getLocationAddress,
                                    tooltip: 'Obtener ciudad actual',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFF6B35),
                        disabledBackgroundColor: const Color(0xFFFFB088),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Crear Cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocationAddress() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Por favor habilita el GPS');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showError('Permiso de ubicación requerido');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.administrativeArea ?? 'Desconocida';
        _cityController.text = city;
      }
    } catch (e) {
      _showError('Error al obtener ubicación: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF9CA3AF)) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF9CA3AF)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ============ SIGN UP REFUGIO SCREEN ============

class SignUpRefugioScreen extends StatefulWidget {
  const SignUpRefugioScreen({Key? key}) : super(key: key);

  @override
  State<SignUpRefugioScreen> createState() => _SignUpRefugioScreenState();
}

class _SignUpRefugioScreenState extends State<SignUpRefugioScreen> {
  final TextEditingController _refugioNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _refugioNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    print('🔍 Validando formulario...');
    
    // Validar todos los campos requeridos
    if (_refugioNameController.text.isEmpty) {
      _showError('❌ Nombre del refugio requerido');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('❌ Email requerido');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('❌ Contraseña requerida');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('❌ Teléfono requerido');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showError('❌ Ciudad requerida');
      return;
    }

    // VALIDACIÓN CRÍTICA: GPS es OBLIGATORIO
    if (_latitude == null || _longitude == null) {
      _showError('❌ OBLIGATORIO: Presiona el botón GPS para capturar tu ubicación');
      return;
    }

    if (_latitude == 0 && _longitude == 0) {
      _showError('❌ Coordenadas inválidas. Intenta capturar GPS nuevamente');
      return;
    }

    print('✅ Todos los campos válidos');
    print('   Nombre: ${_refugioNameController.text}');
    print('   Email: ${_emailController.text}');
    print('   Teléfono: ${_phoneController.text}');
    print('   Ciudad: ${_cityController.text}');
    print('   Coordenadas GPS: $_latitude, $_longitude');

    setState(() => _isLoading = true);
    _performSignUp();
  }

  Future<void> _performSignUp() async {
    try {
      print('📝 Iniciando registro de refugio...');
      final supabase = getSupabaseClient();

      print('👤 Creando usuario en Supabase Auth...');
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _refugioNameController.text,
          'phone': _phoneController.text,
          'city': _cityController.text,
          'account_type': 'refugio',
        },
      );

      if (res.user == null) {
        throw Exception('No se pudo crear la cuenta de usuario');
      }

      print('✅ Usuario creado: ${res.user!.id}');

      print('💾 Guardando refugio con coordenadas GPS...');
      await supabase.from('refuges').insert({
        'id': res.user!.id,
        'name': _refugioNameController.text,
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text,
        'address': _cityController.text,
        'latitude': _latitude!,
        'longitude': _longitude!,
        'description': '',
        'website': null,
        'type': 'shelter',
        'logo_url': null,
        'total_pets': 0,
        'adopted_pets': 0,
        'pending_requests': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Refugio registrado exitosamente');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Registro exitoso! Bienvenido. Verifica tu email para confirmar.'),
          backgroundColor: Color(0xFF1ABC9C),
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      print('❌ Error Auth: ${e.message}');
      if (mounted) {
        _showError('Error: ${e.message}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        _showError('Error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getLocationAddress() async {
    setState(() => _isLoadingLocation = true);

    try {
      print('🔍 Iniciando captura de GPS...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ GPS no está habilitado');
        _showError('Por favor habilita el GPS en los ajustes del dispositivo');
        return;
      }
      print('✅ GPS habilitado');

      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Permiso actual: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📋 Pidiendo permiso...');
        permission = await Geolocator.requestPermission();
        print('📋 Permiso después de pedir: $permission');
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('❌ Permiso denegado');
        _showError('Permiso de ubicación requerido. Por favor habilita en ajustes');
        return;
      }

      print('📡 Obteniendo posición...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      print('✅ Posición obtenida: ${position.latitude}, ${position.longitude}');

      // Guardar coordenadas para el refugio
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      print('💾 Coordenadas guardadas en estado:');
      print('   Lat: $_latitude');
      print('   Lon: $_longitude');

      // Obtener ciudad por geocoding inverso
      print('🔄 Realizando geocoding inverso...');
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.administrativeArea ?? 'Desconocida';
        
        setState(() {
          _cityController.text = city;
        });
        
        print('✅ Ciudad detectada: $city');
        _showSuccess('Ubicación capturada: $city');
      } else {
        print('⚠️  No se encontraron ciudades para las coordenadas');
        _showSuccess('GPS capturado pero no se pudo determinar la ciudad');
      }
    } catch (e) {
      print('❌ Error: $e');
      _showError('Error al obtener ubicación: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFF1ABC9C),
              padding: const EdgeInsets.only(top: 40, bottom: 30, left: 16, right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Form
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear cuenta de Refugio',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Refugio name
                  _buildTextField(
                    label: 'NOMBRE DEL REFUGIO',
                    hint: 'Refugio Patitas Felices',
                    controller: _refugioNameController,
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  _buildTextField(
                    label: 'EMAIL',
                    hint: 'contacto@refugio.com',
                    controller: _emailController,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password
                  _buildPasswordField(
                    label: 'CONTRASEÑA',
                    hint: '••••••••',
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  _buildTextField(
                    label: 'TELÉFONO',
                    hint: '+593 912 345 678',
                    controller: _phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // City con GPS
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CIUDAD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              readOnly: false,
                              decoration: InputDecoration(
                                hintText: 'Presiona GPS para obtener ubicación',
                                hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                                prefixIcon: const Icon(Icons.location_city, color: Color(0xFF9CA3AF)),
                                suffixIcon: _latitude != null && _longitude != null
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _latitude != null && _longitude != null
                                        ? Colors.green
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _latitude != null && _longitude != null
                                        ? Colors.green
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                filled: true,
                                fillColor: _latitude != null && _longitude != null
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFAFAFA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _latitude != null && _longitude != null
                                    ? Colors.green
                                    : const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _latitude != null && _longitude != null
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.white,
                            ),
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF1ABC9C),
                                        ),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      _latitude != null && _longitude != null
                                          ? Icons.location_on
                                          : Icons.gps_fixed,
                                      size: 28,
                                      color: _latitude != null && _longitude != null
                                          ? Colors.green
                                          : const Color(0xFF1ABC9C),
                                    ),
                                    onPressed: _getLocationAddress,
                                    tooltip: _latitude != null && _longitude != null
                                        ? 'Ubicación capturada: ($_latitude, $_longitude)'
                                        : 'Capturar ubicación actual',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1ABC9C),
                        disabledBackgroundColor: const Color(0xFF88D9CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Crear Cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1ABC9C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF9CA3AF)) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF9CA3AF)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}