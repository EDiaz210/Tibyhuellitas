import '../../features/refuges/domain/entities/refuge.dart';

/// Datos quemados de refugios para pruebas locales
class RefugesMockData {
  static final List<Refuge> mockRefuges = [
    Refuge(
      id: '550e8400-e29b-41d4-a716-446655440000',
      name: 'Patitas Felices',
      description: 'Refugio especializado en rescate y adopción de perros y gatos',
      latitude: 4.7110,
      longitude: -74.0721,
      address: 'Carrera 10 #20-30, Bogotá',
      phoneNumber: '+57 310 1234567',
      email: 'patitas@tibyhuellitas.com',
      website: null,
      type: RefugeType.shelter,
      logoUrl: null,
      totalPets: 15,
      adoptedPets: 8,
      pendingRequests: 3,
      createdAt: DateTime.now(),
    ),
    Refuge(
      id: '550e8400-e29b-41d4-a716-446655440001',
      name: 'Hogar Seguro',
      description: 'Fundación dedicada al rescate y rehabilitación de animales en peligro',
      latitude: 4.6097,
      longitude: -74.0817,
      address: 'Avenida Caracas #45-60, Bogotá',
      phoneNumber: '+57 301 9876543',
      email: 'hogarseguro@tibyhuellitas.com',
      website: null,
      type: RefugeType.foundation,
      logoUrl: null,
      totalPets: 8,
      adoptedPets: 5,
      pendingRequests: 2,
      createdAt: DateTime.now(),
    ),
    Refuge(
      id: '550e8400-e29b-41d4-a716-446655440002',
      name: 'Amor Felino',
      description: 'Centro especializado en rescate de gatos callejeros',
      latitude: 4.7200,
      longitude: -74.0500,
      address: 'Calle 80 #15-45, Bogotá',
      phoneNumber: '+57 320 5555555',
      email: 'amorfelino@tibyhuellitas.com',
      website: null,
      type: RefugeType.privateRescue,
      logoUrl: null,
      totalPets: 12,
      adoptedPets: 6,
      pendingRequests: 1,
      createdAt: DateTime.now(),
    ),
  ];

  /// Obtiene refugios cercanos (simulado con datos quemados)
  static List<Refuge> getNearbyRefuges(
    double userLat,
    double userLon,
    double radiusInKm,
  ) {
    // Retorna todos los refugios quemados
    // En producción, esto vendría de Supabase
    return mockRefuges;
  }
}
