import 'package:supabase_flutter/supabase_flutter.dart';

class PetsSyncService {
  static final PetsSyncService _instance = PetsSyncService._internal();

  factory PetsSyncService() {
    return _instance;
  }

  PetsSyncService._internal();

  final supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  final Set<Function(Map<String, dynamic>)> _listeners = {};
  bool _isSubscribed = false;

  /// Inicia el listener de cambios en pets
  Future<void> startListening() async {
    if (_isSubscribed) {
      print('⚠️ Listener ya está activo para pets');
      return;
    }

    try {
      _channel = supabase.realtime.channel('public:pets');

      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'pets',
            callback: (payload) {
              print('🔄 REALTIME: Cambio detectado en pets');
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
              print('❌ Error suscribiendo a pets: $err');
              _isSubscribed = false;
            } else if (status == RealtimeSubscribeStatus.subscribed) {
              print('✅ Suscrito exitosamente a pets');
              _isSubscribed = true;
            }
          });

      print('⏳ Intentando suscribirse a cambios en pets...');
    } catch (e) {
      print('❌ Error iniciando listener para pets: $e');
      _isSubscribed = false;
    }
  }

  /// Detiene el listener
  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _isSubscribed = false;
  }

  /// Agrega un listener que se llamará cuando cambien los pets
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
  /// Útil cuando se crea/actualiza/elimina una mascota desde la app
  void notifyListeners(Map<String, dynamic> record) {
    print('📢 [PetsSyncService] Notificando manualmente a ${_listeners.length} listeners');
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
