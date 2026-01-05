-- ============================================
-- TIBYFOOD CON LOGIN - TABLAS SUPABASE
-- ============================================

-- 1. TABLA: users (extensión del auth de Supabase)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(255),
  phone_number VARCHAR(20),
  address TEXT,
  profile_image_url VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE,
  is_email_verified BOOLEAN DEFAULT FALSE
);

-- 2. TABLA: products
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image_url VARCHAR(500),
  category VARCHAR(100),
  is_vegetarian BOOLEAN DEFAULT FALSE,
  has_offer BOOLEAN DEFAULT FALSE,
  offer_price DECIMAL(10, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLA: orders
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  items JSONB NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'delivered', 'cancelled')),
  delivery_address TEXT NOT NULL,
  phone_number VARCHAR(20) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ÍNDICES PARA MEJOR RENDIMIENTO
-- ============================================

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_has_offer ON products(has_offer);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) - SEGURIDAD
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS: users
CREATE POLICY users_select_policy ON users FOR SELECT
  USING (auth.uid() = id OR (SELECT auth.role() = 'authenticated'));

CREATE POLICY users_insert_policy ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY users_update_policy ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY users_delete_policy ON users FOR DELETE
  USING (auth.uid() = id);

-- POLÍTICAS: products (públicos, todos pueden ver)
CREATE POLICY products_select_policy ON products FOR SELECT
  USING (true);

CREATE POLICY products_insert_policy ON products FOR INSERT
  WITH CHECK ((SELECT auth.role() = 'authenticated'));

CREATE POLICY products_update_policy ON products FOR UPDATE
  USING ((SELECT auth.role() = 'authenticated'));

CREATE POLICY products_delete_policy ON products FOR DELETE
  USING ((SELECT auth.role() = 'authenticated'));

-- POLÍTICAS: orders (cada usuario ve solo sus órdenes)
CREATE POLICY orders_select_policy ON orders FOR SELECT
  USING (auth.uid() = user_id OR (SELECT auth.role() = 'authenticated'));

CREATE POLICY orders_insert_policy ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY orders_update_policy ON orders FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY orders_delete_policy ON orders FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- DATOS DE EJEMPLO
-- ============================================

-- Insertar algunos productos de ejemplo
INSERT INTO products (name, description, price, category, image_url, is_vegetarian, has_offer, offer_price) 
VALUES 
  ('Hamburguesa Clásica', 'Hamburguesa con carne, lechuga y tomate', 8.99, 'burgers', 'https://via.placeholder.com/200', false, true, 7.99),
  ('Pizza Margherita', 'Pizza con queso mozzarella y tomate fresco', 12.99, 'pizza', 'https://via.placeholder.com/200', true, false, NULL),
  ('Pollo Frito', 'Pollo crujiente con papas y ensalada', 10.99, 'chicken', 'https://via.placeholder.com/200', false, true, 8.99),
  ('Ensalada Griega', 'Ensalada fresca con queso feta', 6.99, 'salads', 'https://via.placeholder.com/200', true, false, NULL),
  ('Tacos al Pastor', 'Tacos con carne asada y piña', 5.99, 'mexican', 'https://via.placeholder.com/200', false, false, NULL),
  ('Pasta Carbonara', 'Pasta fresca con salsa carbonara auténtica', 9.99, 'pasta', 'https://via.placeholder.com/200', true, true, 8.99)
ON CONFLICT DO NOTHING;

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista: Órdenes con detalles de usuario
CREATE OR REPLACE VIEW orders_with_user AS
SELECT 
  o.id,
  o.user_id,
  u.email,
  u.full_name,
  u.phone_number as user_phone,
  o.items,
  o.total_price,
  o.status,
  o.delivery_address,
  o.phone_number,
  o.created_at,
  o.updated_at
FROM orders o
JOIN users u ON o.user_id = u.id
ORDER BY o.created_at DESC;

-- Vista: Productos con información de descuento
CREATE OR REPLACE VIEW products_with_price AS
SELECT 
  id,
  name,
  description,
  price,
  CASE 
    WHEN has_offer THEN offer_price
    ELSE price
  END AS effective_price,
  CASE 
    WHEN has_offer THEN ROUND(((price - offer_price) / price * 100)::numeric, 2)
    ELSE 0
  END AS discount_percentage,
  image_url,
  category,
  is_vegetarian,
  has_offer,
  offer_price,
  created_at,
  updated_at
FROM products
ORDER BY category, name;

-- ============================================
-- FUNCIONES ÚTILES
-- ============================================

-- Función: Obtener órdenes pendientes del usuario actual
CREATE OR REPLACE FUNCTION get_user_pending_orders()
RETURNS TABLE (id UUID, total_price DECIMAL, created_at TIMESTAMP WITH TIME ZONE) AS $$
BEGIN
  RETURN QUERY
  SELECT o.id, o.total_price, o.created_at
  FROM orders o
  WHERE o.user_id = auth.uid() AND o.status = 'pending'
  ORDER BY o.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Función: Actualizar last_login del usuario
CREATE OR REPLACE FUNCTION update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users SET last_login = NOW() WHERE id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================

COMMENT ON TABLE users IS 'Perfil de usuarios - extensión de auth.users de Supabase';
COMMENT ON TABLE products IS 'Catálogo de productos/comida disponibles';
COMMENT ON TABLE orders IS 'Órdenes realizadas por usuarios con items en formato JSONB';

COMMENT ON COLUMN orders.items IS 'Array JSON con estructura: [{productId, productName, price, quantity, imageUrl}]';
COMMENT ON COLUMN products.offer_price IS 'Precio con descuento - solo se usa si has_offer = true';
COMMENT ON COLUMN users.is_email_verified IS 'Flag para saber si el usuario verificó su email';

-- ============================================
-- INSTRUCCIONES DE USO
-- ============================================

/*
PASOS PARA CONFIGURAR EN SUPABASE:

1. Ve a https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Ve a "SQL Editor"
4. Copia TODO el contenido de este archivo
5. Pégalo en el SQL Editor
6. Haz clic en "Run" o presiona Ctrl+Enter
7. Espera a que termine (debe decir "No errors")

TABLAS CREADAS:
  • users - Perfiles de usuario
  • products - Catálogo de productos
  • orders - Historial de órdenes

SEGURIDAD:
  • RLS (Row Level Security) habilitado
  • Cada usuario solo ve sus propias órdenes
  • Los productos son públicos para todos

DATOS:
  • Se insertarán 6 productos de ejemplo
  • Puedes agregarr más manualmente o via API

ESTRUCTURA DE ORDEN (items en JSONB):
[
  {
    "productId": "uuid-aqui",
    "productName": "Nombre del producto",
    "price": 9.99,
    "quantity": 2,
    "imageUrl": "https://..."
  }
]

¡LISTO! Ahora puedes usar el app con Supabase.
*/
