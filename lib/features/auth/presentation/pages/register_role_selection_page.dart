import 'package:flutter/material.dart';

class RegisterRoleSelectionPage extends StatefulWidget {
  const RegisterRoleSelectionPage({Key? key}) : super(key: key);

  @override
  State<RegisterRoleSelectionPage> createState() =>
      _RegisterRoleSelectionPageState();
}

class _RegisterRoleSelectionPageState extends State<RegisterRoleSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('¿Quién eres?'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                '¿Quién eres?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el tipo de cuenta que deseas crear',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Opción Adoptante
              _buildRoleCard(
                icon: Icons.home_outlined,
                title: 'Adoptante',
                description: 'Busco adoptar\nuna mascota y\ndarle un\nhogar lleno de\namor',
                backgroundColor: const Color(0xFFFF6B35),
                onTap: () {
                  Navigator.pushNamed(context, '/register',
                      arguments: 'adopter');
                },
              ),
              const SizedBox(height: 20),
              // Opción Refugio
              _buildRoleCard(
                icon: Icons.pets_outlined,
                title: 'Refugio',
                description: 'Represento\nun refugio\no\nfundación\nde animales',
                backgroundColor: const Color(0xFF1ABC9C),
                onTap: () {
                  Navigator.pushNamed(context, '/register',
                      arguments: 'refuge');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            // Flecha
            Icon(Icons.arrow_forward, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
