import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/adoption_requests_sync_service.dart';
import '../../../../core/services/pets_sync_service.dart';

class RefugeAdoptionRequestsPage extends StatefulWidget {
  const RefugeAdoptionRequestsPage({Key? key}) : super(key: key);

  @override
  State<RefugeAdoptionRequestsPage> createState() =>
      _RefugeAdoptionRequestsPageState();
}

class _RefugeAdoptionRequestsPageState
    extends State<RefugeAdoptionRequestsPage> {
  final supabase = Supabase.instance.client;
  int _selectedTabIndex = 0;
  final List<String> tabs = ['Todas', 'Pendientes', 'Aprobadas', 'Rechazadas'];
  final List<String> statuses = ['pending', 'approved', 'rejected'];

  // Servicios como variables para evitar crear nuevas instancias
  late PetsSyncService _petsSyncService;
  late AdoptionRequestsSyncService _adoptionSyncService;
  
  // Referencias a los callbacks para poder removerlos después
  late Function(Map<String, dynamic>) _petsSyncCallback;
  late Function(Map<String, dynamic>) _adoptionSyncCallback;

  @override
  void initState() {
    super.initState();
    
    // Obtener referencias a los servicios singleton
    _petsSyncService = PetsSyncService();
    _adoptionSyncService = AdoptionRequestsSyncService();
    
    // Crear callbacks con referencias permanentes
    _petsSyncCallback = (record) {
      print('🔔 [AdoptionRequestsPage] Cambio en mascotas');
      if (mounted) {
        setState(() {
          // Trigger rebuild
        });
      }
    };
    
    _adoptionSyncCallback = (record) {
      print('🔔 [AdoptionRequestsPage] Cambio en solicitudes, recargando');
      if (mounted) {
        setState(() {
          // Trigger rebuild
        });
      }
    };
    
    // Inicializar listeners en background
    _initializeListeners();
  }

  Future<void> _initializeListeners() async {
    try {
      print('🔧 [AdoptionRequestsPage] Iniciando listeners...');
      // 1. Asegurar que los servicios estén escuchando PRIMERO
      await _petsSyncService.startListening();
      print('✅ [AdoptionRequestsPage] PetsSyncService escuchando');
      
      await _adoptionSyncService.startListening();
      print('✅ [AdoptionRequestsPage] AdoptionSyncService escuchando');
      
      // 2. AHORA agregar listeners
      _petsSyncService.addListener(_petsSyncCallback);
      print('✅ [AdoptionRequestsPage] Listener de pets agregado');
      
      _adoptionSyncService.addListener(_adoptionSyncCallback);
      print('✅ [AdoptionRequestsPage] Listener de adoption agregado');
      
      print('✅ [AdoptionRequestsPage] Listeners inicializados correctamente');
    } catch (e) {
      print('❌ [AdoptionRequestsPage] Error inicializando listeners: $e');
    }
  }

  @override
  void dispose() {
    _petsSyncService.removeListener(_petsSyncCallback);
    _adoptionSyncService.removeListener(_adoptionSyncCallback);
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      // Refresh by reloading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        title: const Text(
          'Solicitudes de Adopción',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        color: const Color(0xFF1ABC9C),
        child: Column(
          children: [
            // Filtros como chips
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedTabIndex == index,
                        label: Text(tabs[index]),
                        onSelected: (selected) {
                          setState(() => _selectedTabIndex = index);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF1ABC9C),
                        side: BorderSide(
                          color: _selectedTabIndex == index
                              ? const Color(0xFF1ABC9C)
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedTabIndex == index
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder(
      future: _loadRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF1ABC9C)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final requests = snapshot.data as List<dynamic>;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay solicitudes',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(
                request: request,
                onStatusChanged: () {
                  setState(() {});
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadRequests() async {
    try {
      final user = supabase.auth.currentUser;
      print('=== DEBUG ADOPTION REQUESTS ===');
      print('User ID: ${user?.id}');
      print('User Email: ${user?.email}');
      
      if (user == null) {
        print('ERROR: No user authenticated');
        return [];
      }

      print('[1] Searching refuge in DB with id=${user.id}');
      try {
        final refugeData = await supabase
            .from('refuges')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        print('[2] Refuge raw response: $refugeData');
        print('[2] Refuge null?: ${refugeData == null}');

        if (refugeData == null) {
          print('ERROR: No refuge record found for user ${user.id}');
          return [];
        }

        final refugeId = refugeData['id'];
        print('[3] Refuge ID extracted: $refugeId');

        print('[4] Building query for requests, tab=$_selectedTabIndex');
        var query = supabase
            .from('adoption_requests')
            .select(
              'id, status, created_at, user_id, pet_id, refuge_id, users(id, name, email), pets(id, name, species, photo_url)',
            )
            .eq('refuge_id', refugeId);

        if (_selectedTabIndex == 1) {
          query = query.eq('status', 'pending');
          print('[4a] Filtering by status=pending');
        } else if (_selectedTabIndex == 2) {
          query = query.eq('status', 'approved');
          print('[4a] Filtering by status=approved');
        } else if (_selectedTabIndex == 3) {
          query = query.eq('status', 'rejected');
          print('[4a] Filtering by status=rejected');
        }

        print('[5] Executing adoption_requests query...');
        final requests = await query.order('created_at', ascending: false);
        
        print('[6] Requests query response: ${requests.length} requests found');
        for (var i = 0; i < requests.length; i++) {
          final req = requests[i];
          print('[6.${i}] Request: user=${req['users']?['name']} pet=${req['pets']?['name']} status=${req['status']}');
        }
        
        return requests;
      } catch (queryError) {
        print('Query Error: $queryError');
        rethrow;
      }
    } catch (e) {
      print('=== ERROR LOADING REQUESTS ===');
      print('Exception Type: ${e.runtimeType}');
      print('Error: $e');
      return [];
    }
  }
}

class _RequestCard extends StatefulWidget {
  final dynamic request;
  final VoidCallback onStatusChanged;

  const _RequestCard({
    required this.request,
    required this.onStatusChanged,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  final supabase = Supabase.instance.client;
  bool isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.request['status'];
    final statusColor = status == 'approved'
        ? const Color(0xFF1ABC9C)
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
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
                                widget.request['pets']?['name']?[0]
                                        ?.toUpperCase() ??
                                    '🐾',
                                style: const TextStyle(fontSize: 28),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.request['pets']?['name']?[0]?.toUpperCase() ?? '🐾',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'pending'
                            ? 'Pendiente'
                            : status == 'approved'
                                ? 'Aprobada'
                                : 'Rechazada',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () => _updateStatus('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Aprobar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : () => _updateStatus('rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Rechazar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isUpdating = true);

    try {
      await supabase
          .from('adoption_requests')
          .update({'status': newStatus}).eq('id', widget.request['id']);

      widget.onStatusChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved'
                  ? 'Solicitud aprobada'
                  : 'Solicitud rechazada',
            ),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF1ABC9C) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }
}
