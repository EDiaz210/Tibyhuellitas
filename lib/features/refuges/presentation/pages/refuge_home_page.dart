import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../injection_container.dart';
import '../../../../core/repositories/adoption_requests_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/adoption_requests_sync_service.dart';
import '../../../../core/services/pets_sync_service.dart';
import '../../../../core/utils/pet_age_calculator.dart';

class RefugeHomePage extends StatefulWidget {
  const RefugeHomePage({Key? key}) : super(key: key);

  @override
  State<RefugeHomePage> createState() => _RefugeHomePageState();
}

class _RefugeHomePageState extends State<RefugeHomePage> {
  late AdoptionRequestsRepository adoptionRepository;
  final supabase = Supabase.instance.client;
  String refugeName = '';
  int totalPets = 0;
  int pendingRequests = 0;
  int adoptedPets = 0;
  
  // Referencias a los callbacks para poder removerlos después
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;
  
  // Servicios como variables para evitar crear nuevas instancias
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;

  @override
  void initState() {
    super.initState();
    adoptionRepository = getIt<AdoptionRequestsRepository>();
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    _loadRefugeData();
    
    // Crear callbacks con referencias permanentes
    _petsSyncCallback = (record) {
      print('🔔 [HOME] Cambio detectado en mascotas');
      print('  - Record: ${record['id']}, refuge_id: ${record['refuge_id']}');
      if (mounted) {
        setState(() {
          print('  ✅ [HOME] Recargando mascotas');
          _loadRefugeData();
        });
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [HOME] Cambio detectado en adoption_requests');
      if (mounted) {
        setState(() {
          print('  ✅ [HOME] Recargando solicitudes');
          _loadRefugeData();
        });
      }
    };
    
    // Inicializar listeners en background (esto debe ser PRIMERO)
    _initializeListeners();
  }

  Future<void> _initializeListeners() async {
    try {
      print('🔧 [RefugeHomePage] Iniciando listeners...');
      // 1. Asegurar que los servicios estén escuchando PRIMERO
      await _petsSyncService.startListening();
      print('✅ [RefugeHomePage] PetsSyncService está escuchando');
      
      await _adoptionSyncService.startListening();
      print('✅ [RefugeHomePage] AdoptionSyncService está escuchando');
      
      // 2. Ahora agregar los listeners (después de que estén suscritos)
      _petsSyncService.addListener(_petsSyncCallback);
      print('✅ [RefugeHomePage] Listener de pets agregado');
      
      _adoptionSyncService.addListener(_adoptionSyncCallback);
      print('✅ [RefugeHomePage] Listener de adoption agregado');
      
      print('✅ Listeners inicializados correctamente en RefugeHomePage');
    } catch (e) {
      print('❌ Error inicializando listeners en RefugeHomePage: $e');
    }
  }

  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  Future<void> _loadRefugeData() async {
    try {
      final user = supabase.auth.currentUser;
      print('🔍 _loadRefugeData: user.id = ${user?.id}');
      if (user == null) return;

      // Obtener datos del refugio (refuges.id == users.id)
      final refugeData = await supabase
          .from('refuges')
          .select('name, id')
          .eq('id', user.id)
          .maybeSingle();

      print('🔍 _loadRefugeData: refugeData = $refugeData');

      if (refugeData != null) {
        final refugeId = refugeData['id'];
        print('🔍 _loadRefugeData: refugeId = $refugeId');

        // Obtener total de mascotas
        final petsCount = await supabase
            .from('pets')
            .select('id')
            .eq('refuge_id', refugeId);

        // Obtener solicitudes pendientes
        final pendingCount = await supabase
            .from('adoption_requests')
            .select('id')
            .eq('refuge_id', refugeId)
            .eq('status', 'pending');

        // Obtener mascotas adoptadas
        final adoptedCount = await supabase
            .from('adoption_requests')
            .select('id')
            .eq('refuge_id', refugeId)
            .eq('status', 'approved');

        setState(() {
          refugeName = refugeData['name'] ?? 'Refugio';
          totalPets = petsCount.length;
          pendingRequests = pendingCount.length;
          adoptedPets = adoptedCount.length;
        });
      }
    } catch (e) {
      print('Error loading refuge data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadRefugeData,
        color: const Color(0xFF1ABC9C),
        child: SingleChildScrollView(
          child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1ABC9C), const Color(0xFF16A085)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Panel de administración',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            refugeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Estadísticas
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          number: totalPets.toString(),
                          label: 'Mascotas',
                          backgroundColor: const Color(0xFF1ABC9C),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          number: pendingRequests.toString(),
                          label: 'Pendientes',
                          backgroundColor: const Color(0xFF1ABC9C),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          number: adoptedPets.toString(),
                          label: 'Adoptadas',
                          backgroundColor: const Color(0xFF1ABC9C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Solicitudes Recientes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Solicitudes Recientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Ir a solicitudes completas
                        },
                        child: const Text(
                          'Ver todas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1ABC9C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RecentRequestsCard(
                    onRequestsUpdated: _loadRefugeData,
                  ),
                  const SizedBox(height: 24),
                  // Mis Mascotas
                  const Text(
                    'Mis Mascotas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MyPetsCard(
                    onPetChanged: () {
                      // Recargar stats del padre cuando cambian las mascotas
                      _loadRefugeData();
                    },
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

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final Color backgroundColor;

  const _StatCard({
    required this.number,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1ABC9C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
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

class _RecentRequestsCard extends StatefulWidget {
  final VoidCallback onRequestsUpdated;

  const _RecentRequestsCard({
    Key? key,
    required this.onRequestsUpdated,
  }) : super(key: key);

  @override
  State<_RecentRequestsCard> createState() => _RecentRequestsCardState();
}

class _RecentRequestsCardState extends State<_RecentRequestsCard> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> _requestsFuture;
  
  // Listeners para realtime
  late AdoptionRequestsSyncService _adoptionSyncService;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRecentRequests();
    
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    _adoptionSyncCallback = (record) {
      print('🔔 [_RecentRequestsCard] Solicitud modificada, recargando');
      if (mounted) {
        setState(() {
          _requestsFuture = _loadRecentRequests();
        });
      }
    };
    
    _initializeListeners();
  }
  
  Future<void> _initializeListeners() async {
    try {
      await _adoptionSyncService.startListening();
      _adoptionSyncService.addListener(_adoptionSyncCallback);
    } catch (e) {
      print('❌ [_RecentRequestsCard] Error: $e');
    }
  }
  
  @override
  void dispose() {
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data as List<dynamic>;

        if (requests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'No hay solicitudes recientes',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: List.generate(
            requests.length.clamp(0, 2),
            (index) {
              final request = requests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestItem(
                  request: request,
                  onStatusChanged: () {
                    widget.onRequestsUpdated();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _loadRecentRequests() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final refugeData = await supabase
          .from('refuges')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (refugeData == null) return [];

      final requests = await supabase
          .from('adoption_requests')
          .select(
            'id, status, created_at, users(name), pets(name, photo_url)',
          )
          .eq('refuge_id', refugeData['id'])
          .order('created_at', ascending: false)
          .limit(2);

      return requests;
    } catch (e) {
      print('Error loading recent requests: $e');
      return [];
    }
  }
}

class _RequestItem extends StatefulWidget {
  final dynamic request;
  final VoidCallback onStatusChanged;

  const _RequestItem({
    required this.request,
    required this.onStatusChanged,
  });

  @override
  State<_RequestItem> createState() => _RequestItemState();
}

class _RequestItemState extends State<_RequestItem> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isLoading = true);
    try {
      // Obtener datos del refugio para el nombre
      final user = supabase.auth.currentUser;
      String refugeName = 'Refugio';
      
      if (user != null) {
        final refugeData = await supabase
            .from('refuges')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
        
        if (refugeData != null) {
          refugeName = refugeData['name'] ?? 'Refugio';
        }
      }

      // Actualizar en la base de datos
      final updateResult = await supabase
          .from('adoption_requests')
          .update({'status': newStatus})
          .eq('id', widget.request['id'])
          .select();

      // Enviar notificación al adoptador
      final notificationService = getIt<NotificationService>();
      final petName = widget.request['pets']?['name'] ?? 'mascota';
      
      if (newStatus == 'approved') {
        await notificationService.showRequestApprovedNotification(
          refugeName: refugeName,
          petName: petName,
        );
      } else if (newStatus == 'rejected') {
        await notificationService.showRequestRejectedNotification(
          refugeName: refugeName,
          petName: petName,
        );
      }

      // Notificar a AdoptionRequestsSyncService que cambió una solicitud
      if (updateResult.isNotEmpty) {
        final updatedRequest = updateResult[0] as Map<String, dynamic>;
        AdoptionRequestsSyncService().notifyListeners(updatedRequest);
        print('✅ Notificación enviada a AdoptionRequestsSyncService');
      }

      widget.onStatusChanged();
    } catch (e) {
      print('Error updating status: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.request['pets']?['photo_url'] != null &&
                    (widget.request['pets']?['photo_url'] as String).isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.request['pets']?['photo_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            widget.request['pets']?['name']?[0]?.toUpperCase() ??
                                '🐾',
                            style: const TextStyle(fontSize: 24),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      widget.request['pets']?['name']?[0]?.toUpperCase() ?? '🐾',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud para ${widget.request['pets']?['name'] ?? 'mascota'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'De: ${widget.request['users']?['name'] ?? 'Usuario'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: widget.request['status'] == 'pending'
                      ? () => _updateStatus('approved')
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.request['status'] == 'approved'
                          ? const Color(0xFF1ABC9C)
                          : widget.request['status'] == 'rejected'
                              ? Colors.grey.withOpacity(0.2)
                              : const Color(0xFF1ABC9C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.check,
                      color: widget.request['status'] == 'approved'
                          ? Colors.white
                          : widget.request['status'] == 'rejected'
                              ? Colors.grey
                              : const Color(0xFF1ABC9C),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.request['status'] == 'pending'
                      ? () => _updateStatus('rejected')
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.request['status'] == 'rejected'
                          ? Colors.red
                          : widget.request['status'] == 'approved'
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: widget.request['status'] == 'rejected'
                          ? Colors.white
                          : widget.request['status'] == 'approved'
                              ? Colors.grey
                              : Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MyPetsCard extends StatefulWidget {
  final VoidCallback? onPetChanged;
  
  const _MyPetsCard({
    Key? key,
    this.onPetChanged,
  }) : super(key: key);

  @override
  State<_MyPetsCard> createState() => _MyPetsCardState();
}

class _MyPetsCardState extends State<_MyPetsCard> {
  final supabase = Supabase.instance.client;
  late Future<List<dynamic>> _petsFuture;
  
  // Servicios y callbacks para realtime
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadMyPets();
    
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    _petsSyncCallback = (record) {
      print('🔔 [_MyPetsCard] Mascota modificada, recargando lista');
      if (mounted) {
        setState(() {
          _petsFuture = _loadMyPets();
        });
        widget.onPetChanged?.call();
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [_MyPetsCard] Solicitud modificada, recargando lista');
      if (mounted) {
        setState(() {
          _petsFuture = _loadMyPets();
        });
        widget.onPetChanged?.call();
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
      print('❌ [_MyPetsCard] Error listeners: $e');
    }
  }
  
  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _petsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'No tienes mascotas registradas',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final pets = snapshot.data as List<dynamic>;

        if (pets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'No tienes mascotas registradas',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: List.generate(
            pets.length,
            (index) {
              final pet = pets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PetCard(
                  pet: pet,
                  onPetDeleted: () {
                    // Recargar mascotas cuando se elimina una
                    setState(() {
                      _petsFuture = _loadMyPets();
                    });
                    // Notificar al padre que recargue los stats
                    widget.onPetChanged?.call();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _loadMyPets() async {
    try {
      final user = supabase.auth.currentUser;
      print('🔍 _loadMyPets: user.id = ${user?.id}');
      if (user == null) return [];

      // Obtener mascotas del refugio (refuges.id == users.id, así que usamos user.id directamente)
      final pets = await supabase
          .from('pets')
          .select('id, name, species, refuge_id, created_at, photo_url, age_in_months, breed')
          .eq('refuge_id', user.id);

      print('🔍 _loadMyPets: Mascotas encontradas: ${pets.length}');
      for (var pet in pets) {
        print('  - ${pet['name']} (refuge_id: ${pet['refuge_id']})');
      }

      return pets;
    } catch (e) {
      print('=== ERROR CARGANDO MASCOTAS ===');
      print('Error: $e');
      rethrow;
    }
  }
}

class _PetCard extends StatefulWidget {
  final dynamic pet;
  final VoidCallback? onPetDeleted;

  const _PetCard({
    required this.pet,
    this.onPetDeleted,
  });

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  String _getSpeciesEmoji(String? species) {
    switch (species) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐱';
      case 'rabbit':
        return '🐰';
      case 'bird':
        return '🐦';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1ABC9C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.pet['photo_url'] != null &&
                    widget.pet['photo_url'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.pet['photo_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            _getSpeciesEmoji(widget.pet['species']),
                            style: const TextStyle(fontSize: 40),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      _getSpeciesEmoji(widget.pet['species']),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pet['name'] ?? 'Mascota',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet['age_in_months'] != null && widget.pet['age_in_months'] > 0
                        ? '${PetAgeCalculator.calculateHumanAge(widget.pet['age_in_months'])}'
                        : 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Edad Humana',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1ABC9C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/edit_pet_refuge',
                    arguments: {
                      'pet': widget.pet,
                      'readOnly': true,
                    },
                  ).then((_) => setState(() {}));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF1ABC9C),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/edit_pet_refuge',
                    arguments: {
                      'pet': widget.pet,
                      'readOnly': false,
                    },
                  ).then((_) => setState(() {}));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF1ABC9C),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _deletePet,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deletePet() async {
    final supabase = Supabase.instance.client;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${widget.pet['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await supabase
            .from('pets')
            .delete()
            .eq('id', widget.pet['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mascota eliminada'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {});
          // Notificar al padre que recargue la lista
          widget.onPetDeleted?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
