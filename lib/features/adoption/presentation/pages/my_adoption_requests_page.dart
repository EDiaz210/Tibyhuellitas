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

class _MyAdoptionRequestsPageState extends State<MyAdoptionRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdoptionRequestsRepository _adoptionRepository;
  late String _currentUserId;
  bool _isLoading = true;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adoptionRepository = getIt<AdoptionRequestsRepository>();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar datos cada vez que la página se vuelve a enfocar
    _refreshKey++;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mis Solicitudes'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Aprobadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllRequests(),
          _buildPendingRequests(),
          _buildApprovedRequests(),
        ],
      ),
    );
  }

  Widget _buildAllRequests() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _refreshKey++;
        });
      },
      child: FutureBuilder<List<AdoptionRequest>>(
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
      ),
    );
  }

  Widget _buildPendingRequests() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _refreshKey++;
        });
      },
      child: FutureBuilder<List<AdoptionRequest>>(
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
      ),
    );
  }

  Widget _buildApprovedRequests() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _refreshKey++;
        });
      },
      child: FutureBuilder<List<AdoptionRequest>>(
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
      ),
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
