import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pets_sync_service.dart';
import '../../../../core/services/adoption_requests_sync_service.dart';

class RefugeProfilePage extends StatefulWidget {
  const RefugeProfilePage({Key? key}) : super(key: key);

  @override
  State<RefugeProfilePage> createState() => _RefugeProfilePageState();
}

class _RefugeProfilePageState extends State<RefugeProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? refugeData;
  bool isLoading = true;
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController descriptionController;
  
  // Servicios como variables para evitar crear nuevas instancias
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;
  
  // Referencias a los callbacks para poder removerlos después
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    _loadRefugeData();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    descriptionController = TextEditingController();
    
    // Obtener referencias a los servicios singleton
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    // Crear callbacks con referencias permanentes
    _petsSyncCallback = (record) {
      print('🔔 [RefugeProfilePage] Cambio detectado en mascotas');
      if (mounted) {
        setState(() {
          _loadRefugeData();
        });
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [RefugeProfilePage] Cambio detectado en adoption_requests');
      if (mounted) {
        setState(() {
          _loadRefugeData();
        });
      }
    };
    
    // Inicializar listeners en background
    _initializeListeners();
  }

  Future<void> _initializeListeners() async {
    try {
      print('🔧 [RefugeProfilePage] Iniciando listeners...');
      // 1. Asegurar que los servicios estén escuchando PRIMERO
      await _petsSyncService.startListening();
      print('✅ [RefugeProfilePage] PetsSyncService escuchando');
      
      await _adoptionSyncService.startListening();
      print('✅ [RefugeProfilePage] AdoptionSyncService escuchando');
      
      // 2. AHORA agregar listeners
      _petsSyncService.addListener(_petsSyncCallback);
      print('✅ [RefugeProfilePage] Listener de pets agregado');
      
      _adoptionSyncService.addListener(_adoptionSyncCallback);
      print('✅ [RefugeProfilePage] Listener de adoption agregado');
      
      print('✅ [RefugeProfilePage] Listeners inicializados correctamente');
    } catch (e) {
      print('❌ [RefugeProfilePage] Error inicializando listeners: $e');
    }
  }

  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRefugeData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Obtener datos del refugio (refuges.id == users.id)
      final data = await supabase
          .from('refuges')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          refugeData = data;
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone_number'] ?? '';
          emailController.text = data['email'] ?? '';
          descriptionController.text = data['description'] ?? '';
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading refuge data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateRefugeData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Update by refuge ID (not user.id)
      if (refugeData != null && refugeData?['id'] != null) {
        await supabase.from('refuges').update({
          'name': nameController.text,
          'phone_number': phoneController.text,
          'email': emailController.text,
          'description': descriptionController.text,
        }).eq('id', refugeData?['id'] as String);
      }

      setState(() => isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Color(0xFF1ABC9C),
          ),
        );
      }

      await _loadRefugeData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _refreshRefugeData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Obtener datos del refugio (refuges.id == users.id)
      final data = await supabase
          .from('refuges')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          refugeData = data;
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone_number'] ?? '';
          // NO actualizar email en el refresh
          descriptionController.text = data['description'] ?? '';
        });
      }
    } catch (e) {
      print('Error refreshing refuge data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF1ABC9C)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        title: const Text(
          'Perfil del Refugio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() => isEditing = true);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRefugeData,
        color: const Color(0xFF1ABC9C),
        child: SingleChildScrollView(
        child: Column(
          children: [
            // Header con información del refugio
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Text(
                        refugeData?['name']?[0]?.toUpperCase() ?? '🐾',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1ABC9C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    refugeData?['name'] ?? 'Refugio',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Administrador de Refugio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido editable
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Refugio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  _buildInfoField(
                    label: 'Nombre del Refugio',
                    controller: nameController,
                    isEditing: isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  _buildInfoField(
                    label: 'Teléfono',
                    controller: phoneController,
                    isEditing: isEditing,
                    hintText: '+593 9XX XXX XXXX',
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildInfoField(
                    label: 'Email',
                    controller: emailController,
                    isEditing: isEditing,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  _buildInfoField(
                    label: 'Descripción',
                    controller: descriptionController,
                    isEditing: isEditing,
                    maxLines: 4,
                    hintText: 'Cuéntanos sobre tu refugio...',
                  ),
                  const SizedBox(height: 24),

                  // Estadísticas
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),

                  // Botones
                  if (isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => isEditing = false);
                              _loadRefugeData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateRefugeData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1ABC9C),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Actualizar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => isEditing = true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Editar información',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Botón cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          print('Iniciando logout...');
                          await supabase.auth.signOut();
                          print('Logout exitoso');
                          if (mounted) {
                            // Volver a la pantalla de login (home de la app)
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          print('Error en logout: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Text(
              controller.text.isEmpty ? '-' : controller.text,
              style: TextStyle(
                color: controller.text.isEmpty ? Colors.grey[400] : Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return _StatisticsWidget(
      onDataChanged: () {
        setState(() {});
      },
    );
  }
}

class _StatisticsWidget extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const _StatisticsWidget({
    Key? key,
    this.onDataChanged,
  }) : super(key: key);

  @override
  State<_StatisticsWidget> createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<_StatisticsWidget> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, int>> _statisticsFuture;
  
  // Listeners para realtime
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
    
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    _petsSyncCallback = (record) {
      print('🔔 [_StatisticsWidget] Mascota modificada, recargando stats');
      if (mounted) {
        setState(() {
          _statisticsFuture = _loadStatistics();
        });
        widget.onDataChanged?.call();
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [_StatisticsWidget] Solicitud modificada, recargando stats');
      if (mounted) {
        setState(() {
          _statisticsFuture = _loadStatistics();
        });
        widget.onDataChanged?.call();
      }
    };
    
    _initializeListeners();
  }
  
  Future<void> _initializeListeners() async {
    try {
      await _petsSyncService.startListening();
      await _adoptionSyncService.startListening();
      _petsSyncService.addListener(_petsSyncCallback);
      _adoptionSyncService.addListener(_adoptionSyncCallback);
    } catch (e) {
      print('❌ [_StatisticsWidget] Error: $e');
    }
  }
  
  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  Future<Map<String, int>> _loadStatistics() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return {};

      final refugeData = await supabase
          .from('refuges')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (refugeData == null) return {};

      final refugeId = refugeData['id'];

      final petsCount =
          await supabase.from('pets').select('id').eq('refuge_id', refugeId);

      final requestsCount = await supabase
          .from('adoption_requests')
          .select('id')
          .eq('refuge_id', refugeId)
          .eq('status', 'pending');

      final adoptedCount = await supabase
          .from('adoption_requests')
          .select('id')
          .eq('refuge_id', refugeId)
          .eq('status', 'approved');

      return {
        'total_pets': petsCount.length,
        'total_requests': requestsCount.length,
        'adopted': adoptedCount.length,
      };
    } catch (e) {
      print('Error loading statistics: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data as Map<String, int>;

        return Row(
          children: [
            Expanded(
              child: _StatBox(
                title: 'Mascotas',
                value: stats['total_pets']?.toString() ?? '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                title: 'Pendientes',
                value: stats['total_requests']?.toString() ?? '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                title: 'Adoptadas',
                value: stats['adopted']?.toString() ?? '0',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1ABC9C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1ABC9C).withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1ABC9C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
