import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'core/network/network_info.dart';
import 'core/services/location_service.dart';
import 'core/services/geocoding_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/gemini_service.dart';
import 'core/repositories/chat_repository.dart';
import 'core/repositories/adoption_requests_repository.dart';
import 'core/repositories/user_repository.dart';
import 'core/error/failures.dart';
import 'core/usecases/usecase.dart';

// BLoCs
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/pets/presentation/bloc/pet_bloc.dart';
import 'features/refuges/presentation/bloc/refuge_bloc.dart';

// Use Cases & Entities
import 'features/pets/domain/usecases/pet_usecases.dart';
import 'features/refuges/domain/usecases/refuge_usecases.dart';
import 'features/pets/domain/entities/pet.dart';
import 'features/refuges/domain/entities/refuge.dart';

final getIt = GetIt.instance;

/// Configure all dependencies for the application
void configureDependencies() {
  // ============ Core Services ============
  
  // Register Connectivity
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Register NetworkInfo
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(Connectivity()),
  );

  // Register Supabase Client - safely handle initialization
  try {
    final supabase = Supabase.instance.client;
    getIt.registerLazySingleton<SupabaseClient>(() => supabase);
  } catch (e) {
    debugPrint('⚠️ Warning: Supabase not initialized, using mock client');
    // Fallback: register a dummy client that won't be used
    getIt.registerLazySingleton<SupabaseClient>(
      () => throw Exception('Supabase not initialized'),
    );
  }

  // Register Location Service
  getIt.registerLazySingleton<LocationService>(
    () => LocationServiceImpl(),
  );

  // Register Geocoding Service
  getIt.registerLazySingleton<GeocodingService>(
    () => GeocodingServiceImpl(),
  );

  // Register Notification Service
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(),
  );

  // Register Gemini Service
  String geminiApiKey = '';
  try {
    geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load GEMINI_API_KEY from .env');
  }
  debugPrint('🔐 Gemini API Key: ${geminiApiKey.isNotEmpty ? 'Cargada correctamente' : 'NO ENCONTRADA'}');
  
  // Register ChatRepository
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(supabase: getIt<SupabaseClient>()),
  );
  
  // Register AdoptionRequestsRepository
  getIt.registerLazySingleton<AdoptionRequestsRepository>(
    () => AdoptionRequestsRepositoryImpl(supabase: getIt<SupabaseClient>()),
  );

  // Register UserRepository
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(supabase: getIt<SupabaseClient>()),
  );
  
  getIt.registerLazySingleton<GeminiService>(
    () => GeminiServiceImpl(
      apiKey: geminiApiKey,
      chatRepository: getIt<ChatRepository>(),
    ),
  );

  // ============ BLoCs ============
  
  // Register Location BLoC
  getIt.registerSingleton<LocationBloc>(
    LocationBloc(locationService: getIt<LocationService>()),
  );

  // Register Pet BLoC with Supabase-backed use cases
  getIt.registerSingleton<PetBloc>(
    PetBloc(
      getAllPets: SupabaseGetAllPets(supabase: () => _getSupabaseClient()),
      getPetById: SupabaseGetPetById(supabase: () => _getSupabaseClient()),
      searchPets: SupabaseSearchPets(supabase: () => _getSupabaseClient()),
    ),
  );

  // Register Refuge BLoC with Supabase-backed use cases
  getIt.registerSingleton<RefugeBloc>(
    RefugeBloc(
      getAllRefuges: SupabaseGetAllRefuges(supabase: () => _getSupabaseClient()),
      getNearbyRefuges: SupabaseGetNearbyRefuges(supabase: () => _getSupabaseClient()),
    ),
  );
}

/// Helper function to get Supabase client safely
SupabaseClient _getSupabaseClient() {
  try {
    return Supabase.instance.client;
  } catch (e) {
    throw Exception('Supabase not initialized: $e');
  }
}

// ============ Supabase-Backed Use Cases ============

class SupabaseGetAllPets implements GetAllPets {
  final SupabaseClient Function() supabase;

  SupabaseGetAllPets({required this.supabase});

