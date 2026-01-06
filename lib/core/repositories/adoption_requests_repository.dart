import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../../injection_container.dart';

class AdoptionRequest {
  final String id;
  final String userId;
  final String petId;
  final String refugeId;
  final String status; // pending, approved, rejected
  final String petName;
  final String refugeName;
  final DateTime requestDate;
  final String? approvalNotes;

  AdoptionRequest({
    required this.id,
    required this.userId,
    required this.petId,
    required this.refugeId,
    required this.status,
    required this.petName,
    required this.refugeName,
    required this.requestDate,
    this.approvalNotes,
  });

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    return AdoptionRequest(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      petId: json['pet_id'] ?? '',
      refugeId: json['refuge_id'] ?? '',
      status: json['status'] ?? 'pending',
      petName: json['pets']['name'] ?? 'Mascota',
      refugeName: json['refuges']['name'] ?? 'Refugio',
      requestDate: DateTime.parse(json['request_date'] ?? DateTime.now().toIso8601String()),
      approvalNotes: json['approval_notes'],
    );
  }
}

abstract class AdoptionRequestsRepository {
  Future<List<AdoptionRequest>> getUserAdoptionRequests(String userId);
  Future<List<AdoptionRequest>> getAdoptionRequestsByStatus(String userId, String status);
  Future<void> createAdoptionRequest(String userId, String petId, String refugeId);
  Future<void> cancelAdoptionRequest(String requestId);
}

class AdoptionRequestsRepositoryImpl implements AdoptionRequestsRepository {
  final SupabaseClient supabase;

  AdoptionRequestsRepositoryImpl({required this.supabase});

  @override
  Future<List<AdoptionRequest>> getUserAdoptionRequests(String userId) async {
    try {
      final response = await supabase
          .from('adoption_requests')
          .select('*, pets(name), refuges(name)')
          .eq('user_id', userId)
          .order('request_date', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching adoption requests: $e');
      return [];
    }
  }

  @override
  Future<List<AdoptionRequest>> getAdoptionRequestsByStatus(String userId, String status) async {
    try {
      final response = await supabase
          .from('adoption_requests')
          .select('*, pets(name), refuges(name)')
          .eq('user_id', userId)
          .eq('status', status)
          .order('request_date', ascending: false);

      return (response as List)
          .map((json) => AdoptionRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching adoption requests by status: $e');
      return [];
    }
  }

  @override
  Future<void> createAdoptionRequest(String userId, String petId, String refugeId) async {
    try {
      // Primero, verificar que el usuario existe en la tabla users
      // Si no existe, crearlo
      String adopterName = 'Usuario';
      try {
        final userData = await supabase
            .from('users')
            .select('name')
            .eq('id', userId)
            .single();
        adopterName = userData['name'] ?? 'Usuario';
      } catch (e) {
        // Usuario no existe, crearlo
        final currentUser = supabase.auth.currentUser;
        if (currentUser != null) {
          adopterName = currentUser.userMetadata?['name'] ?? currentUser.email?.split('@')[0] ?? 'Usuario';
          await supabase.from('users').insert({
            'id': userId,
            'email': currentUser.email ?? '',
            'name': adopterName,
            'role': 'adopter',
            'email_verified': currentUser.emailConfirmedAt != null,
          });
        }
      }

      // Obtener el nombre de la mascota
      String petName = 'mascota';
      try {
        final petData = await supabase
            .from('pets')
            .select('name')
            .eq('id', petId)
            .single();
        petName = petData['name'] ?? 'mascota';
      } catch (e) {
        print('Error getting pet name: $e');
      }

      // Ahora crear la solicitud de adopción
      await supabase.from('adoption_requests').insert({
        'user_id': userId,
        'pet_id': petId,
        'refuge_id': refugeId,
        'status': 'pending',
      });

      // Enviar notificación al refugio sobre la nueva solicitud
      try {
        final notificationService = getIt<NotificationService>();
        await notificationService.showNewRequestNotification(
          adopterName: adopterName,
          petName: petName,
        );
      } catch (e) {
        print('Error sending notification: $e');
        // No rethrow - la solicitud se creó exitosamente aunque la notificación falle
      }
    } catch (e) {
      print('Error creating adoption request: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelAdoptionRequest(String requestId) async {
    try {
      await supabase
          .from('adoption_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId);
    } catch (e) {
      print('Error cancelling adoption request: $e');
      rethrow;
    }
  }
}
