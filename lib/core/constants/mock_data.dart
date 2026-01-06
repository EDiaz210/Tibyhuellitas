import '../../features/pets/domain/entities/pet.dart';
import '../../features/refuges/domain/entities/refuge.dart';
import '../../features/auth/domain/entities/user.dart';

class MockData {
  // Mock Pets
  static List<Pet> mockPets = [
    Pet(
      id: 'pet_1',
      name: 'Luna',
      species: PetSpecies.dog,
      breed: 'Labrador Retriever',
      size: PetSize.large,
      ageInMonths: 24,
      gender: 'Hembra',
      description:
          'Luna es una perrita muy cariñosa y juguetona. Adora los paseos y jugar con otros perros.',
      photoUrls: [],
      refugeId: 'refuge_1',
      healthStatus: {
        PetHealthStatus.vaccinated,
        PetHealthStatus.dewormed,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Pet(
      id: 'pet_2',
      name: 'Michi',
      species: PetSpecies.cat,
      breed: 'Persa',
      size: PetSize.small,
      ageInMonths: 12,
      gender: 'Hembra',
      description:
          'Michi es una gatita independiente pero muy cariñosa cuando quiere. Ideal para apartamentos.',
      photoUrls: [],
      refugeId: 'refuge_1',
      healthStatus: {
        PetHealthStatus.vaccinated,
        PetHealthStatus.sterilized,
      },
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Pet(
      id: 'pet_3',
      name: 'Rocky',
      species: PetSpecies.dog,
      breed: 'Pastor Alemán',
      size: PetSize.large,
      ageInMonths: 36,
      gender: 'Macho',
      description:
          'Rocky es un perro energético y leal. Necesita mucho ejercicio y un dueño con experiencia.',
      photoUrls: [],
      refugeId: 'refuge_2',
      healthStatus: {
        PetHealthStatus.vaccinated,
        PetHealthStatus.microchipped,
      },
      additionalNotes: 'Requiere entrenamiento básico',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Pet(
      id: 'pet_4',
      name: 'Pelón',
      species: PetSpecies.dog,
      breed: 'Poodle Mix',
      size: PetSize.small,
      ageInMonths: 8,
      gender: 'Macho',
      description:
          'Pelón es un cachorro juguetón y muy sociable. Perfecto para familias con niños.',
      photoUrls: [],
      refugeId: 'refuge_2',
      healthStatus: {
        PetHealthStatus.vaccinated,
      },
      createdAt: DateTime.now(),
    ),
  ];

  // Mock Refuges
  static List<Refuge> mockRefuges = [
    Refuge(
      id: 'refuge_1',
      name: 'Refugio Patas Felices',
      description:
          'Refugio dedicado al rescate y rehabilitación de mascotas abandonadas. Contamos con personal veterinario y especializado en comportamiento animal.',
      latitude: 4.5709,
      longitude: -74.2973,
      address: 'Av. Carrera 7 #120-20, Bogotá',
      phoneNumber: '+57 300 123 4567',
      email: 'info@patasfelices.org',
      website: 'www.patasfelices.org',
      type: RefugeType.foundation,
      totalPets: 15,
      adoptedPets: 8,
      pendingRequests: 3,
      createdAt: DateTime(2022, 1, 15),
    ),
    Refuge(
      id: 'refuge_2',
      name: 'Casa de Peludos',
      description:
          'Organización sin ánimo de lucro enfocada en el bienestar de animales en situación de calle. Ofrecemos servicios de esterilización y atención veterinaria.',
      latitude: 4.5850,
      longitude: -74.2450,
      address: 'Calle 45 #8-15, Bogotá',
      phoneNumber: '+57 301 987 6543',
      email: 'contact@casadepeludos.com',
      type: RefugeType.foundation,
      totalPets: 22,
      adoptedPets: 15,
      pendingRequests: 5,
      createdAt: DateTime(2021, 6, 20),
    ),
    Refuge(
      id: 'refuge_3',
      name: 'Santuario Animal',
      description: 'Refugio privado especializado en adopciones responsables.',
      latitude: 4.6100,
      longitude: -74.2800,
      address: 'Transversal 25 #67-30, Bogotá',
      phoneNumber: '+57 310 555 8888',
      email: 'santuario@animal.org',
      type: RefugeType.shelter,
      totalPets: 8,
      adoptedPets: 5,
      pendingRequests: 1,
      createdAt: DateTime(2023, 3, 10),
    ),
  ];

  // Mock Users
  static final User mockUser = User(
    id: 'user_1',
    email: 'usuario@example.com',
    name: 'Juan Pérez',
    role: UserRole.adopter,
    createdAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  static final User mockRefugeUser = User(
    id: 'refuge_user_1',
    email: 'refugio@example.com',
    name: 'María García',
    role: UserRole.refuge,
    createdAt: DateTime(2022, 1, 15),
    emailVerified: true,
  );
}
