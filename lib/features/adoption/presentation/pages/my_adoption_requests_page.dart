import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/repositories/adoption_requests_repository.dart';
import '../../../../injection_container.dart';

class MyAdoptionRequestsPage extends StatefulWidget {
  const MyAdoptionRequestsPage({Key? key}) : super(key: key);

  @override
  State<MyAdoptionRequestsPage> createState() =>
      _MyAdoptionRequestsPageState();
}

class _MyAdoptionRequestsPageState extends State<MyAdoptionRequestsPage> {
  late AdoptionRequestsRepository _adoptionRepository;
  late String _currentUserId;
  int _selectedTabIndex = 0;
  final List<String> tabs = ['Todas', 'Pendientes', 'Aprobadas'];

  @override
  void initState() {
    super.initState();
    _adoptionRepository = getIt<AdoptionRequestsRepository>();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  Future<void> _refreshRequests() async {
    setState(() {
      // Fuerza reconstrucción al tirar hacia abajo
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navegar al home del adoptante
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        title: const Text('Mis Solicitudes'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        color: const Color(0xFFFF6B35),
        child: Column(
          children: [
            // Filtros como chips
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    tabs.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedTabIndex == index,
                        label: Text(tabs[index]),
                        onSelected: (selected) {
                          setState(() => _selectedTabIndex = index);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFFF6B35),
                        side: BorderSide(
                          color: _selectedTabIndex == index
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedTabIndex == index
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido basado en tab seleccionado
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildAllRequests();
    } else if (_selectedTabIndex == 1) {
      return _buildPendingRequests();
    } else {
      return _buildApprovedRequests();
    }
  }

  Widget _buildAllRequests() {
    return FutureBuilder<List<AdoptionRequest>>(
      future: _adoptionRepository.getUserAdoptionRequests(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes solicitudes de adopción'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            Color statusColor = _getStatusColor(request.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(
                petName: request.petName,
                refugeName: request.refugeName,
                date: _formatDate(request.requestDate),
                status: _getStatusText(request.status),
                statusColor: statusColor,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequests() {
    return FutureBuilder<List<AdoptionRequest>>(
      future: _adoptionRepository.getAdoptionRequestsByStatus(_currentUserId, 'pending'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes solicitudes pendientes'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(
                petName: request.petName,
                refugeName: request.refugeName,
                date: _formatDate(request.requestDate),
                status: 'Pendiente',
                statusColor: Colors.orange,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApprovedRequests() {
    return FutureBuilder<List<AdoptionRequest>>(
      future: _adoptionRepository.getAdoptionRequestsByStatus(_currentUserId, 'approved'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tienes solicitudes aprobadas'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(
                petName: request.petName,
                refugeName: request.refugeName,
                date: _formatDate(request.requestDate),
                status: 'Aprobada',
                statusColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard({
    required String petName,
    required String refugeName,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pet Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pets, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud para $petName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  refugeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 365) {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
