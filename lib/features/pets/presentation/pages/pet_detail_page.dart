import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    if (widget.userLocation == null || widget.distanceService == null) {
      setState(() => _loadingDistance = false);
      return;
    }

    try {
      final distance = widget.distanceService!.calculateDistance(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
        4.7110, // Será dinámico desde refugio data
        -74.0721, // Será dinámico desde refugio data
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                      // Atributos: Edad, Sexo, Tamaño
                      Row(
                        children: [
                          Expanded(
                            child: _AttributeCard(
                              value: '${(widget.pet.ageInMonths / 12).toStringAsFixed(0)} años',
                              label: 'Edad',
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
                              value: _getSizeLabel(widget.pet.size),
                              label: 'Tamaño',
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
                                  const Text(
                                    'Refugio Patitas Felices',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  _loadingDistance
                                      ? const SizedBox(
                                          height: 12,
                                          width: 50,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        )
                                      : Text(
                                          _distance != null &&
                                                  widget.distanceService !=
                                                      null
                                              ? '${widget.distanceService!.formatDistance(_distance!)} de distancia'
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
                        onPressed: () async {
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
                          backgroundColor: const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        child: const Text(
                          'Solicitar Adopción ❤',
                          style: TextStyle(
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
    );
  }

  String _getSizeLabel(PetSize size) {
    switch (size) {
      case PetSize.small:
        return 'Pequeño';
      case PetSize.medium:
        return 'Medio';
      case PetSize.large:
        return 'Grande';
      default:
        return 'Mediano';
    }
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
