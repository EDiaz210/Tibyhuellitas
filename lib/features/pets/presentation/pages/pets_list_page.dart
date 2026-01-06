import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/pet.dart';
import '../bloc/pet_bloc.dart';
import 'pet_detail_page.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/distance_service.dart';

class PetsListPage extends StatefulWidget {
  const PetsListPage({Key? key}) : super(key: key);

  @override
  State<PetsListPage> createState() => _PetsListPageState();
}

class _PetsListPageState extends State<PetsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'todos'; // todos, dog, cat
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();
  final DistanceService _distanceService = DistanceService();
  late Future<List<String>> _favoritesFuture;
  Set<String> _localFavorites = {}; // Cache local de favoritos
  Position? _userLocation;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _initializeUserLocation();
  }

  Future<void> _initializeUserLocation() async {
    try {
      final location = await _distanceService.getCurrentLocation();
      setState(() {
        _userLocation = location;
        _loadingLocation = false;
      });
    } catch (e) {
      print('Error getting user location: $e');
      setState(() => _loadingLocation = false);
    }
  }

  void _loadFavorites() {
    _favoritesFuture = _favoritesService.getUserFavorites().then((favorites) {
      setState(() {
        _localFavorites = favorites.toSet();
      });
      return favorites;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String filter) {
    _searchController.clear();
    setState(() => _selectedFilter = filter);
    final event = filter == 'todos'
        ? const FetchAllPets()
        : SearchPetsEvent(
            query: '',
            speciesFilter: filter == 'dog' ? 'dog' : 'cat',
          );
    context.read<PetBloc>().add(event);
  }

  void _toggleFavorite(String petId) async {
    final isFavorite = _localFavorites.contains(petId);
    
    setState(() {
      if (isFavorite) {
        _localFavorites.remove(petId);
      } else {
        _localFavorites.add(petId);
      }
    });

    if (isFavorite) {
      await _favoritesService.removeFavorite(petId);
    } else {
      await _favoritesService.addFavorite(petId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con saludo y notificaciones
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hola, ${_authService.currentUserName} 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {},
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Título
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Encuentra tu mascota',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Search bar + Filter button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          context.read<PetBloc>().add(
                            SearchPetsEvent(
                              query: query,
                              speciesFilter: _selectedFilter == 'todos' ? null : _selectedFilter,
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar mascota...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
              const SizedBox(height: 16),
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      isSelected: _selectedFilter == 'todos',
                      onTap: () => _applyFilter('todos'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '🐕 Perros',
                      isSelected: _selectedFilter == 'dog',
                      onTap: () => _applyFilter('dog'),
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: '🐈 Gatos',
                      isSelected: _selectedFilter == 'cat',
                      onTap: () => _applyFilter('cat'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Pets grid
              BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  if (state is PetLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (state is PetLoaded && state.pets.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: state.pets.length,
                        itemBuilder: (context, index) {
                          final pet = state.pets[index];
                          final isFavorite = _localFavorites.contains(pet.id);
                          return _PetGridCard(
                            pet: pet,
                            isFavorite: isFavorite,
                            onFavoriteToggle: _toggleFavorite,
                            userLocation: _userLocation,
                            distanceService: _distanceService,
                          );
                        },
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        state is PetError
                            ? 'Error: ${(state).message}'
                            : 'No se encontraron mascotas',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6B35)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B35)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PetGridCard extends StatefulWidget {
  final Pet pet;
  final bool isFavorite;
  final Function(String) onFavoriteToggle;
  final Position? userLocation;
  final DistanceService distanceService;

  const _PetGridCard({
    required this.pet,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.userLocation,
    required this.distanceService,
  });

  @override
  State<_PetGridCard> createState() => _PetGridCardState();
}

class _PetGridCardState extends State<_PetGridCard> {
  double? _distance;
  bool _loadingDistance = true;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    if (widget.userLocation == null) {
      setState(() => _loadingDistance = false);
      return;
    }

    try {
      final distance = widget.distanceService.calculateDistance(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        4.7110, // Latitud del refugio (será dinámica después)
        -74.0721, // Longitud del refugio (será dinámica después)
      );

      setState(() {
        _distance = distance;
        _loadingDistance = false;
      });
    } catch (e) {
      print('Error calculating distance: $e');
      setState(() => _loadingDistance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores alternados para las tarjetas
    final colors = [
      const Color(0xFFFFF9E6), // Amarillo suave
      const Color(0xFFE6F3FF), // Azul suave
      const Color(0xFFFFF0F6), // Rosa suave
      const Color(0xFFE6F9F9), // Cian suave
    ];
    final bgColor = colors[widget.pet.name.length % colors.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailPage(
              pet: widget.pet,
              userLocation: widget.userLocation,
              distanceService: widget.distanceService,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: widget.pet.photoUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          widget.pet.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: Color(0xFFFF6B35),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.pets,
                          size: 40,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onFavoriteToggle(widget.pet.id),
                          child: Icon(
                            widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.pet.breed} • ${(widget.pet.ageInMonths / 12).toStringAsFixed(0)} años',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: _loadingDistance
                              ? const SizedBox(
                                  height: 12,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : Text(
                                  _distance != null
                                      ? widget.distanceService
                                          .formatDistance(_distance!)
                                      : 'Sin ubicación',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
