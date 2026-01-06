import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RefugePetsPage extends StatefulWidget {
  const RefugePetsPage({Key? key}) : super(key: key);

  @override
  State<RefugePetsPage> createState() => _RefugePetsPageState();
}

class _RefugePetsPageState extends State<RefugePetsPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        title: const Text(
          'Mis Mascotas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: _loadMyPets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF1ABC9C)),
              ),
            );
          }

          if (snapshot.hasError) {
            // Vista amigable de error (similar a vacío) con CTA para crear mascota
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pudimos cargar tus mascotas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intenta registrar una mascota. Si persiste, vuelve a intentar más tarde.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_pet_refuge');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1ABC9C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Registrar mascota',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final pets = snapshot.data as List<dynamic>;

          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tienes mascotas registradas',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add_pet_refuge');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1ABC9C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Registrar mascota',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${pets.length} mascota${pets.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_pet_refuge');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1ABC9C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Agregar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: const Color(0xFF1ABC9C),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PetCard(
                          pet: pet,
                          onUpdate: () {
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _loadMyPets() async {
    try {
      final user = supabase.auth.currentUser;
      print('=== DEBUG REFUGE PETS ===');
      print('User ID: ${user?.id}');
      print('User Email: ${user?.email}');
      
      if (user == null) {
        print('ERROR: No user authenticated');
        return [];
      }

      print('[1] Buscando refugio en DB con id=${user.id}');
      try {
        final refugeData = await supabase
            .from('refuges')
            .select('*')
            .eq('id', user.id)
            .maybeSingle();

        print('[2] Refugio raw response: $refugeData');
        print('[2] Refugio null?: ${refugeData == null}');

        if (refugeData == null) {
          print('ERROR: No refuge record found for user ${user.id}');
          return [];
        }

        final refugeId = refugeData['id'];
        print('[3] Refuge ID extracted: $refugeId');

        print('[4] Searching pets for refuge_id=$refugeId');
        final pets = await supabase
            .from('pets')
            .select('*')
            .eq('refuge_id', refugeId)
            .order('created_at', ascending: false);

        print('[5] Pets query response: ${pets.length} pets found');
        for (var i = 0; i < pets.length; i++) {
          print('[5.${i}] Pet: ${pets[i]['name']} (id=${pets[i]['id']})');
        }

        return pets;
      } catch (queryError) {
        print('Query Error: $queryError');
        rethrow;
      }
    } catch (e) {
      print('=== ERROR LOADING PETS ===');
      print('Exception Type: ${e.runtimeType}');
      print('Error: $e');
      rethrow;
    }
  }
}

class _PetCard extends StatefulWidget {
  final dynamic pet;
  final VoidCallback onUpdate;

  const _PetCard({
    required this.pet,
    required this.onUpdate,
  });

  @override
  State<_PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<_PetCard> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final status = widget.pet['status'];
    final statusColor = status == 'available' ? const Color(0xFF1ABC9C) : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.pet['name']?[0]?.toUpperCase() ?? '🐾',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet['name'] ?? 'Mascota',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.pet['species'] ?? 'Especie'} • ${widget.pet['breed'] ?? 'Raza'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status == 'available'
                            ? 'Disponible'
                            : status == 'adopted'
                                ? 'Adoptada'
                                : 'Reservada',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Ver',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/edit_pet_refuge',
                      arguments: {
                        'pet': widget.pet,
                        'readOnly': true,
                      },
                    ).then((_) => widget.onUpdate());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/edit_pet_refuge',
                      arguments: widget.pet,
                    ).then((_) => widget.onUpdate());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Eliminar',
                  color: Colors.red,
                  onTap: () => _deletePet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${widget.pet['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await supabase
            .from('pets')
            .delete()
            .eq('id', widget.pet['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mascota eliminada'),
              backgroundColor: Colors.red,
            ),
          );
          widget.onUpdate();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1ABC9C),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
