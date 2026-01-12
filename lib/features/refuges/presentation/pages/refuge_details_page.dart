import 'package:flutter/material.dart';
import '../../domain/entities/refuge.dart';

class RefugeDetailsPage extends StatefulWidget {
  final Refuge refuge;

  const RefugeDetailsPage({Key? key, required this.refuge}) : super(key: key);

  @override
  State<RefugeDetailsPage> createState() => _RefugeDetailsPageState();
}

class _RefugeDetailsPageState extends State<RefugeDetailsPage> {
  Future<void> _refreshPage() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: const Color(0xFF1ABC9C),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del refugio
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.pets, size: 80, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y tipo
                    Text(
                      widget.refuge.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1ABC9C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Refugio',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1ABC9C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.refuge.totalPets} mascotas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Estadísticas
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    // Información de contacto
                    _buildContactSection(),
                    const SizedBox(height: 20),
                    // Descripción
                    _buildDescriptionSection(),
                    const SizedBox(height: 30),
                    // Botones de acción
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('15', 'Mascotas'),
          _buildStatColumn('23', 'Adoptadas'),
          _buildStatColumn('8', 'Pendientes'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1ABC9C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contacto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          icon: Icons.location_on,
          title: 'Dirección',
          value: '${widget.refuge.address}',
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          icon: Icons.phone,
          title: 'Teléfono',
          value: '${widget.refuge.phoneNumber ?? 'No disponible'}',
        ),
        const SizedBox(height: 12),
        _buildContactItem(
          icon: Icons.email,
          title: 'Email',
          value: '${widget.refuge.email}',
        ),
        ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1ABC9C), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre nosotros',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Somos un refugio dedicado a rescatar, rehabilitar y rehomar animales abandonados. Nuestro equipo trabaja sin fines de lucro para ofrecerles una segunda oportunidad a nuestros peludos amigos.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call),
            label: const Text('Llamar al Refugio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.pets),
            label: const Text('Ver Mascotas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1ABC9C),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
