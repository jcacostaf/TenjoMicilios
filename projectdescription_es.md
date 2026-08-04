# TenjoMovil - Descripción del Proyecto

## Resumen
Una plataforma de app de domicilios para un pueblo pequeño (~15,000 personas máximo), que conecta a **consumidores**, **repartidores** y **restaurantes/tiendas** mediante apps móviles específicas para cada rol, con un backend compartido y una plataforma de administración para registrar comercios.

---

## Stack Tecnológico

### Apps Móviles (Consumidor, Repartidor, Restaurante)
- **Framework:** Flutter (Dart)
- **Por qué:** Excelente rendimiento en celulares Android de gama baja (importante para repartidores), animaciones fluidas de mapas/tiempo real, un solo código para iOS + Android, menor consumo de batería que React Native, se combina bien con un backend moderno en .NET.
- **Manejo de estado:** Riverpod (sugerido)
- **Estructura:** Un solo código Flutter, dividido por rol en `/features/consumer`, `/features/driver`, `/features/restaurant`, con un `/core` compartido (modelos, servicios, utilidades).

### Plataforma Web de Administración
- **Framework:** React (o Blazor, ya que el backend es .NET)
- **Por qué:** Los administradores necesitan una experiencia cómoda de escritorio — interfaz de mapa, tablas de datos, acciones masivas. No es un buen ajuste para Flutter, que es mobile-first.
- **Función clave (v1):** Herramienta de registro de tiendas basada en mapa — el admin selecciona una ubicación en el mapa, ingresa los datos de la tienda y envía una invitación por correo al dueño.

### Backend
- **Framework:** ASP.NET Core (.NET 8+)
- **Por qué:** Maduro, escalable, multiplataforma, tipado fuerte, buenas herramientas, soporte nativo de tiempo real con SignalR.
- **Tiempo real:** SignalR (actualizaciones de estado de pedidos, ubicación del repartidor en vivo).
- **Trabajos en segundo plano:** Hangfire (para notificaciones, tareas programadas).

### Base de Datos
- **Principal:** PostgreSQL (con PostGIS para consultas geoespaciales — asignación de repartidores, zonas de entrega, cálculo de distancias).
- **Caché:** Redis (planeado, para estado de pedidos/ubicación de repartidores en tiempo real a mayor escala).

### Notificaciones
- **Notificaciones push:** Firebase Cloud Messaging (FCM) — nivel gratuito, se integra de forma nativa con Flutter.
- **SMS de respaldo:** Twilio — usado para notificar repartidores en caso de que el push falle (celulares viejos, mala conexión).

### Mapas y Rutas
- **Candidato elegido:** Mapbox — mejor optimización de rutas para entregas con varias paradas, marca/estilo personalizado, mapas sin conexión.
- **Alternativa:** Google Maps API — mejor precisión y cobertura global, integración más simple, pero más costoso por solicitud y menos flexible en rutas.
- **Decisión:** Se prefiere Mapbox para las necesidades de rutas de entrega; Google Maps queda como respaldo si la calidad del mapa de la región es mejor para ese pueblo.

### Servicio de Correo (Admin → Invitaciones a Tiendas)
- **SendGrid** (nivel gratuito: 100 correos/día, suficiente para la escala de un pueblo pequeño).

### Hosting (escala objetivo: pueblo de 15,000 personas)
| Servicio | Proveedor | Costo estimado |
|---|---|---|
| Hosting del backend | DigitalOcean App Platform | ~$12/mes |
| Base de datos | DigitalOcean Managed PostgreSQL | ~$15/mes |
| Notificaciones push | Firebase | Nivel gratuito |
| Mapas/rutas | Mapbox | ~$10-50/mes (según uso) |
| Dominio | Namecheap/GoDaddy | ~$12/año |
| **Total estimado** | | **~$40-60/mes** |