  @override
  Future<Either<Failure, List<Pet>>> call(NoParams params) async {
    try {
      final response = await supabase().from('pets').select();
      final pets = (response as List).map((pet) {
        return Pet(
          id: pet['id'] as String,
          name: pet['name'] as String,
          species: _parseSpecies(pet['species'] as String),
          breed: pet['breed'] as String? ?? 'Raza desconocida',
          size: _parseSize(pet['size'] as String?),
          ageInMonths: pet['age_in_months'] as int? ?? 0,
          gender: pet['gender'] as String? ?? 'No especificado',
          description: pet['description'] as String? ?? '',
          photoUrls: List<String>.from(pet['photo_urls'] as List? ?? []),
          refugeId: pet['refuge_id'] as String,
          healthStatus: _parseHealthStatus(pet['health_status'] as List? ?? []),
          additionalNotes: pet['additional_notes'] as String?,
          createdAt: DateTime.parse(pet['created_at'] as String),
        );
      }).toList();
      return Right(pets);
    } catch (e) {
      print('Error fetching pets: $e');
      return Left(ServerFailure('Error fetching pets: $e'));
    }
  }

  @override
  PetRepository get repository => throw UnimplementedError();
}

class SupabaseGetPetById implements GetPetById {
  final SupabaseClient Function() supabase;

  SupabaseGetPetById({required this.supabase});

