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

  String? selectedSpecies;
  String? selectedBreed;
  String? selectedGender;
  String petName = '';
  String breedText = '';
  int ageMonths = 0;
  bool isVaccinated = false;
  bool isDewormed = false;
  bool isSterilized = false;
  bool hasMicrochip = false;
  bool needsSpecialCare = false;
  String healthNotes = '';
  String? photoUrl;
  bool isLoading = false;

  final List<String> species = ['Perro', 'Gato', 'Conejo', 'Ave', 'Roedor', 'Otro'];
  final List<String> genders = ['Macho', 'Hembra'];
  
  final Map<String, String> speciesMap = {
    'Perro': 'dog',
    'Gato': 'cat',
    'Conejo': 'rabbit',
    'Ave': 'bird',
    'Roedor': 'other',
    'Otro': 'other',
  };
  
  final Map<String, String> genderMap = {
    'Macho': 'male',
    'Hembra': 'female',
  };
  
  final Map<String, String> reverseGenderMap = {
    'male': 'Macho',
    'female': 'Hembra',
  };
  
  final Map<String, String> reverseSpeciesMap = {
    'dog': 'Perro',
    'cat': 'Gato',
    'rabbit': 'Conejo',
    'bird': 'Ave',
    'other': 'Otro',
  };

  final Map<String, List<String>> breeds = {
    'Perro': ['Labrador', 'Golden Retriever', 'Pastor Alemán', 'Bulldog', 'Otro'],
    'Gato': ['Persa', 'Siamés', 'Común', 'Bengalí', 'Otro'],
    'Conejo': ['Angora', 'Común', 'Holandés', 'Otro'],
    'Ave': ['Loro', 'Periquito', 'Canario', 'Otro'],
    'Roedor': ['Hamster', 'Conejillo', 'Rata', 'Otro'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _loadPetData();
    }
  }

  Future<void> _loadPetData() async {
    if (widget.pet == null) return;
    
    try {
      // Cargar los datos COMPLETOS del pet desde Supabase
      final fullPetData = await supabase
          .from('pets')
          .select('*')
          .eq('id', widget.pet!['id'])
          .maybeSingle();

      if (fullPetData != null) {
        setState(() {
          print('DEBUG: fullPetData keys = ${fullPetData.keys.toList()}');
          print('DEBUG: photo_url = ${fullPetData['photo_url']}');
          print('DEBUG: health_status = ${fullPetData['health_status']}');
          
          petName = fullPetData['name'] ?? '';
          breedText = fullPetData['breed'] ?? '';
          ageMonths = fullPetData['age_in_months'] ?? 0;
          selectedSpecies = reverseSpeciesMap[fullPetData['species']] ?? 'Otro';
          selectedGender = reverseGenderMap[fullPetData['gender']] ?? 'Macho';
          selectedBreed = fullPetData['breed'] ?? 'Otro';
          
          // Cargar photo_url
          final photoUrlData = fullPetData['photo_url'];
          if (photoUrlData != null && photoUrlData.toString().isNotEmpty) {
            photoUrl = photoUrlData.toString();
          }
          
          // Cargar health_status (es un array)
          final healthStatus = fullPetData['health_status'];
          if (healthStatus != null && healthStatus is List) {
            isVaccinated = healthStatus.contains('vaccinated');
            isDewormed = healthStatus.contains('dewormed');
            isSterilized = healthStatus.contains('sterilized');
            hasMicrochip = healthStatus.contains('microchipped');
          }
          
          needsSpecialCare = fullPetData['requires_special_care'] ?? false;
          healthNotes = fullPetData['additional_notes'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading pet data: $e');
    }
  }

  Future<void> _updatePet() async {
    if (petName.isEmpty || selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos requeridos')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final healthStatus = <String>[];
      if (isVaccinated) healthStatus.add('vaccinated');
      if (isDewormed) healthStatus.add('dewormed');
      if (isSterilized) healthStatus.add('sterilized');
      if (hasMicrochip) healthStatus.add('microchipped');

      await supabase
          .from('pets')
          .update({
            'name': petName,
            'species': speciesMap[selectedSpecies] ?? 'other',
            'breed': selectedBreed ?? 'Otro',
            'gender': genderMap[selectedGender] ?? 'male',
            'age_in_months': ageMonths,
            'health_status': healthStatus,
            'requires_special_care': needsSpecialCare,
            'additional_notes': healthNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.pet!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Mascota actualizada exitosamente!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pet == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1ABC9C),
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('No hay mascota para editar'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 0,
        title: Text(
          widget.readOnly 
              ? 'Ver ${widget.pet!['name']}'
              : 'Editar ${widget.pet!['name']}',
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.readOnly) ...[
                // Foto de la mascota
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(
                        color: const Color(0xFF1ABC9C),
                        width: 3,
                      ),
                    ),
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.pets,
                                  size: 60,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Modo Vista: mostrar todos los datos en tarjetas
                _buildInfoCard('Nombre de la Mascota', petName),
                const SizedBox(height: 12),
                _buildInfoCard('Especie', selectedSpecies ?? '-'),
                const SizedBox(height: 12),
                if (selectedBreed != null)
                  _buildInfoCard('Raza', selectedBreed ?? '-'),
                if (selectedBreed != null)
                  const SizedBox(height: 12),
                _buildInfoCard('Género', selectedGender ?? '-'),
                const SizedBox(height: 12),
                _buildInfoCard('Edad (meses)', ageMonths.toString()),
                const SizedBox(height: 24),
                const Text(
                  '🏥 Estado de Salud',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHealthStatus('Vacunado/a', isVaccinated),
                const SizedBox(height: 12),
                _buildHealthStatus('Desparasitado/a', isDewormed),
                const SizedBox(height: 12),
                _buildHealthStatus('Esterilizado/a', isSterilized),
                const SizedBox(height: 12),
                _buildHealthStatus('Microchip', hasMicrochip),
                const SizedBox(height: 12),
                _buildHealthStatus('Requiere cuidados especiales', needsSpecialCare),
                const SizedBox(height: 24),
                if (healthNotes.isNotEmpty) ...[
                  const Text(
                    '📝 Notas Adicionales de Salud',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(healthNotes),
                  ),
                ],
              ] else ...[
                // Modo Edición: formulario editable
                // Información Básica
                _BasicInfoSection(
                  selectedSpecies: selectedSpecies,
                  selectedBreed: selectedBreed,
                  breeds: breeds,
                  species: species,
                  genders: genders,
                  selectedGender: selectedGender,
                  petName: petName,
                  ageMonths: ageMonths,
                  readOnly: widget.readOnly,
                  onSpeciesChanged: (value) {
                    setState(() {
                      selectedSpecies = value;
                      selectedBreed = null;
                    });
                  },
                  onBreedChanged: (value) {
                    setState(() => selectedBreed = value);
                  },
                  onNameChanged: (value) {
                    setState(() => petName = value);
                  },
                  onGenderChanged: (value) {
                    setState(() => selectedGender = value);
                  },
                  onAgeChanged: (value) {
                    setState(() => ageMonths = int.tryParse(value) ?? 0);
                  },
                ),
                const SizedBox(height: 24),

                // Estado de Salud
                const Text(
                  '🏥 Estado de Salud',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _HealthCheckbox(
                  label: 'Vacunado/a',
                  subtitle: 'Tiene todas las vacunas al día',
                  value: isVaccinated,
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => isVaccinated = val ?? false);
                  },
                ),
                const SizedBox(height: 12),
                _HealthCheckbox(
                  label: 'Desparasitado/a',
                  subtitle: 'Tratamiento antiparasitario completado',
                  value: isDewormed,
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => isDewormed = val ?? false);
                  },
                ),
                const SizedBox(height: 12),
                _HealthCheckbox(
                  label: 'Esterilizado/a',
                  subtitle: 'Ha sido castrado/a o esterilizado/a',
                  value: isSterilized,
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => isSterilized = val ?? false);
                  },
                ),
                const SizedBox(height: 12),
                _HealthCheckbox(
                  label: 'Microchip',
                  subtitle: 'Tiene microchip de identificación',
                  value: hasMicrochip,
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => hasMicrochip = val ?? false);
                  },
                ),
                const SizedBox(height: 12),
                _HealthCheckbox(
                  label: 'Requiere cuidados especiales',
                  subtitle: 'Necesita medicación o atención particular',
                  value: needsSpecialCare,
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => needsSpecialCare = val ?? false);
                  },
                ),
                const SizedBox(height: 24),

                // Notas adicionales
                const Text(
                  '📝 Notas Adicionales de Salud (Opcional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  enabled: !widget.readOnly,
                  onChanged: (value) {
                    setState(() => healthNotes = value);
                  },
                  controller: TextEditingController(text: healthNotes),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Información adicional sobre la salud...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón guardar
                if (!widget.readOnly)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updatePet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1ABC9C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              '✓ Actualizar Mascota',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatus(String label, bool value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF1ABC9C) : Colors.grey[300],
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  final String? selectedSpecies;
  final String? selectedBreed;
  final Map<String, List<String>> breeds;
  final List<String> species;
  final List<String> genders;
  final String? selectedGender;
  final String petName;
  final int ageMonths;
  final bool readOnly;
  final Function(String?) onSpeciesChanged;
  final Function(String?) onBreedChanged;
  final Function(String) onNameChanged;
  final Function(String?) onGenderChanged;
  final Function(String) onAgeChanged;

  const _BasicInfoSection({
    required this.selectedSpecies,
    required this.selectedBreed,
    required this.breeds,
    required this.species,
    required this.genders,
    required this.selectedGender,
    required this.petName,
    required this.ageMonths,
    required this.readOnly,
    required this.onSpeciesChanged,
    required this.onBreedChanged,
    required this.onNameChanged,
    required this.onGenderChanged,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🐾 Información Básica',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onNameChanged,
          enabled: !readOnly,
          controller: TextEditingController(text: petName),
          decoration: InputDecoration(
            hintText: 'Ej: Luna, Rocky, Michi...',
            labelText: '⭐ NOMBRE DE LA MASCOTA',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedSpecies,
          items: species
              .map(
                (s) => DropdownMenuItem(value: s, child: Text(s)),
              )
              .toList(),
          onChanged: readOnly ? null : onSpeciesChanged,
          decoration: InputDecoration(
            labelText: '🐾 ESPECIE',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedSpecies != null && breeds.containsKey(selectedSpecies))
          DropdownButtonFormField<String>(
            value: selectedBreed != null && breeds[selectedSpecies]!.contains(selectedBreed) 
                ? selectedBreed 
                : null,
            items: breeds[selectedSpecies]!
                .map(
                  (b) => DropdownMenuItem(value: b, child: Text(b)),
                )
                .toList(),
            onChanged: readOnly ? null : onBreedChanged,
            decoration: InputDecoration(
              labelText: '🧬 RAZA',
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        if (selectedSpecies != null && breeds.containsKey(selectedSpecies))
          const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedGender,
                items: genders
                    .map(
                      (g) => DropdownMenuItem(value: g, child: Text(g)),
                    )
                    .toList(),
                onChanged: readOnly ? null : onGenderChanged,
                decoration: InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                onChanged: onAgeChanged,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: ageMonths > 0 ? ageMonths.toString() : ''),
                decoration: InputDecoration(
                  labelText: 'Edad (meses)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthCheckbox extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final Function(bool?)? onChanged;

  const _HealthCheckbox({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1ABC9C),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
