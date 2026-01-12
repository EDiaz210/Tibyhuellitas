import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/pets_sync_service.dart';
import '../../../../core/services/adoption_requests_sync_service.dart';

class RefugeAdminPanelPage extends StatefulWidget {
  const RefugeAdminPanelPage({Key? key}) : super(key: key);

  @override
  State<RefugeAdminPanelPage> createState() => _RefugeAdminPanelPageState();
}

class _RefugeAdminPanelPageState extends State<RefugeAdminPanelPage> {
  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  final supabase = Supabase.instance.client;
  
  // Servicios como variables para evitar crear nuevas instancias
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;
  
  // Referencias a los callbacks para poder removerlos después
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    
    // Obtener referencias a los servicios singleton
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    // Crear callbacks con referencias permanentes
    _petsSyncCallback = (record) {
      print('🔔 [AdminPanel] Cambio detectado en mascotas, recargando');
      if (mounted) {
        setState(() {
          _requestsFuture = _fetchAdoptionRequests();
        });
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [AdminPanel] Cambio detectado en adoption_requests, recargando');
      if (mounted) {
        setState(() {
          _requestsFuture = _fetchAdoptionRequests();
        });
      }
    };
    
    // Inicializar listeners en background
    _initializeListeners();
  }

  Future<void> _initializeListeners() async {
    try {
      print('🔧 [AdminPanel] Iniciando listeners...');
      // 1. Asegurar que los servicios estén escuchando PRIMERO
      await _petsSyncService.startListening();
      print('✅ [AdminPanel] PetsSyncService escuchando');
      
      await _adoptionSyncService.startListening();
      print('✅ [AdminPanel] AdoptionSyncService escuchando');
      
      // 2. AHORA agregar listeners
      _petsSyncService.addListener(_petsSyncCallback);
      print('✅ [AdminPanel] Listener de pets agregado');
      
      _adoptionSyncService.addListener(_adoptionSyncCallback);
      print('✅ [AdminPanel] Listener de adoption agregado');
      
      print('✅ [AdminPanel] Listeners inicializados correctamente');
    } catch (e) {
      print('❌ [AdminPanel] Error inicializando listeners: $e');
    }
  }

  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  void _loadRequests() {
    _requestsFuture = _fetchAdoptionRequests();
  }

  Future<List<Map<String, dynamic>>> _fetchAdoptionRequests() async {
    try {
      // Obtener el refugio actual del usuario autenticado
      final userId = supabase.auth.currentUser?.id;
      print('DEBUG 1: User ID = $userId');
      if (userId == null) {
        print('DEBUG 1: No user logged in');
        return [];
      }

      // Buscar el refugio asociado a este usuario (refuges.id == auth_user.id)
      final refugeResponse = await supabase
          .from('refuges')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      print('DEBUG 2: Refuge response = $refugeResponse');
      if (refugeResponse == null) {
        print('DEBUG 2: No refuge found for user');
        return [];
      }

      final refugeId = refugeResponse['id'];
      print('DEBUG 3: Refuge ID = $refugeId');

      // Obtener las solicitudes de adopción para mascotas de este refugio
      // Primero obtener los IDs de mascotas del refugio
      final petsResponse = await supabase
          .from('pets')
          .select('id')
          .eq('refuge_id', refugeId);

      print('DEBUG 4: Pets response = $petsResponse (count: ${petsResponse.length})');
      if (petsResponse.isEmpty) {
        print('DEBUG 4: No pets found in refuge');
        return [];
      }

      final petIds = List<String>.from(
        petsResponse.map((pet) => pet['id'] as String),
      );
      print('DEBUG 5: Pet IDs = $petIds');

      // Obtener las solicitudes de adopción para esas mascotas
      final requests = await supabase
          .from('adoption_requests')
          .select('*, users(full_name), pets(name, photo_url)')
          .inFilter('pet_id', petIds)
          .order('created_at', ascending: false)
          .limit(5);

      print('DEBUG 6: Adoption requests = $requests (count: ${requests.length})');
      return List<Map<String, dynamic>>.from(requests);
    } catch (e, stackTrace) {
      print('Error loading adoption requests: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> _refreshAdminPanel() async {
    setState(() {
      _requestsFuture = _fetchAdoptionRequests();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Refugio Patitas Felices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAdminPanel,
        color: const Color(0xFF1ABC9C),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con estadísticas
              _buildStatsHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solicitudes recientes
                    _buildSectionTitle('Solicitudes Recientes'),
                    const SizedBox(height: 12),
                    _buildRequestsList(),
                    const SizedBox(height: 30),
                    // Mis mascotas
                    _buildSectionTitle('Mis Mascotas'),
                    const SizedBox(height: 12),
                    _buildPetsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1ABC9C),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/refuge_home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/refuge_pets');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/refuge_adoption_requests');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/refuge_profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
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
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1ABC9C),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('15', 'Mascotas'),
              _buildStatItem('8', 'Pendientes'),
              _buildStatItem('23', 'Adoptadas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Ver todas',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1ABC9C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No hay solicitudes recientes',
              style: TextStyle(color: Colors.grey[500]),
            ),
          );
        }

        return Column(
          children: [
            ...requests.map((request) {
              final petName = request['pets']?['name'] ?? 'Mascota desconocida';
              final petPhoto = request['pets']?['photo_url'] ?? '';
              final userName = request['users']?['full_name'] ?? 'Usuario desconocido';
              final status = request['status'] ?? 'Pendiente';

              return Column(
                children: [
                  _buildRequestItem(
                    petName: petName,
                    petPhoto: petPhoto,
                    userName: userName,
                    status: status,
                    showApproveButton: true,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRequestItem({
    required String petName,
    required String petPhoto,
    required String userName,
    required String status,
    required bool showApproveButton,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: petPhoto.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      petPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.pets, color: Color(0xFFFF6B35));
                      },
                    ),
                  )
                : const Icon(Icons.pets, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud para $petName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'De: $userName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (showApproveButton) ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return Column(
      children: [
        _buildPetItem(
          petName: 'Luna',
          status: 'Disponible',
        ),
      ],
    );
  }

  Widget _buildPetItem({
    required String petName,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pets, color: Color(0xFF1ABC9C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1ABC9C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF1ABC9C)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1ABC9C)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
