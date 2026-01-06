import 'package:equatable/equatable.dart';

enum RefugeType { shelter, foundation, privateRescue }

enum AdoptionRequestStatus { pending, approved, rejected }

class Refuge extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final RefugeType type;
  final String? logoUrl;
  final int totalPets;
  final int adoptedPets;
  final int pendingRequests;
  final DateTime createdAt;

  const Refuge({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.phoneNumber,
    this.email,
    this.website,
    required this.type,
    this.logoUrl,
    this.totalPets = 0,
    this.adoptedPets = 0,
    this.pendingRequests = 0,
    required this.createdAt,
  });

  Refuge copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    RefugeType? type,
    String? logoUrl,
    int? totalPets,
    int? adoptedPets,
    int? pendingRequests,
    DateTime? createdAt,
  }) {
    return Refuge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      totalPets: totalPets ?? this.totalPets,
      adoptedPets: adoptedPets ?? this.adoptedPets,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        latitude,
        longitude,
        address,
        phoneNumber,
        email,
        website,
        type,
        logoUrl,
        totalPets,
        adoptedPets,
        pendingRequests,
        createdAt,
      ];
}
