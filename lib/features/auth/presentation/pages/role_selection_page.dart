import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionPage extends StatefulWidget {
  final String email;
  final String displayName;

  const RoleSelectionPage({
    Key? key,
    required this.email,
    required this.displayName,
  }) : super(key: key);

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;
  final _supabaseClient = Supabase.instance.client;

  Future<void> _saveUserRole(String role) async {
    setState(() => _isLoading = true);

    try {
      print('🔵 [ROLE SELECTION] Registrando usuario con rol: $role');
      print('   Email: ${widget.email}');
      print('   Display Name: ${widget.displayName}');

      // Registrar en Supabase Auth con account_type
      final AuthResponse res = await _supabaseClient.auth.signUp(
        email: widget.email,
        password: '${widget.displayName}GoogleAuth${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'display_name': widget.displayName,
          'account_type': role,
        },
      );

      if (res.user == null) {
        throw Exception('No se pudo registrar el usuario');
      }

      print('✅ [ROLE SELECTION] Usuario registrado en Supabase: ${res.user!.id}');
      print('   Account Type: $role');

      // Validar que los datos se hayan guardado correctamente en tabla users
      try {
        final userData = await _supabaseClient
            .from('users')
            .select('account_type, name, email')
            .eq('id', res.user!.id)
            .single();

        print('✅ [ROLE SELECTION] Datos en tabla users:');
        print('   account_type: ${userData['account_type']}');
        print('   name: ${userData['name']}');
        print('   email: ${userData['email']}');
      } catch (e) {
        print('⚠️ [ROLE SELECTION] Usuario no encontrado en tabla users: $e');
      }

      if (mounted) {
        // Determinar la ruta según el role
        final routeName = role == 'adoptante' ? '/home' : '/refuge_home';
        print('🔵 [ROLE SELECTION] Navegando a: $routeName con account_type: $role');
        
        Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: widget.email,
        );
      }
    } catch (e) {
      print('❌ [ROLE SELECTION] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      appBar: AppBar(
        title: const Text('Selecciona tu rol'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Qué tipo de usuario eres?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona el rol que mejor se ajuste a ti',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              // Botón Adoptante
              SizedBox(
                width: double.infinity,
                height: 150,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _saveUserRole('adoptante'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 40, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Adoptante',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quiero adoptar una mascota',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón Refugio
              SizedBox(
                width: double.infinity,
                height: 150,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _saveUserRole('refugio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, size: 40, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Refugio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Represento un refugio de animales',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
