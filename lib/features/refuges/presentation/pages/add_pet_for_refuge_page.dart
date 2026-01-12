import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../../core/services/pets_sync_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../injection_container.dart';

class AddPetForRefugePage extends StatefulWidget {
  const AddPetForRefugePage({Key? key}) : super(key: key);

  @override
  State<AddPetForRefugePage> createState() => _AddPetForRefugePageState();
}

class _AddPetForRefugePageState extends State<AddPetForRefugePage> {
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController descriptionController = TextEditingController();
  
  List<File> selectedImages = [];
  String? selectedSpecies;
  String? selectedBreed;
  String petName = '';
  String description = '';
  int ageMonths = 0;
  String? selectedGender;
  bool isVaccinated = false;
  bool isDewormed = false;
  bool isSterilized = false;
  bool hasMicrochip = false;
  bool needsSpecialCare = false;
  String healthNotes = '';
  bool isLoading = false;

  final List<String> species = ['Perro', 'Gato', 'Conejo', 'Ave', 'Roedor', 'Otro'];
  final List<String> genders = ['Macho', 'Hembra'];
  
  // Mapeo de nombres en español a valores de enum en inglés
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

  final Map<String, List<String>> breeds = {
    'Perro': ['Labrador', 'Golden Retriever', 'Pastor Alemán', 'Bulldog', 'Otro'],
    'Gato': ['Persa', 'Siamés', 'Común', 'Bengalí', 'Otro'],
    'Conejo': ['Angora', 'Común', 'Holandés', 'Otro'],
    'Ave': ['Loro', 'Periquito', 'Canario', 'Otro'],
    'Roedor': ['Hamster', 'Conejillo', 'Rata', 'Otro'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1ABC9C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nueva Mascota',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Fotos
              _PhotosSection(),
              const SizedBox(height: 24),

              // Información Básica
              _BasicInfoSection(
                selectedSpecies: selectedSpecies,
                selectedBreed: selectedBreed,
                breeds: breeds,
                species: species,
                petName: petName,
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
                selectedGender: selectedGender,
                genders: genders,
              ),
              const SizedBox(height: 24),

              // Descripción
              _DescriptionSection(
                controller: descriptionController,
                description: description,
                onDescriptionChanged: (value) {
                  setState(() => description = value);
                },
              ),
              const SizedBox(height: 24),

              // Estado de Salud
              _HealthSection(
                isVaccinated: isVaccinated,
                isDewormed: isDewormed,
                isSterilized: isSterilized,
                hasMicrochip: hasMicrochip,
                needsSpecialCare: needsSpecialCare,
                healthNotes: healthNotes,
                onVaccinatedChanged: (value) {
                  setState(() => isVaccinated = value ?? false);
                },
                onDewormedChanged: (value) {
                  setState(() => isDewormed = value ?? false);
                },
                onSterilizedChanged: (value) {
                  setState(() => isSterilized = value ?? false);
                },
                onMicrochipChanged: (value) {
                  setState(() => hasMicrochip = value ?? false);
                },
                onSpecialCareChanged: (value) {
                  setState(() => needsSpecialCare = value ?? false);
                },
                onHealthNotesChanged: (value) {
                  setState(() => healthNotes = value);
                },
              ),
              const SizedBox(height: 32),

              // Botón Publicar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _publishPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Publicar Mascota',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishPet() async {
    if (petName.isEmpty || selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa los campos requeridos')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Obtener ID del refugio (refuges.id == users.id, así que usamos user.id directamente)
      final refugeId = user.id;

      // Construir array de health_status
      final List<String> healthStatus = [];
      if (isVaccinated) healthStatus.add('vaccinated');
      if (isDewormed) healthStatus.add('dewormed');
      if (isSterilized) healthStatus.add('sterilized');
      if (hasMicrochip) healthStatus.add('microchipped');

      // Construir array de personality_traits
      final List<String> personalityTraits = [];
      if (description.contains('Juguetón')) personalityTraits.add('playful');
      if (description.contains('Tranquilo')) personalityTraits.add('calm');
      if (description.contains('Cariñoso')) personalityTraits.add('affectionate');
      if (description.contains('Ideal para niños')) personalityTraits.add('good_with_children');
      if (description.contains('Apto departamento')) personalityTraits.add('apartment_friendly');

      // Insertar mascota
      final response = await supabase.from('pets').insert({
        'name': petName,
        'species': speciesMap[selectedSpecies] ?? 'other',
        'breed': selectedBreed ?? 'Otro',
        'gender': genderMap[selectedGender] ?? 'male',
        'age_in_months': ageMonths,
        'description': description,
        'health_status': healthStatus,
        'personality_traits': personalityTraits,
        'requires_special_care': needsSpecialCare,
        'additional_notes': healthNotes,
        'refuge_id': refugeId,
      }).select();

      // Notificar a PetsSyncService para que actualice listeners
      if (response.isNotEmpty) {
        final newPet = response[0] as Map<String, dynamic>;
        PetsSyncService().notifyListeners(newPet);
        print('✅ Notificación enviada a PetsSyncService por nueva mascota');
        
        // Enviar notificación push al usuario sobre nueva mascota disponible
        try {
          final notificationService = getIt<NotificationService>();
          final refugeName = await _getRefugeName(refugeId);
          await notificationService.showPetAvailableNotification(
            petName: petName,
            refugeName: refugeName,
          );
        } catch (e) {
          print('Error sending pet notification: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Mascota registrada exitosamente!')),
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

  Future<String> _getRefugeName(String refugeId) async {
    try {
      final response = await supabase
          .from('refuges')
          .select('name')
          .eq('id', refugeId)
          .single();
      return response['name'] as String? ?? 'El refugio';
    } catch (e) {
      print('Error getting refuge name: $e');
      return 'El refugio';
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}

class _PhotosSection extends StatefulWidget {
  @override
  State<_PhotosSection> createState() => _PhotosSectionState();
}

class _PhotosSectionState extends State<_PhotosSection> {
  final ImagePicker _imagePicker = ImagePicker();
  List<File> selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📷 Fotos de la Mascota',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mínimo 1 foto, máximo 5. La primera será la principal.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Principal
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.yellow,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      const Text(
                        'PRINCIPAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Otras fotos
              ...List.generate(
                selectedImages.length,
                (index) => Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Agregar foto
              if (selectedImages.length < 4)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                      color: Colors.grey[100],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF1ABC9C),
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            '${selectedImages.length}/5 fotos agregadas. Las fotos de buena calidad aumentan las adopciones.',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1ABC9C)),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF1ABC9C)),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null && mounted) {
      setState(() {
        selectedImages.add(File(pickedFile.path));
      });
    }
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
          onChanged: onSpeciesChanged,
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
            value: selectedBreed,
            items: breeds[selectedSpecies]!
                .map(
                  (b) => DropdownMenuItem(value: b, child: Text(b)),
                )
                .toList(),
            onChanged: onBreedChanged,
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
                onChanged: onGenderChanged,
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
                keyboardType: TextInputType.number,
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

class _DescriptionSection extends StatelessWidget {
  final TextEditingController controller;
  final String description;
  final Function(String) onDescriptionChanged;

  const _DescriptionSection({
    required this.controller,
    required this.description,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Descripción',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: onDescriptionChanged,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'Describe su personalidad, historia, comportamiento con niños y otras mascotas, nivel de actividad, qué tipo de hogar sería ideal...',
            labelText: '💬 CUÉNTANOS SOBRE ESTA MASCOTA',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            'Juguetón',
            'Tranquilo',
            'Cariñoso',
            'Ideal para niños',
            'Apto departamento',
          ]
              .map(
                (suggestion) => GestureDetector(
                  onTap: () {
                    final currentText = controller.text;
                    final newText = currentText.isEmpty
                        ? suggestion
                        : '$currentText\n$suggestion';
                    controller.text = newText;
                    onDescriptionChanged(newText);
                  },
                  child: Chip(
                    label: Text(
                      '+ $suggestion',
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _HealthSection extends StatelessWidget {
  final bool isVaccinated;
  final bool isDewormed;
  final bool isSterilized;
  final bool hasMicrochip;
  final bool needsSpecialCare;
  final String healthNotes;
  final Function(bool?) onVaccinatedChanged;
  final Function(bool?) onDewormedChanged;
  final Function(bool?) onSterilizedChanged;
  final Function(bool?) onMicrochipChanged;
  final Function(bool?) onSpecialCareChanged;
  final Function(String) onHealthNotesChanged;

  const _HealthSection({
    required this.isVaccinated,
    required this.isDewormed,
    required this.isSterilized,
    required this.hasMicrochip,
    required this.needsSpecialCare,
    required this.healthNotes,
    required this.onVaccinatedChanged,
    required this.onDewormedChanged,
    required this.onSterilizedChanged,
    required this.onMicrochipChanged,
    required this.onSpecialCareChanged,
    required this.onHealthNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          title: 'Vacunado/a',
          subtitle: 'Tiene todas las vacunas al día',
          value: isVaccinated,
          onChanged: onVaccinatedChanged,
        ),
        const SizedBox(height: 12),
        _HealthCheckbox(
          title: 'Desparasitado/a',
          subtitle: 'Tratamiento antiparasitario completado',
          value: isDewormed,
          onChanged: onDewormedChanged,
        ),
        const SizedBox(height: 12),
        _HealthCheckbox(
          title: 'Esterilizado/a',
          subtitle: 'Ha sido castrado/a o esterilizado/a',
          value: isSterilized,
          onChanged: onSterilizedChanged,
        ),
        const SizedBox(height: 12),
        _HealthCheckbox(
          title: 'Microchip',
          subtitle: 'Tiene microchip de identificación',
          value: hasMicrochip,
          onChanged: onMicrochipChanged,
        ),
        const SizedBox(height: 12),
        _HealthCheckbox(
          title: 'Requiere cuidados especiales',
          subtitle: 'Necesita medicación o atención particular',
          value: needsSpecialCare,
          onChanged: onSpecialCareChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onHealthNotesChanged,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Alergias, medicamentos, condiciones crónicas, historial médico relevante...',
            labelText: '📋 NOTAS ADICIONALES DE SALUD (OPCIONAL)',
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _HealthCheckbox extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool?) onChanged;

  const _HealthCheckbox({
    required this.title,
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
        border: Border.all(
          color: value ? const Color(0xFF1ABC9C) : Colors.grey[300]!,
          width: 1.5,
        ),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
