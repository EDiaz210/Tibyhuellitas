-- ============================================
-- TIBYHUELLITAS - SISTEMA DE ADOPCIÓN DE MASCOTAS
-- Setup para Supabase
-- ============================================

-- 1. CREAR ENUMS (TIPOS)
CREATE TYPE pet_species AS ENUM ('dog', 'cat', 'rabbit', 'bird', 'other');
CREATE TYPE pet_size AS ENUM ('small', 'medium', 'large');
CREATE TYPE refuge_type AS ENUM ('shelter', 'foundation', 'privateRescue');
CREATE TYPE adoption_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE user_role AS ENUM ('adopter', 'refuge', 'admin');

-- 2. TABLA: users (Perfil de usuarios - extensión de auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  role user_role NOT NULL DEFAULT 'adopter',
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLA: refuges (Refugios y centros de adopción)
CREATE TABLE IF NOT EXISTS refuges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  address TEXT NOT NULL,
  phone_number VARCHAR(20),
  email VARCHAR(255),
  website VARCHAR(500),
  type refuge_type DEFAULT 'shelter',
  logo_url VARCHAR(500),
  total_pets INTEGER DEFAULT 0,
  adopted_pets INTEGER DEFAULT 0,
  pending_requests INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLA: pets (Mascotas disponibles para adopción)
CREATE TABLE IF NOT EXISTS pets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  species pet_species NOT NULL,
  breed VARCHAR(255) NOT NULL,
  size pet_size,
  age_in_months INTEGER,
  gender VARCHAR(50),
  description TEXT,
  photo_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  refuge_id UUID NOT NULL REFERENCES refuges(id) ON DELETE CASCADE,
  health_status TEXT[] DEFAULT ARRAY[]::TEXT[],
  personality_traits TEXT[] DEFAULT ARRAY[]::TEXT[],
  requires_special_care BOOLEAN DEFAULT FALSE,
  additional_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA: adoption_requests (Solicitudes de adopción)
CREATE TABLE IF NOT EXISTS adoption_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  refuge_id UUID NOT NULL REFERENCES refuges(id) ON DELETE CASCADE,
  status adoption_status DEFAULT 'pending',
  request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  approval_notes TEXT,
  approval_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. TABLA: favorites (Mascotas favoritas del usuario)
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, pet_id)
);

-- ============================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ============================================

