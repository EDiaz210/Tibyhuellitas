import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPetForRefugePage extends StatefulWidget {
  final Map<String, dynamic>? pet;
  final bool readOnly;

  const EditPetForRefugePage({
    Key? key,
    this.pet,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<EditPetForRefugePage> createState() => _EditPetForRefugePageState();
}

class _EditPetForRefugePageState extends State<EditPetForRefugePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedStatus;
  bool _isVaccinated = false;
  bool _isNeutered = false;

  final List<String> _species = ['Perro', 'Gato', 'Otro'];
  final List<String> _genders = ['Macho', 'Hembra'];
  final List<String> _statuses = ['available', 'adopted', 'reserved'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?['name'] ?? '');
    _breedController = TextEditingController(text: widget.pet?['breed'] ?? '');
    _ageController = TextEditingController(text: widget.pet?['age_in_months']?.toString() ?? '');
    _selectedSpecies = widget.pet?['species'];
    _selectedGender = widget.pet?['gender'];
    _selectedStatus = widget.pet?['status'];
    
    // Parsear health_status (puede ser array o string)
    final healthStatus = widget.pet?['health_status'];
    if (healthStatus is List) {
      _isVaccinated = healthStatus.contains('vaccinated');
      _isNeutered = healthStatus.contains('neutered');
    } else if (healthStatus is String) {
      _isVaccinated = healthStatus.contains('vaccinated');
      _isNeutered = healthStatus.contains('neutered');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        title: Text(
          widget.readOnly 
              ? 'Ver ${widget.pet!['name']}'
              : (widget.pet == null ? 'Nueva Mascota' : 'Editar ${widget.pet!['name']}'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                enabled: !widget.readOnly,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ingresa un nombre';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Especie
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                decoration: InputDecoration(
                  labelText: 'Especie',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: widget.readOnly ? null : (value) => setState(() => _selectedSpecies = value),
                validator: (value) {
                  if (value == null) return 'Selecciona una especie';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Raza
              TextFormField(
                controller: _breedController,
                enabled: !widget.readOnly,
                decoration: InputDecoration(
                  labelText: 'Raza',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.info),
                ),
              ),
              const SizedBox(height: 16),

              // Género
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: widget.readOnly ? null : (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 16),

              // Edad
              TextFormField(
                controller: _ageController,
                enabled: !widget.readOnly,
                decoration: InputDecoration(
                  labelText: 'Edad (años)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Estado
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.check_circle),
                ),
                items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                onChanged: widget.readOnly ? null : (value) => setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: 16),

              // Salud
              const Text(
                'Estado de Salud',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Vacunada'),
                value: _isVaccinated,
                onChanged: widget.readOnly ? null : (value) => setState(() => _isVaccinated = value ?? false),
              ),
              CheckboxListTile(
                title: const Text('Esterilizada/Castrada'),
                value: _isNeutered,
                onChanged: widget.readOnly ? null : (value) => setState(() => _isNeutered = value ?? false),
              ),
              const SizedBox(height: 24),

              // Botones
              if (!widget.readOnly)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _savePet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'adopted':
        return 'Adoptada';
      case 'reserved':
        return 'Reservada';
      default:
        return status;
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final healthStatus = <String>[];
      if (_isVaccinated) healthStatus.add('vaccinated');
      if (_isNeutered) healthStatus.add('neutered');

      final petId = widget.pet?['id'];

      if (petId != null) {
        // Editar
        await supabase
            .from('pets')
            .update({
              'name': _nameController.text,
              'species': _selectedSpecies,
              'breed': _breedController.text,
              'gender': _selectedGender,
              'age_in_months': int.tryParse(_ageController.text) ?? 0,
              'health_status': healthStatus,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', petId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mascota actualizada'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
