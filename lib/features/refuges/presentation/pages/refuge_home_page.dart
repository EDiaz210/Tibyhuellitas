import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../injection_container.dart';
import '../../../../core/repositories/adoption_requests_repository.dart';
import '../../../../core/services/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    adoptionRepository = getIt<AdoptionRequestsRepository>();
    _loadRefugeData();
  }

  Future<void> _loadRefugeData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Obtener datos del refugio
      final refugeData = await supabase
          .from('refuges')
          .select('name, id')
          .eq('id', user.id)
          .maybeSingle();

      if (refugeData != null) {
        final refugeId = refugeData['id'];

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
      body: SingleChildScrollView(
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
                  _RecentRequestsCard(),
                  const SizedBox(height: 24),
                  // Mis Mascotas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mis Mascotas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/refuge_pets');
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1ABC9C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Agregar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _MyPetsCard(),
                ],
              ),
            ),
          ],
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
  @override
  State<_RecentRequestsCard> createState() => _RecentRequestsCardState();
}

class _RecentRequestsCardState extends State<_RecentRequestsCard> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadRecentRequests(),
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
                    setState(() {});
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
            'id, status, created_at, users(name), pets(name, photo_urls)',
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
      await supabase
          .from('adoption_requests')
          .update({'status': newStatus})
          .eq('id', widget.request['id']);

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
            child: Center(
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
                  onTap: widget.request['status'] != 'approved'
                      ? () => _updateStatus('approved')
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.request['status'] == 'approved'
                          ? const Color(0xFF1ABC9C)
                          : const Color(0xFF1ABC9C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.check,
                      color: widget.request['status'] == 'approved'
                          ? Colors.white
                          : const Color(0xFF1ABC9C),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.request['status'] != 'rejected'
                      ? () => _updateStatus('rejected')
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.request['status'] == 'rejected'
                          ? Colors.red
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: widget.request['status'] == 'rejected'
                          ? Colors.white
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
  @override
  State<_MyPetsCard> createState() => _MyPetsCardState();
}

class _MyPetsCardState extends State<_MyPetsCard> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadMyPets(),
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
                child: _PetCard(pet: pet),
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
      print('=== DEBUG: Usuario actual ===');
      print('User ID: ${user?.id}');
      print('User email: ${user?.email}');
      
      if (user == null) {
        print('ERROR: No hay usuario autenticado');
        return [];
      }

      final refugeData = await supabase
          .from('refuges')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      print('=== DEBUG: Datos del refugio ===');
      print('Refugio data: $refugeData');
      print('Refugio ID: ${refugeData?['id']}');

      if (refugeData == null) {
        print('ERROR: No se encontró refugio para este usuario');
        return [];
      }

      print('\n=== DEBUG: Buscando mascotas ===');
      print('Buscando con refuge_id: ${refugeData['id']}');

      final pets = await supabase
          .from('pets')
          .select('id, name, species, refuge_id, created_at')
          .eq('refuge_id', refugeData['id']);

      print('Total de mascotas encontradas: ${pets.length}');
      for (var pet in pets) {
        print('- Mascota: ${pet['name']} (${pet['species']}) - ID: ${pet['id']}');
      }

      // DEBUG: Obtener TODAS las mascotas sin filtro
      print('\n=== DEBUG: Verificando TODAS las mascotas en la tabla ===');
      final allPets = await supabase.from('pets').select('id, name, refuge_id');
      print('Total de mascotas en la tabla (sin filtro): ${allPets.length}');
      for (var pet in allPets) {
        print('- ID: ${pet['id']} | Nombre: ${pet['name']} | Refuge ID: ${pet['refuge_id']}');
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

  const _PetCard({required this.pet});

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
            child: Center(
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
                    arguments: widget.pet,
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
                    arguments: widget.pet,
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