CREATE INDEX IF NOT EXISTS idx_pets_refuge_id ON pets(refuge_id);
CREATE INDEX IF NOT EXISTS idx_pets_species ON pets(species);
CREATE INDEX IF NOT EXISTS idx_pets_size ON pets(size);
CREATE INDEX IF NOT EXISTS idx_adoption_requests_user_id ON adoption_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_adoption_requests_pet_id ON adoption_requests(pet_id);
CREATE INDEX IF NOT EXISTS idx_adoption_requests_refuge_id ON adoption_requests(refuge_id);
CREATE INDEX IF NOT EXISTS idx_adoption_requests_status ON adoption_requests(status);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_pet_id ON favorites(pet_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE refuges ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE adoption_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS: users
CREATE POLICY "Users can read their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- POLÍTICAS: refuges (públicos, todos pueden ver)
CREATE POLICY "Refuges are publicly readable" ON refuges
  FOR SELECT USING (true);

-- POLÍTICAS: pets (públicos, todos pueden ver)
CREATE POLICY "Pets are publicly readable" ON pets
  FOR SELECT USING (true);

-- POLÍTICAS: adoption_requests
CREATE POLICY "Users can read their own requests" ON adoption_requests
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create adoption requests" ON adoption_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- POLÍTICAS: favorites
CREATE POLICY "Users can read their own favorites" ON favorites
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can add favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- DATOS DE EJEMPLO - DATOS REALES PARA PRUEBAS
-- ============================================

-- LIMPIAR DATOS ANTERIORES (si existen)
DELETE FROM favorites;
DELETE FROM adoption_requests;
DELETE FROM pets;
DELETE FROM refuges;

-- Insertar refugios con información completa
INSERT INTO refuges (id, name, description, latitude, longitude, address, phone_number, email, type, total_pets, adopted_pets, pending_requests)
VALUES 
  ('550e8400-e29b-41d4-a716-446655440000'::UUID, 'Patitas Felices', 'Refugio especializado en rescate y adopción de perros y gatos', 4.7110, -74.0721, 'Carrera 10 #20-30, Bogotá', '+57 310 1234567', 'patitas@tibyhuellitas.com', 'shelter', 15, 8, 3),
  ('550e8400-e29b-41d4-a716-446655440001'::UUID, 'Hogar Seguro', 'Fundación dedicada al rescate y rehabilitación de animales en peligro', 4.6097, -74.0817, 'Avenida Caracas #45-60, Bogotá', '+57 301 9876543', 'hogarseguro@tibyhuellitas.com', 'foundation', 8, 5, 2),
  ('550e8400-e29b-41d4-a716-446655440002'::UUID, 'Amor Felino', 'Centro especializado en rescate de gatos callejeros', 4.7200, -74.0500, 'Calle 80 #15-45, Bogotá', '+57 320 5555555', 'amorfelino@tibyhuellitas.com', 'privateRescue', 12, 6, 1)
ON CONFLICT DO NOTHING;

-- Insertar mascotas con datos COMPLETOS
INSERT INTO pets (id, name, species, breed, size, age_in_months, gender, description, photo_urls, refuge_id, health_status, personality_traits, requires_special_care, additional_notes)
VALUES 
  -- PERROS
  ('650e8400-e29b-41d4-a716-446655440000'::UUID, 'Luna', 'dog', 'Labrador Retriever', 'large', 24, 'Hembra', 'Luna es una perrita muy cariñosa, juguetona y perfecta para familias', ARRAY['https://images.unsplash.com/photo-1633722715463-d30628cfa30b?w=500&q=80', 'https://images.unsplash.com/photo-1558788353-f76d92427f16?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440000'::UUID, ARRAY['vaccinated', 'dewormed', 'sterilized'], ARRAY['juguetón', 'cariñoso', 'ideal para niños'], false, 'Muy amigable con niños'),
  ('650e8400-e29b-41d4-a716-446655440002'::UUID, 'Rocky', 'dog', 'Pastor Alemán', 'large', 36, 'Macho', 'Rocky es un perro energético, leal y protector. Necesita ejercicio diario', ARRAY['https://images.unsplash.com/photo-1611003228941-98852ba62227?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440001'::UUID, ARRAY['vaccinated', 'microchipped', 'sterilized'], ARRAY['energético', 'leal', 'requiere ejercicio'], false, 'Requiere propietario con experiencia'),
  ('650e8400-e29b-41d4-a716-446655440003'::UUID, 'Max', 'dog', 'Golden Retriever', 'large', 18, 'Macho', 'Max es un perro alegre y cariñoso que ama jugar en el parque', ARRAY['https://images.unsplash.com/photo-1633631970434-fef0a7ea93d3?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440000'::UUID, ARRAY['vaccinated', 'dewormed'], ARRAY['juguetón', 'cariñoso', 'ideal para niños'], false, 'Ideal para familias activas'),
  ('650e8400-e29b-41d4-a716-446655440004'::UUID, 'Toby', 'dog', 'Cocker Spaniel', 'medium', 12, 'Macho', 'Toby es pequeño, tierno y adorable. Perfecto para apartamentos', ARRAY['https://images.unsplash.com/photo-1616037541085-7065b106bbe6?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440001'::UUID, ARRAY['vaccinated', 'sterilized'], ARRAY['tranquilo', 'cariñoso', 'apto apartamento'], false, 'Excelente compañero de apartamento'),
  
  -- GATOS
  ('650e8400-e29b-41d4-a716-446655440001'::UUID, 'Michi', 'cat', 'Persa', 'small', 12, 'Hembra', 'Michi es una gatita independiente pero cariñosa que busca tranquilidad', ARRAY['https://images.unsplash.com/photo-1574158622682-e40e69881006?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440000'::UUID, ARRAY['vaccinated', 'sterilized', 'dewormed'], ARRAY['tranquilo', 'independiente', 'apto apartamento'], false, 'Gato de interior, necesita hogar tranquilo'),
  ('650e8400-e29b-41d4-a716-446655440005'::UUID, 'Garfield', 'cat', 'Gato Naranja', 'medium', 24, 'Macho', 'Garfield es un gato calmado que le encanta dormir en el sofá y ronronear', ARRAY['https://images.unsplash.com/photo-1596854407944-bf87f6fdd49e?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440002'::UUID, ARRAY['vaccinated', 'sterilized'], ARRAY['tranquilo', 'cariñoso', 'apto apartamento'], false, 'Le encanta la compañía de humanos'),
  ('650e8400-e29b-41d4-a716-446655440006'::UUID, 'Princesa', 'cat', 'Gato Blanco y Negro', 'small', 8, 'Hembra', 'Princesa es una gatita joven, curiosa y muy juguetona', ARRAY['https://images.unsplash.com/photo-1606214174585-fe31582dc1d4?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440002'::UUID, ARRAY['vaccinated', 'dewormed'], ARRAY['juguetón', 'energético', 'curioso'], false, 'Joven y llena de energía'),
  ('650e8400-e29b-41d4-a716-446655440007'::UUID, 'Nala', 'cat', 'Gato Siamés', 'small', 18, 'Hembra', 'Nala es una gata elegante y sociable que disfruta de interacción humana', ARRAY['https://images.unsplash.com/photo-1589941013453-ec89f33b76be?w=500&q=80'], '550e8400-e29b-41d4-a716-446655440000'::UUID, ARRAY['vaccinated', 'sterilized', 'microchipped'], ARRAY['sociable', 'cariñoso', 'ideal para niños'], false, 'Le encanta ser el centro de atención')
ON CONFLICT DO NOTHING;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE users IS 'Perfil de usuarios - extensión de auth.users de Supabase';
COMMENT ON TABLE refuges IS 'Refugios y centros de adopción de mascotas';
COMMENT ON TABLE pets IS 'Mascotas disponibles para adopción';
COMMENT ON TABLE adoption_requests IS 'Solicitudes de adopción de usuarios';

-- ============================================
-- INSTRUCCIONES
-- ============================================

/*
PASOS PARA CONFIGURAR:

1. Ve a https://supabase.com/dashboard
2. Selecciona tu proyecto TIBYHUELLITAS
3. Ve a "SQL Editor"
4. Copia TODO el contenido de este archivo
5. Pégalo en el SQL Editor
6. Haz clic en "Run" (Ctrl+Enter)
7. ¡Listo! Las tablas serán creadas con DATOS REALES

TABLAS CREADAS:
  ✓ users - Perfil de usuarios (roles: adopter, refuge, admin)
  ✓ refuges - Refugios y centros de adopción (3 refugios de ejemplo)
  ✓ pets - Mascotas disponibles (8 mascotas: 4 perros + 4 gatos)
  ✓ adoption_requests - Solicitudes de adopción
  ✓ favorites - Mascotas favoritas del usuario

FLUJO DE INGRESO DE MASCOTAS:
  
  1. Refugio se registra con role = 'refuge'
  2. Refugio accede al formulario "Nueva Mascota"
  3. Completa todos los campos:
     - Fotos (1-5 fotos, la primera es la principal)
     - Nombre de la mascota
     - Especie (dog, cat, rabbit, bird, other)
     - Raza
     - Descripción (personalidad, historia, comportamiento)
     - Rasgos de personalidad (juguetón, tranquilo, cariñoso, ideal para niños, apto departamento)
     - Estado de salud (vacunado, desparasitado, esterilizado, microchip, requiere cuidados especiales)
     - Notas adicionales de salud (opcional)
  4. Sistema guarda en tabla 'pets' con refuge_id del refugio autenticado

CAMPOS DE LA TABLA 'pets':
  - id (UUID, auto-generado)
  - name (VARCHAR) - Nombre de la mascota
  - species (ENUM: dog, cat, rabbit, bird, other)
  - breed (VARCHAR) - Raza
  - size (ENUM OPTIONAL: small, medium, large)
  - age_in_months (INTEGER OPTIONAL) - Edad en meses
  - gender (VARCHAR OPTIONAL) - Género
  - description (TEXT) - Descripción detallada
  - photo_urls (TEXT ARRAY) - URLs de fotos (1-5 máximo)
  - refuge_id (UUID) - ID del refugio que la registra
  - health_status (TEXT ARRAY) - Estado de salud
  - personality_traits (TEXT ARRAY) - Rasgos de personalidad
  - requires_special_care (BOOLEAN) - Si requiere cuidados especiales
  - additional_notes (TEXT) - Notas adicionales de salud
  - created_at, updated_at (TIMESTAMP)

DATOS INCLUIDOS EN ESTE SCRIPT:
  
  REFUGIOS (3):
    1. Patitas Felices (Shelter) - +57 310 1234567
    2. Hogar Seguro (Foundation) - +57 301 9876543
    3. Amor Felino (Private Rescue) - +57 320 5555555
  
  MASCOTAS (8 - ingresadas como ejemplo):
    - 4 Perros: Luna, Rocky, Max, Toby
    - 4 Gatos: Michi, Garfield, Princesa, Nala
    - Con fotos, edad, raza, salud y rasgos de personalidad

SEGURIDAD (RLS):
  ✓ refuges - Públicas (todos ven todos los refugios)
  ✓ pets - Públicas (todos ven todas las mascotas)
  ✓ adoption_requests - Privadas (cada usuario solo ve sus solicitudes)
  ✓ favorites - Privadas (cada usuario solo ve sus favoritos)
  ✓ users - Privadas (cada usuario solo ve su perfil)

PRÓXIMOS PASOS:
  1. Ejecutar este SQL en Supabase
  2. Crear UI para que refugios registren mascotas
  3. Implementar validación de campos
  4. Agregar upload de imágenes a Supabase Storage

¡Ahora los refugios pueden registrar y gestionar sus mascotas!
*/

-- TABLA: chat_messages (Historial del chat con Gemini)
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  sender VARCHAR(20) NOT NULL CHECK (sender IN ('user', 'assistant')),
  message TEXT NOT NULL,
  pet_context UUID REFERENCES pets(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- RLS (Row Level Security) para chat_messages
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo ven sus propios mensajes
CREATE POLICY "Users can view their own chat messages"
  ON chat_messages FOR SELECT
  USING (user_id = auth.uid());

-- Política: Los usuarios solo insertan mensajes propios
CREATE POLICY "Users can insert their own chat messages"
  ON chat_messages FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Política: Los usuarios solo pueden borrar sus propios mensajes
CREATE POLICY "Users can delete their own chat messages"
  ON chat_messages FOR DELETE
  USING (user_id = auth.uid());