Alternativa considerada: Azure App Service (encaje nativo con .NET, ~$15-50/mes) — viable si más adelante se quiere una integración más profunda con el ecosistema Azure (por ejemplo, Azure AD, Azure Maps).

---

## Publicación de la App
- **Google Play Console:** Cuota única de registro de $25. Publicación vía `flutter build appbundle --release`, subiendo el `.aab` firmado.
- **Apple App Store:** Programa de Desarrollador de Apple, $99/año. Publicación vía `flutter build ios --release`, archivado y subido con Xcode/Transporter a App Store Connect.
- Ambas plataformas requieren: política de privacidad, contacto de soporte, ícono de la app (1024x1024), capturas de pantalla y justificación de permisos (ubicación, cámara, etc).

---

## Arquitectura del Sistema

```
Portal Web de Administración (React)
        │
        ▼
API en ASP.NET Core (.NET 8+)
        │
        ├── PostgreSQL (tiendas, usuarios, invitaciones, pedidos)
        ├── SignalR (actualizaciones en tiempo real de pedidos/repartidores)
        ├── SendGrid (correos de invitación)
        ├── Firebase (notificaciones push)
        ├── Twilio (SMS de respaldo)
        └── Mapbox / Google Maps (rutas, geolocalización)
        │
        ▼
Apps Flutter (interfaz por rol)
    ├── App del Consumidor
    ├── App del Repartidor
    └── App del Restaurante
```

---

## Modelo de Datos (inicial)

### stores (tiendas)
- id, name, address, latitude, longitude, phone, category, status (pendiente/invitada/activa/suspendida), created_by, created_at, activated_at

### invitations (invitaciones)
- id, store_id, email, token, status (enviada/abierta/completada/expirada), expires_at, created_at

### restaurant_users (usuarios del restaurante)
- id, store_id, email, password_hash, name, role (dueño/gerente/personal), created_at, last_login

*(las tablas de consumidor, repartidor y pedidos se definirán en fases posteriores)*

---

## Orden de Construcción / Hoja de Ruta

1. **Plataforma admin — registro de tiendas vía mapa** (fase actual)
   - El admin selecciona la ubicación en el mapa, ingresa los datos de la tienda y envía correo de invitación.
2. **Flujo de registro e inicio de sesión del dueño de tienda**
   - Enlace de invitación seguro con token, configuración de contraseña, inicio de sesión con JWT.
3. **Portal básico de restaurante**
   - Inicio de sesión + dashboard de marcador de posición ("pedidos próximamente").
4. **App del consumidor**
   - Explorar restaurantes registrados, hacer pedidos.
5. **App del repartidor**
   - Aceptar entregas, seguimiento en tiempo real, ganancias.
6. **Flujo de pedidos en tiempo real de principio a fin**
   - El restaurante recibe el pedido → el repartidor lo acepta → el consumidor lo sigue en vivo.

---

## Tiendas sin ubicación registrada en el mapa
- Aunque una tienda no esté registrada en Google Maps/Mapbox, el admin puede crearla manualmente ingresando su ubicación y datos a mano.
- Esa tienda queda visible igual para consumidores, repartidores, restaurantes y el panel de admin.

---

## Principios Clave de Diseño
- **Separación de roles:** Cada tipo de usuario (consumidor/repartidor/restaurante/admin) tiene su propio flujo de interfaz aislado — sin navegación mezclada.
- **Núcleo compartido:** Los modelos/servicios comunes viven en una capa compartida para evitar duplicación entre los módulos de Flutter por rol.
- **Autorización aplicada en el backend:** Las validaciones de rol ocurren en el servidor (`[Authorize(Roles = "...")]`), no solo ocultas en la interfaz.
- **Empezar por el lado de la oferta:** Registrar restaurantes primero mediante la herramienta admin antes de construir el flujo completo de pedidos — esto permite tracción real temprana mientras se construye el resto de la app.

---

*Última actualización: refleja las decisiones de arquitectura y stack de la conversación inicial del proyecto.*
