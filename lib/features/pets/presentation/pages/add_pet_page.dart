import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({Key? key}) : super(key: key);

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  late PageController _pageController;
  int _currentStep = 0;
  List<XFile> _selectedImages = [];
  String? _selectedSpecies;
  bool _isVaccinated = true;
  bool _isDewormed = true;
  bool _isSterilized = false;
  bool _hasMicrochip = false;
  bool _needsSpecialCare = false;

  final _petNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _healthNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _petNameController.dispose();
    _descriptionController.dispose();
    _healthNotesController.dispose();
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
        title: const Text('Nueva Mascota'),
        backgroundColor: const Color(0xFF1ABC9C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentStep = index);
        },
        children: [
          _buildPhotosStep(),
          _buildBasicInfoStep(),
          _buildDescriptionStep(),
          _buildHealthStep(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Anterior'),
                )
              else
                const SizedBox(width: 100),
              Text('Paso ${_currentStep + 1}/4'),
              if (_currentStep < 3)
                ElevatedButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                  ),
                  child: const Text('Siguiente'),
                )
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                  ),
                  child: const Text('Publicar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotos de la Mascota',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mínimo 1 foto, máximo 5. La primera será la principal.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Grid de fotos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _selectedImages.length < 5
                ? _selectedImages.length + 1
                : _selectedImages.length,
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '★ PRINCIPAL',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return GestureDetector(
                  onTap: _pickImage,
                  child: DottedBox(
                    icon: Icons.camera_alt,
                    label: 'Agregar',
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedImages.length}/5 fotos agregadas. Las fotos de buena calidad aumentan las adopciones.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField('NOMBRE DE LA MASCOTA', _petNameController,
              'Ej: Luna, Rocky, Michi...'),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'ESPECIE',
            value: _selectedSpecies,
            items: ['Perro', 'Gato', 'Pájaro', 'Conejo', 'Otro'],
            onChanged: (value) {
              setState(() => _selectedSpecies = value);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('RAZA', TextEditingController(), ''),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CUÉNTANOS SOBRE ESTA MASCOTA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Describe su personalidad, historia, comportamiento con niños y otras mascotas, nivel de actividad, qué tipo de hogar sería ideal...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SUGERENCIAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Juguetón'),
              _buildSuggestionChip('Tranquilo'),
              _buildSuggestionChip('Cariñoso'),
              _buildSuggestionChip('Ideal para niños'),
              _buildSuggestionChip('Apto departamento'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de Salud',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildHealthCheckbox('Vacunado/a', 'Tiene todas las vacunas al día',
              _isVaccinated, (value) {
            setState(() => _isVaccinated = value ?? false);
          }),
          const SizedBox(height: 12),
          _buildHealthCheckbox('Desparasitado/a',
              'Tratamiento antiparasitario completado', _isDewormed, (value) {
            setState(() => _isDewormed = value ?? false);
          }),
          const SizedBox(height: 12),
          _buildHealthCheckbox('Esterilizado/a',
              'Ha sido castrado/a o esterilizado/a', _isSterilized, (value) {
            setState(() => _isSterilized = value ?? false);
          }),
          const SizedBox(height: 12),
          _buildHealthCheckbox('Microchip',
              'Tiene microchip de identificación', _hasMicrochip, (value) {
            setState(() => _hasMicrochip = value ?? false);
          }),
          const SizedBox(height: 12),
          _buildHealthCheckbox('Requiere cuidados especiales',
              'Necesita medicación o atención particular',
              _needsSpecialCare, (value) {
            setState(() => _needsSpecialCare = value ?? false);
          }),
          const SizedBox(height: 24),
          const Text(
            'NOTAS ADICIONALES DE SALUD (OPCIONAL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _healthNotesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Alergias, medicamentos, condiciones crónicas, historial médico relevante...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCheckbox(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF1ABC9C).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF1ABC9C) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1ABC9C),
          ),
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
                const SizedBox(height: 2),
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

  Widget _buildSuggestionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _submitForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mascota publicada exitosamente')),
    );
    Navigator.pop(context);
  }
}

class DottedBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const DottedBox({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1ABC9C), size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1ABC9C),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
