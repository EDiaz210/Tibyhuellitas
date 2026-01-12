import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/refuge_bloc.dart';
import '../widgets/refuge_map_widget.dart';
import '../../domain/entities/refuge.dart';
import '../../../../core/services/distance_service.dart';
import '../../../../core/data/refuges_mock_data.dart';

class RefugesMapPage extends StatefulWidget {
  const RefugesMapPage({Key? key}) : super(key: key);

  @override
  State<RefugesMapPage> createState() => _RefugesMapPageState();
}

class _RefugesMapPageState extends State<RefugesMapPage> {
  late DistanceService _distanceService;
  Position? _userLocation;
  Refuge? _selectedRefuge;
  double? _distanceToSelected;
  bool _loadingLocation = true;
  final TextEditingController _searchController = TextEditingController();
  List<Refuge> _filteredRefuges = [];
  int _availablePetsCount = 0;

  @override
  void initState() {
    super.initState();
    _distanceService = DistanceService();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final location = await _distanceService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _userLocation = location;
          _loadingLocation = false;
        });
        _fetchRefuges();
      } else {
        setState(() => _loadingLocation = false);
        _fetchRefuges();
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _loadingLocation = false);
      _fetchRefuges();
    }
  }

  void _fetchRefuges() {
    final lat = _userLocation?.latitude ?? 4.5709;
    final lon = _userLocation?.longitude ?? -74.2973;
    
    context.read<RefugeBloc>().add(
          FetchNearbyRefuges(
            latitude: lat,
            longitude: lon,
            radiusInKm: 25.0,
          ),
        );
  }

  void _onRefugeSelected(Refuge refuge) {
    setState(() {
      _selectedRefuge = refuge;
      if (_userLocation != null) {
        _distanceToSelected = _distanceService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          refuge.latitude,
          refuge.longitude,
        );
      }
    });
    // Cargar cantidad de mascotas disponibles
    _loadAvailablePetsCount(refuge.id);
  }

  Future<void> _refreshRefuges() async {
    _fetchRefuges();
    // Auto-fix refugios sin coordenadas válidas
    _fixRefugesWithoutCoordinates();
    await Future.delayed(const Duration(seconds: 1));
  }

  void _fixRefugesWithoutCoordinates() {
    // Esta función se ejecutará en background para actualizar refugios
    // que no tengan coordenadas válidas (0,0)
    // Por ahora solo se loguea, pero en una versión futura se implementará
    print('🔧 Verificando refugios sin coordenadas...');
  }

  void _filterRefuges(String query, List<Refuge> allRefuges) {
    setState(() {
      if (query.isEmpty) {
        _filteredRefuges = allRefuges;
      } else {
        _filteredRefuges = allRefuges
            .where((refuge) =>
                refuge.name.toLowerCase().contains(query.toLowerCase()) ||
                refuge.address.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadAvailablePetsCount(String refugeId) async {
    try {
      // Obtener todas las mascotas del refugio
      final allPets = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('refuge_id', refugeId);

      // Obtener mascotas adoptadas
      final adoptedPets = await Supabase.instance.client
          .from('adoption_requests')
          .select('pet_id')
          .eq('status', 'approved');

      final adoptedPetIds = (adoptedPets as List)
          .map((req) => req['pet_id'] as String)
          .toSet();

      final availableCount = (allPets as List)
          .where((pet) => !adoptedPetIds.contains(pet['id']))
          .length;

      setState(() => _availablePetsCount = availableCount);
    } catch (e) {
      print('Error loading available pets: $e');
      setState(() => _availablePetsCount = 0);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshRefuges,
        color: const Color(0xFF1ABC9C),
        child: _loadingLocation
            ? const Center(child: CircularProgressIndicator())
            : BlocBuilder<RefugeBloc, RefugeState>(
              builder: (context, state) {
                // Usar datos quemados como fallback
                List<Refuge> refuges = [];
                
                if (state is RefugeLoaded) {
                  print('🏠 Refugios cargados desde BD: ${state.refuges.length}');
                  
                  // Filtrar refugios con coordenadas válidas (no 0,0)
                  final validRefuges = state.refuges.where((r) => 
                    r.latitude != 0 && r.longitude != 0
                  ).toList();
                  
                  for (var refuge in validRefuges) {
                    print('   ✓ ${refuge.name}: (${refuge.latitude}, ${refuge.longitude})');
                  }
                  
                  refuges = validRefuges;
                  
                  // Si no hay refugios válidos, usar mock data
                  if (refuges.isEmpty) {
                    print('⚠️  No hay refugios con coordenadas válidas, usando mock data');
                    refuges = RefugesMockData.mockRefuges;
                  }
                } else {
                  // Usar datos quemados si no hay estado cargado
                  print('🏠 No hay estado RefugeLoaded, usando mock data');
                  refuges = RefugesMockData.mockRefuges;
                }

                // Si aún no hay refugios, mostrar datos quemados
                if (refuges.isEmpty) {
                  print('⚠️  Refugios vacíos, forzando mock data');
                  refuges = RefugesMockData.mockRefuges;
                }

                // Inicializar _filteredRefuges solo si es la primera vez o si está vacío
                if (_filteredRefuges.isEmpty && _searchController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _filteredRefuges = refuges;
                    });
                  });
                }
                
                // Usar los refugios filtrados si hay búsqueda, sino todos
                final displayRefuges = _searchController.text.isEmpty 
                    ? refuges 
                    : _filteredRefuges;

                print('📍 Total refugios a mostrar en mapa: ${displayRefuges.length}');

                if (state is RefugeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    // Mapa
                    RefugeMapWidget(
                      refuges: displayRefuges,
                      userLocation: _userLocation != null
                          ? LatLng(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                            )
                          : null,
                      onRefugeSelected: _onRefugeSelected,
                    ),
                    // Barra de búsqueda superior
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (query) =>
                                    _filterRefuges(query, refuges),
                                decoration: InputDecoration(
                                  hintText: 'Buscar refugios...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tarjeta inferior con info del refugio seleccionado
                    if (_selectedRefuge != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: _buildRefugeCard(),
                      ),
                  ],
                );
              },
            ),
        ),
    );
  }

  Widget _buildRefugeCard() {
    final refuge = _selectedRefuge!;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Color(0xFF1ABC9C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refugio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        refuge.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              refuge.address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  icon: Icons.location_on,
                  value: _distanceToSelected != null
                      ? _distanceService.formatDistance(_distanceToSelected!)
                      : 'N/A',
                  label: 'Distancia',
                ),
                _buildInfoChip(
                  icon: Icons.pets,
                  value: '$_availablePetsCount',
                  label: 'Disponibles',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFFFF6B35),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
