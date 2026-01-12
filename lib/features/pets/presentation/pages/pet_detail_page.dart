import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../domain/entities/pet.dart';
import '../../../../core/services/distance_service.dart';
import '../../../../core/repositories/adoption_requests_repository.dart';
import '../../../../injection_container.dart';

class PetDetailPage extends StatefulWidget {
  final Pet pet;
  final Position? userLocation;
  final DistanceService? distanceService;

  const PetDetailPage({
    Key? key,
    required this.pet,
    this.userLocation,
    this.distanceService,
  }) : super(key: key);

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  bool isFavorite = false;
  double? _distance;
  bool _loadingDistance = true;
  String? _refugeName;
  double? _refugeLatitude;
  double? _refugeLongitude;
  bool _loadingRefugeData = true;
  final supabase = Supabase.instance.client;
  final _distanceService = DistanceService();
  Position? _userLocation;
  bool _loadingUserLocation = true;
  bool _hasExistingRequest = false;
  bool _checkingRequest = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadRefugeData();
    _checkExistingRequest();
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await _distanceService.getCurrentLocation();
      setState(() {
        _userLocation = location;
        _loadingUserLocation = false;
      });
      print('DEBUG PET_DETAIL: User location loaded: ${location?.latitude}, ${location?.longitude}');
    } catch (e) {
      print('ERROR loading user location: $e');
      setState(() => _loadingUserLocation = false);
    }
  }

  Future<void> _loadRefugeData() async {
    try {
      final refugeData = await supabase
          .from('refuges')
          .select('name, address, latitude, longitude')
          .eq('id', widget.pet.refugeId)
          .maybeSingle();

      print('DEBUG PET_DETAIL: Refuge data received: $refugeData');

      if (refugeData != null && mounted) {
        setState(() {
          _refugeName = refugeData['name'] ?? 'Refugio sin nombre';
          _refugeLatitude = (refugeData['latitude'] as num?)?.toDouble();
          _refugeLongitude = (refugeData['longitude'] as num?)?.toDouble();
          _loadingRefugeData = false;
        });
        
        print('DEBUG PET_DETAIL: Refuge data set - Name: $_refugeName, Lat: $_refugeLatitude, Lon: $_refugeLongitude');
        
        // Ahora que tenemos las coordenadas del refugio, esperamos a que se cargue la ubicación del usuario
        // y luego calculamos la distancia
        if (_refugeLatitude != null && _refugeLongitude != null) {
          // Esperamos a que _userLocation se cargue
          await Future.doWhile(() async {
            await Future.delayed(const Duration(milliseconds: 100));
            return _loadingUserLocation;
          });
          
          print('DEBUG PET_DETAIL: User location is now available, calling _calculateDistance');
          _calculateDistance();
        } else {
          print('DEBUG PET_DETAIL: ERROR - Refuge coordinates are null!');
          setState(() => _loadingDistance = false);
        }
      } else {
        print('DEBUG PET_DETAIL: Refuge data is null or widget not mounted');
        setState(() {
          _loadingRefugeData = false;
          _loadingDistance = false;
        });
      }
    } catch (e) {
      print('ERROR loading refuge data: $e');
      if (mounted) {
        setState(() {
          _refugeName = 'Error cargando refugio';
          _loadingRefugeData = false;
          _loadingDistance = false;
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    print('DEBUG PET_DETAIL: _calculateDistance called');
    print('DEBUG PET_DETAIL: userLocation=$_userLocation');
    print('DEBUG PET_DETAIL: distanceService=$_distanceService');
    print('DEBUG PET_DETAIL: refugeLatitude=$_refugeLatitude, refugeLongitude=$_refugeLongitude');
    
    if (_userLocation == null || 
        _refugeLatitude == null ||
        _refugeLongitude == null) {
      print('DEBUG PET_DETAIL: Missing data for distance calculation, setting false');
      setState(() => _loadingDistance = false);
      return;
    }

    try {
      print('DEBUG PET_DETAIL: Calculating distance from (${_userLocation!.latitude}, ${_userLocation!.longitude}) to ($_refugeLatitude, $_refugeLongitude)');
      
      final distance = _distanceService.calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        _refugeLatitude!,
        _refugeLongitude!,
      );

      print('DEBUG PET_DETAIL: Distance calculated: $distance');
      
      setState(() {
        _distance = distance;
        _loadingDistance = false;
      });
      
      print('DEBUG PET_DETAIL: Distance state updated to $_distance');
    } catch (e) {
      print('ERROR calculating distance: $e');
      setState(() => _loadingDistance = false);
    }
  }

  Future<void> _checkExistingRequest() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _checkingRequest = false);
        return;
      }

      final result = await supabase
          .from('adoption_requests')
          .select('status')
          .eq('user_id', user.id)
          .eq('pet_id', widget.pet.id)
          .maybeSingle();

      if (mounted) {
        // Solo bloquear si existe una solicitud Y el estado es pending o approved
        // Si fue rechazada, permitir enviar de nuevo
        _hasExistingRequest = result != null && 
            (result['status'] == 'pending' || result['status'] == 'approved');
        
        setState(() {
          _checkingRequest = false;
        });
      }

      print('DEBUG PET_DETAIL: User has active request for this pet: $_hasExistingRequest (status: ${result?['status']})');
    } catch (e) {
      print('ERROR checking existing request: $e');
      if (mounted) {
        setState(() => _checkingRequest = false);
      }
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadRefugeData();
          _loadUserLocation();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Imagen grande con fondo coloreado
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: bgColor,
                  ),
                  child: Center(
                    child: widget.pet.photoUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.pet.photoUrls.first,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.pets,
                                  size: 80,
                                  color: Color(0xFFFF6B35),
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.pets,
                            size: 80,
                            color: Color(0xFFFF6B35),
                          ),
                  ),
                ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + Tag Disponible
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.pet.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1ABC9C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Disponible',
                              style: TextStyle(
                                color: Color(0xFF1ABC9C),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Raza
                      Text(
                        widget.pet.breed,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Atributos: Edad Humana, Sexo, Raza
                      Row(
                        children: [
                          Expanded(
                            child: _AttributeCard(
                              value: _calculateHumanAge(widget.pet.ageInMonths),
                              label: 'Edad Humana',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AttributeCard(
                              value: widget.pet.gender == 'Hembra'
                                  ? 'Hembra'
                                  : 'Macho',
                              label: 'Sexo',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AttributeCard(
                              value: widget.pet.breed,
                              label: 'Raza',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Refugio
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1ABC9C).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
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
                                  Text(
                                    _refugeName ?? 'Cargando refugio...',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _loadingDistance || _loadingRefugeData || _loadingUserLocation
                                      ? const SizedBox(
                                          height: 12,
                                          width: 50,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        )
                                      : Text(
                                          _distance != null
                                              ? '${_distanceService.formatDistance(_distance!)} de distancia'
                                              : 'Sin información de distancia',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Color(0xFF1ABC9C),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sobre la mascota
                      Text(
                        'Sobre ${widget.pet.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.pet.description.isNotEmpty
                            ? widget.pet.description
                            : 'Esta es una mascota adorable que está lista para encontrar su nuevo hogar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botón Solicitar Adopción - DENTRO DEL SCROLL
                      ElevatedButton(
                        onPressed: _checkingRequest || _hasExistingRequest ? null : () async {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Debes iniciar sesión primero'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            final adoptionRepository = getIt<AdoptionRequestsRepository>();
                            await adoptionRepository.createAdoptionRequest(
                              user.id,
                              widget.pet.id,
                              widget.pet.refugeId,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Solicitud de adopción enviada! 🎉'),
                                  backgroundColor: Color(0xFFFF6B35),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              // Esperar a que se cierre el SnackBar y luego ir a Solicitudes
                              await Future.delayed(const Duration(seconds: 2));
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al enviar solicitud: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasExistingRequest 
                            ? Colors.grey 
                            : const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        child: Text(
                          _checkingRequest
                            ? 'Verificando...'
                            : _hasExistingRequest
                              ? 'Ya tiene solicitud para esta mascota'
                              : 'Solicitar Adopción ❤',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botones superiores (Atrás y Favorito)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() => isFavorite = !isFavorite);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }

  String _calculateHumanAge(int ageInMonths) {
    double humanAge;
    
    if (ageInMonths < 12) {
      // Para perros menores a 12 meses: (meses / 12) × 15
      // 9 meses = (9/12) × 15 = 11.25 años (12-14 años humanos)
      humanAge = (ageInMonths / 12.0) * 15.0;
    } else {
      // Para perros 12+ meses: Edad humana = 16 × ln(edad en años) + 31
      double ageInYears = ageInMonths / 12.0;
      humanAge = 16 * log(ageInYears) + 31;
    }
    
    // Retornar con un decimal
    return humanAge.toStringAsFixed(1);
  }
}

class _AttributeCard extends StatelessWidget {
  final String value;
  final String label;

  const _AttributeCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
