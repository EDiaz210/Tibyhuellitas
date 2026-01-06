import 'package:equatable/equatable.dart';

enum PetSpecies { dog, cat, bird, rabbit, other }

enum PetSize { small, medium, large }

enum PetHealthStatus {
  vaccinated,
  dewormed,
  sterilized,
  microchipped,
  specialCare
}

class Pet extends Equatable {
  final String id;
  final String name;
  final PetSpecies species;
  final String breed;
  final PetSize size;
  final int ageInMonths;
  final String gender;
  final String description;
  final List<String> photoUrls;
  final String refugeId;
  final Set<PetHealthStatus> healthStatus;
  final String? additionalNotes;
  final DateTime createdAt;
  final bool isAvailable;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.size,
    required this.ageInMonths,
    required this.gender,
    required this.description,
    required this.photoUrls,
    required this.refugeId,
    required this.healthStatus,
    this.additionalNotes,
    required this.createdAt,
    this.isAvailable = true,
  });

  Pet copyWith({
    String? id,
    String? name,
    PetSpecies? species,
    String? breed,
    PetSize? size,
    int? ageInMonths,
    String? gender,
    String? description,
    List<String>? photoUrls,
    String? refugeId,
    Set<PetHealthStatus>? healthStatus,
    String? additionalNotes,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      size: size ?? this.size,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      refugeId: refugeId ?? this.refugeId,
      healthStatus: healthStatus ?? this.healthStatus,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        species,
        breed,
        size,
        ageInMonths,
        gender,
        description,
        photoUrls,
        refugeId,
        healthStatus,
        additionalNotes,
        createdAt,
        isAvailable,
      ];
}
