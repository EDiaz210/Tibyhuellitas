import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  
  // Métodos específicos para adopción
  Future<void> showNewRequestNotification({
    required String adopterName,
    required String petName,
  });
  Future<void> showRequestApprovedNotification({
    required String refugeName,
    required String petName,
  });
  Future<void> showRequestRejectedNotification({
    required String refugeName,
    required String petName,
  });
  Future<void> showPetAvailableNotification({
    required String petName,
    required String refugeName,
  });
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _plugin.initialize(initSettings);
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'tibyhuellitas_channel',
      'TIBYHUELLITAS Notifications',
      channelDescription: 'Notifications for adoption requests and updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Notificación: REFUGIO recibe nueva solicitud de adopción
  @override
  Future<void> showNewRequestNotification({
    required String adopterName,
    required String petName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'adoption_requests',
      'Solicitudes de Adopción',
      channelDescription: 'Notificaciones cuando alguien solicita adoptar',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: Color.fromARGB(255, 26, 188, 156),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      1,
      '🎉 Nueva Solicitud de Adopción',
      '$adopterName solicitó adoptar a $petName',
      details,
      payload: 'adoption_request:$adopterName:$petName',
    );

    print('✅ Notificación enviada: Nueva solicitud de $adopterName');
  }

  /// Notificación: ADOPTADOR recibe aprobación
  @override
  Future<void> showRequestApprovedNotification({
    required String refugeName,
    required String petName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'adoption_status',
      'Estado de Solicitud',
      channelDescription: 'Notificaciones sobre aprobación/rechazo de solicitudes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: Color.fromARGB(255, 76, 175, 80),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      2,
      '✅ ¡Solicitud Aprobada!',
      '$refugeName aprobó tu solicitud para $petName',
      details,
      payload: 'request_approved:$refugeName:$petName',
    );

    print('✅ Notificación enviada: Solicitud aprobada por $refugeName');
  }

  /// Notificación: ADOPTADOR recibe rechazo
  @override
  Future<void> showRequestRejectedNotification({
    required String refugeName,
    required String petName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'adoption_status',
      'Estado de Solicitud',
      channelDescription: 'Notificaciones sobre aprobación/rechazo de solicitudes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      color: Color.fromARGB(255, 244, 67, 54),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      3,
      '❌ Solicitud Rechazada',
      '$refugeName rechazó tu solicitud para $petName',
      details,
      payload: 'request_rejected:$refugeName:$petName',
    );

    print('❌ Notificación enviada: Solicitud rechazada por $refugeName');
  }

  /// Notificación: Nueva mascota disponible para adopción
  @override
  Future<void> showPetAvailableNotification({
    required String petName,
    required String refugeName,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'new_pets',
      'Nuevas Mascotas',
      channelDescription: 'Notificaciones cuando hay nuevas mascotas disponibles',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: Color.fromARGB(255, 33, 150, 243),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      4,
      '🐾 $petName disponible para adopción',
      'El refugio $refugeName acaba de registrar a $petName. ¡No esperes más!',
      details,
      payload: 'pet_available:$refugeName:$petName',
    );

    print('🐾 Notificación enviada: $petName disponible por $refugeName');
  }
}