  @override
  Future<Either<Failure, Pet>> call(String petId) async {
    try {
      final response = await supabase()
          .from('pets')
          .select()
          .eq('id', petId)
          .single();

      final pet = Pet(
        id: response['id'] as String,
        name: response['name'] as String,
        species: _parseSpecies(response['species'] as String),
        breed: response['breed'] as String? ?? 'Raza desconocida',
        size: _parseSize(response['size'] as String?),
        ageInMonths: response['age_in_months'] as int? ?? 0,
        gender: response['gender'] as String? ?? 'No especificado',
        description: response['description'] as String? ?? '',
        photoUrls: List<String>.from(response['photo_urls'] as List? ?? []),
        refugeId: response['refuge_id'] as String,
        healthStatus: _parseHealthStatus(response['health_status'] as List? ?? []),
        additionalNotes: response['additional_notes'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
      return Right(pet);
    } catch (e) {
      print('Error fetching pet: $e');
      return Left(ServerFailure('Error fetching pet: $e'));
    }
  }

  @override
  PetRepository get repository => throw UnimplementedError();
}

class SupabaseSearchPets implements SearchPets {
  final SupabaseClient Function() supabase;

  SupabaseSearchPets({required this.supabase});

  @override
  Future<Either<Failure, List<Pet>>> call(SearchPetsParams params) async {
    try {
      var query = supabase().from('pets').select();

      if (params.speciesFilter != null) {
        query = query.eq('species', params.speciesFilter!);
      }
      if (params.sizeFilter != null) {
        query = query.eq('size', params.sizeFilter!);
      }

      final response = await query;
      final pets = (response as List)
          .map((pet) {
            return Pet(
              id: pet['id'] as String,
              name: pet['name'] as String,
              species: _parseSpecies(pet['species'] as String),
              breed: pet['breed'] as String? ?? 'Raza desconocida',
              size: _parseSize(pet['size'] as String?),
              ageInMonths: pet['age_in_months'] as int? ?? 0,
              gender: pet['gender'] as String? ?? 'No especificado',
              description: pet['description'] as String? ?? '',
              photoUrls: List<String>.from(pet['photo_urls'] as List? ?? []),
              refugeId: pet['refuge_id'] as String,
              healthStatus: _parseHealthStatus(pet['health_status'] as List? ?? []),
              additionalNotes: pet['additional_notes'] as String?,
              createdAt: DateTime.parse(pet['created_at'] as String),
            );
          })
          .where((pet) =>
              pet.name.toLowerCase().contains(params.query.toLowerCase()) ||
              pet.breed.toLowerCase().contains(params.query.toLowerCase()))
          .toList();

      return Right(pets);
    } catch (e) {
      print('Error searching pets: $e');
      return Left(ServerFailure('Error searching pets: $e'));
    }
  }

  @override
  PetRepository get repository => throw UnimplementedError();
}

class SupabaseGetAllRefuges implements GetAllRefuges {
  final SupabaseClient Function() supabase;

  SupabaseGetAllRefuges({required this.supabase});

  @override
  Future<Either<Failure, List<Refuge>>> call(NoParams params) async {
    try {
      final response = await supabase().from('refuges').select();
      final refuges = (response as List).map((refuge) {
        return Refuge(
          id: refuge['id'] as String,
          name: refuge['name'] as String,
          description: refuge['description'] as String? ?? '',
          latitude: (refuge['latitude'] as num).toDouble(),
          longitude: (refuge['longitude'] as num).toDouble(),
          address: refuge['address'] as String,
          phoneNumber: refuge['phone_number'] as String?,
          email: refuge['email'] as String?,
          website: refuge['website'] as String?,
          type: _parseRefugeType(refuge['type'] as String?),
          logoUrl: refuge['logo_url'] as String?,
          totalPets: refuge['total_pets'] as int? ?? 0,
          adoptedPets: refuge['adopted_pets'] as int? ?? 0,
          pendingRequests: refuge['pending_requests'] as int? ?? 0,
          createdAt: DateTime.parse(refuge['created_at'] as String),
        );
      }).toList();
      return Right(refuges);
    } catch (e) {
      return Left(ServerFailure('Error fetching refuges: $e'));
    }
  }

  @override
  RefugeRepository get repository => throw UnimplementedError();
}

class SupabaseGetNearbyRefuges implements GetNearbyRefuges {
  final SupabaseClient Function() supabase;

  SupabaseGetNearbyRefuges({required this.supabase});

  @override
  Future<Either<Failure, List<Refuge>>> call(
      GetNearbyRefugesParams params) async {
    try {
      final response = await supabase().from('refuges').select();
      final refuges = (response as List)
          .map((refuge) {
            return Refuge(
              id: refuge['id'] as String,
              name: refuge['name'] as String,
              description: refuge['description'] as String? ?? '',
              latitude: (refuge['latitude'] as num).toDouble(),
              longitude: (refuge['longitude'] as num).toDouble(),
              address: refuge['address'] as String,
              phoneNumber: refuge['phone_number'] as String?,
              email: refuge['email'] as String?,
              website: refuge['website'] as String?,
              type: _parseRefugeType(refuge['type'] as String?),
              logoUrl: refuge['logo_url'] as String?,
              totalPets: refuge['total_pets'] as int? ?? 0,
              adoptedPets: refuge['adopted_pets'] as int? ?? 0,
              pendingRequests: refuge['pending_requests'] as int? ?? 0,
              createdAt: DateTime.parse(refuge['created_at'] as String),
            );
          })
          .where((refuge) {
            final distance = _calculateDistance(
              params.latitude,
              params.longitude,
              refuge.latitude,
              refuge.longitude,
            );
            return distance <= params.radiusInKm;
          })
          .toList();

      return Right(refuges);
    } catch (e) {
      return Left(ServerFailure('Error fetching nearby refuges: $e'));
    }
  }

  @override
  RefugeRepository get repository => throw UnimplementedError();
}

// ============ Helper Functions ============

PetSpecies _parseSpecies(String species) {
  switch (species.toLowerCase()) {
    case 'dog':
      return PetSpecies.dog;
    case 'cat':
      return PetSpecies.cat;
    case 'rabbit':
      return PetSpecies.rabbit;
    case 'bird':
      return PetSpecies.bird;
    default:
      return PetSpecies.other;
  }
}

PetSize _parseSize(String? size) {
  switch (size?.toLowerCase()) {
    case 'small':
      return PetSize.small;
    case 'medium':
      return PetSize.medium;
    case 'large':
      return PetSize.large;
    default:
      return PetSize.medium;
  }
}

RefugeType _parseRefugeType(String? type) {
  switch (type?.toLowerCase()) {
    case 'shelter':
      return RefugeType.shelter;
    case 'foundation':
      return RefugeType.foundation;
    case 'privaterescue':
      return RefugeType.privateRescue;
    default:
      return RefugeType.shelter;
  }
}

Set<PetHealthStatus> _parseHealthStatus(List<dynamic> statuses) {
  final result = <PetHealthStatus>{};
  for (final status in statuses) {
    switch (status.toString().toLowerCase()) {
      case 'vaccinated':
        result.add(PetHealthStatus.vaccinated);
        break;
      case 'dewormed':
        result.add(PetHealthStatus.dewormed);
        break;
      case 'sterilized':
        result.add(PetHealthStatus.sterilized);
        break;
      case 'microchipped':
        result.add(PetHealthStatus.microchipped);
        break;
      case 'special_needs':
        result.add(PetHealthStatus.specialCare);
        break;
    }
  }
  return result;
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371;
  final double dLat = _toRad(lat2 - lat1);
  final double dLon = _toRad(lon2 - lon1);
  final double a = (sin(dLat / 2) * sin(dLat / 2)) +
      (cos(_toRad(lat1)) *
          cos(_toRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2));
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRad(double deg) => deg * (3.14159 / 180);
