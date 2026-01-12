import 'package:supabase_flutter/supabase_flutter.dart';

class AdoptionRequestsSyncService {
  static final AdoptionRequestsSyncService _instance =
      AdoptionRequestsSyncService._internal();

  factory AdoptionRequestsSyncService() {
    return _instance;
  }

  AdoptionRequestsSyncService._internal();

  final supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  final Set<Function(Map<String, dynamic>)> _listeners = {};
  bool _isSubscribed = false;

  /// Inicia el listener de cambios en adoption_requests
  Future<void> startListening() async {
    if (_isSubscribed) {
      print('⚠️ Listener ya está activo para adoption_requests');
      return;
    }

    try {
      _channel = supabase.realtime.channel('public:adoption_requests');

      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'adoption_requests',
            callback: (payload) {
              print('🔄 REALTIME: Cambio detectado en adoption_requests');
              print('Evento: ${payload.eventType}');
              print('Data: ${payload.newRecord}');

              // Notificar a todos los listeners
              final record = payload.newRecord as Map<String, dynamic>? ?? {};
              for (var listener in _listeners) {
                try {
                  listener(record);
                } catch (e) {
                  print('❌ Error en listener: $e');
                }
              }
            },
          )
          .subscribe((status, err) {
            if (err != null) {
              print('❌ Error suscribiendo a adoption_requests: $err');
              _isSubscribed = false;
            } else if (status == RealtimeSubscribeStatus.subscribed) {
              print('✅ Suscrito exitosamente a adoption_requests');
              _isSubscribed = true;
            }
          });

      print('⏳ Intentando suscribirse a cambios en adoption_requests...');
    } catch (e) {
      print('❌ Error iniciando listener para adoption_requests: $e');
      _isSubscribed = false;
    }
  }

  /// Detiene el listener
  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _isSubscribed = false;
  }

  /// Agrega un listener que se llamará cuando cambien los adoption_requests
  void addListener(Function(Map<String, dynamic>) callback) {
    _listeners.add(callback);
    print('✅ Listener agregado. Total listeners: ${_listeners.length}');
    // El listener será efectivo una vez que startListening() se complete
  }

  /// Elimina un listener
  void removeListener(Function(Map<String, dynamic>) callback) {
    _listeners.remove(callback);
    print('❌ Listener removido. Total listeners: ${_listeners.length}');
    if (_listeners.isEmpty) {
      stopListening();
    }
  }

  /// Emite un cambio manualmente a todos los listeners
  /// Útil cuando se crea/actualiza/elimina una solicitud desde la app
  void notifyListeners(Map<String, dynamic> record) {
    print('📢 [AdoptionRequestsSyncService] Notificando manualmente a ${_listeners.length} listeners');
    for (var listener in _listeners) {
      try {
        listener(record);
      } catch (e) {
        print('❌ Error en listener: $e');
      }
    }
  }

  /// Limpia todos los listeners
  void clearListeners() {
    _listeners.clear();
    stopListening();
  }

  /// Obtiene el número de listeners activos
  int getListenerCount() => _listeners.length;
}
