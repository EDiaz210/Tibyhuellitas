import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/refuge.dart';
import '../../../pets/domain/entities/pet.dart';

class RefugeMapWidget extends StatefulWidget {
  final List<Refuge> refuges;
  final Function(Refuge)? onRefugeSelected;
  final LatLng? userLocation;

  const RefugeMapWidget({
    Key? key,
    required this.refuges,
    this.onRefugeSelected,
    this.userLocation,
  }) : super(key: key);

  @override
  State<RefugeMapWidget> createState() => _RefugeMapWidgetState();
}

class _RefugeMapWidgetState extends State<RefugeMapWidget> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.userLocation ??
            LatLng(4.5709, -74.2973), // Default to Bogotá
        zoom: 12.0,
        minZoom: 1.0,
        maxZoom: 19.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            // User location marker
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35), // Naranja como "Tu"
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            // Refuge markers
            ...widget.refuges.map((refuge) {
              return Marker(
                point: LatLng(refuge.latitude, refuge.longitude),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    widget.onRefugeSelected?.call(refuge);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1ABC9C), // Teal para refugios
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}

class PetLocationWidget extends StatelessWidget {
  final Pet pet;
  final Refuge? refuge;

  const PetLocationWidget({
    Key? key,
    required this.pet,
    this.refuge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (refuge == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          center: LatLng(refuge!.latitude, refuge!.longitude),
          zoom: 14.0,
          minZoom: 1.0,
          maxZoom: 19.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(refuge!.latitude, refuge!.longitude),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1ABC9C),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
