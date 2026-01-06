import 'package:equatable/equatable.dart';

enum AdoptionRequestStatus {
  pending('Pendiente'),
  approved('Aprobada'),
  rejected('Rechazada'),
  cancelled('Cancelada');

  final String displayName;
  const AdoptionRequestStatus(this.displayName);
}

class AdoptionRequest extends Equatable {
  final String id;
  final String userId;
  final String petId;
  final String refugeId;
  final AdoptionRequestStatus status;
  final DateTime requestDate;
  final String? approvalNotes;
  final DateTime? approvalDate;

  const AdoptionRequest({
    required this.id,
    required this.userId,
    required this.petId,
    required this.refugeId,
    required this.status,
    required this.requestDate,
    this.approvalNotes,
    this.approvalDate,
  });

  AdoptionRequest copyWith({
    String? id,
    String? userId,
    String? petId,
    String? refugeId,
    AdoptionRequestStatus? status,
    DateTime? requestDate,
    String? approvalNotes,
    DateTime? approvalDate,
  }) {
    return AdoptionRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      refugeId: refugeId ?? this.refugeId,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      approvalDate: approvalDate ?? this.approvalDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petId,
        refugeId,
        status,
        requestDate,
        approvalNotes,
        approvalDate,
      ];
}
