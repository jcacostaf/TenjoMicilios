# Arquitectura de la App Movil (Flutter)

Un solo codigo Flutter para todos los roles (consumidor, repartidor, restaurante), dividido por feature. Cada rol tiene su propia carpeta bajo `features/`, sin mezclar navegacion entre roles.

```
lib/
  main.dart              Punto de entrada. Pantalla de bienvenida y enrutamiento
                          inicial hacia el flujo de cada rol.

  core/                  Codigo compartido entre features.
    api_config.dart       URL base del backend.
    models/                Clases planas que reflejan las entidades del backend
                            (Store, Product, Order/OrderDetail, ConsumerAddress,
                            DriverProfile, CartItem), con fromJson/toJson.
    services/
      api_service.dart      Todas las llamadas HTTP al backend, centralizadas aqui.
      geocoding_service.dart  Direccion de texto <-> coordenadas, via Nominatim (OSM).
      routing_service.dart    Ruta real por calles entre dos puntos, via OSRM.
      driver_identity_service.dart  Guarda localmente quien es el repartidor logueado.
      address_storage_service.dart  Guarda localmente las direcciones del consumidor.
      order_tracking_service.dart   Guarda localmente el pedido activo del consumidor
                                     (no hay cuenta/identidad de consumidor todavia).
    utils/
      geo.dart               Distancia entre coordenadas, limites de zoom del mapa,
                              y conversion lat/lng -> tile OSM (para precargar tiles).

  features/
    restaurant/            Todo lo especifico del rol "restaurante".
      store_selector_screen.dart   Elegir que tienda administrar.
      catalog_screen.dart          Lista de productos, activar/desactivar.
      product_form_screen.dart     Crear/editar producto (nombre, precio,
                                    foto, activo).
      orders_screen.dart           Pedidos entrantes y su estado.
    consumer/               Flujo del consumidor.
      business_list_screen.dart    Punto de entrada: negocios por categoria
                                    (chips), banner del pedido activo si hay uno.
      store_menu_screen.dart       Productos de un negocio, carrito en memoria.
      checkout_screen.dart         Direccion de entrega + confirmar pedido.
      order_tracking_screen.dart   Estado del pedido en vivo (sondeo cada 8s).
      address_list_screen.dart     Direcciones guardadas del consumidor.
      address_form_screen.dart     Elegir/confirmar una direccion en el mapa.
    driver/                 Flujo del repartidor.
      available_orders_screen.dart Pedidos disponibles para aceptar, y el activo.
      driver_navigation_screen.dart Mapa de navegacion en vivo del pedido activo.
```

## Convenciones

- **Un servicio central de API** (`core/services/api_service.dart`): las pantallas no llaman `http` directamente, siempre pasan por `ApiService`.
- **Modelos livianos**: `core/models/` son solo datos (sin logica), con `fromJson`/`toJson` para hablar con el backend.
- **Sin manejo de estado global todavia**: cada pantalla mantiene su propio estado con `StatefulWidget` (`FutureBuilder` para cargas async). Si la complejidad crece, evaluar Riverpod (como se penso originalmente en `projectdescription.md`).
- **Separacion por rol**: nunca mezclar widgets/pantallas de distintos roles en la misma carpeta de `features/`.

## Pedidos del consumidor

Sin pago y sin cuenta/login de consumidor todavia. El flujo es: `business_list_screen` (categoria via chips, filtrado en el cliente ya que `GET /api/stores` no filtra por categoria) -> `store_menu_screen` (carrito en memoria, `Map<productId, cantidad>`) -> `checkout_screen` (usa la direccion ya seleccionada en `AddressStorageService`, llama `ApiService.createOrder`) -> `order_tracking_screen` (sondea `GET /api/orders/{id}` cada 8s, mismo patron que `driver_navigation_screen`).

Como no hay identidad de consumidor en el backend, no hay forma de listar "mis pedidos" desde el servidor. En su lugar, `order_tracking_service.dart` guarda localmente el id del ultimo pedido activo (se limpia solo cuando llega a `Entregado`), y `business_list_screen` lo usa para mostrar un banner de "pedido activo" al volver a abrir la app. Es de un solo pedido a la vez, sin historial — si se necesita historial real, hace falta una identidad de consumidor en el backend primero.

## Geolocalizacion y mapas

Todo el mapa usa OpenStreetMap via `flutter_map` (sin API key ni costo). Tres servicios externos, todos gratuitos:

- **Tiles**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png` (sin subdominios `{s}` — OSM ya no los reparte por ahi, y usarlos rompe la cache de tiles precargados).
- **Geocoding** (`geocoding_service.dart`, Nominatim): direccion en texto -> coordenadas (`geocodeAddress`, para ubicar la direccion de entrega en el mapa) y coordenadas -> texto (`suggestAddress`, para sugerir la direccion al elegir un punto en el mapa).
- **Routing** (`routing_service.dart`, OSRM publico): ruta real por calles entre dos puntos, con distancia y tiempo estimado. Sin esto, el mapa solo podia dibujar una linea recta entre repartidor y destino, que cruzaba manzanas sin seguir las calles.

**Rango de zoom** (`geo.dart`): `workingAreaMinZoom`/`workingAreaMaxZoom` limitan que tan lejos se puede alejar o acercar el mapa, para no dejar ver mas alla del radio de cobertura de Tenjo (`maxDeliveryRadiusMeters`) ni acercarse mas de lo que las calles distinguen.

**Mapa de navegacion del repartidor** (`driver_navigation_screen.dart`), el mas elaborado:
- Sigue la posicion del repartidor con `Geolocator.getPositionStream` (no un solo `getCurrentPosition`).
- El destino cambia solo segun el estado del pedido: la tienda antes de recoger, la direccion de entrega (geocodificada) despues.
- Al abrir, la camara se encuadra automaticamente para mostrar repartidor + destino (`CameraFit.coordinates`), y se vuelve a encuadrar cuando llega la ruta real por calles (que puede salirse del encuadre recto inicial).
- Despues de ese encuadre inicial, la camara solo vuelve a centrarse cuando el repartidor se movio de verdad: se ignoran lecturas GPS con mala precision (`accuracy` > 50 m) y movimientos menores a 15 m, para no perder el encuadre por ruido del GPS (frecuente en desktop/wifi, donde no hay chip GPS real).

**Precarga de tiles** (`available_orders_screen.dart`): apenas se conoce la ubicacion del repartidor en la lista de pedidos (antes de aceptar ninguno), se precargan con `precacheImage` los tiles OSM alrededor suyo en los zooms que va a usar el mapa de navegacion. Asi, cuando abre un pedido, esos tiles ya estan en la cache del navegador. Se repite solo si el repartidor se movio mas de 200 m desde la ultima precarga.

Ver tambien: [ARCHITECTURE.md general](../ARCHITECTURE.md) en la raiz del repo.
