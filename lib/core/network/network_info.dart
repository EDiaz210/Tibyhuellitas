import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

@LazySingleton(as: NetworkInfo)
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    try {
      final result = await connectivity.checkConnectivity();
      // In newer versions, it returns List<ConnectivityResult>
      if (result is List) {
        return !(result as List).cast<ConnectivityResult>().contains(ConnectivityResult.none);
      } else {
        // Fallback for older versions
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }
}
