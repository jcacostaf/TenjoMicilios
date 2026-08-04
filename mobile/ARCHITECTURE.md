# Arquitectura de la App Movil (Flutter)

Un solo codigo Flutter para todos los roles (consumidor, repartidor, restaurante), dividido por feature. Cada rol tiene su propia carpeta bajo `features/`, sin mezclar navegacion entre roles.

```
lib/
  main.dart              Punto de entrada. Pantalla de bienvenida y enrutamiento
                          inicial hacia el flujo de cada rol.

  core/                  Codigo compartido entre features.
    api_config.dart       URL base del backend.
    models/                Clases planas que reflejan las entidades del backend
                            (Store, Product), con fromJson/toJson.
    services/
      api_service.dart      Todas las llamadas HTTP al backend, centralizadas aqui.

  features/
    restaurant/            Todo lo especifico del rol "restaurante".
      store_selector_screen.dart   Elegir que tienda administrar.
      catalog_screen.dart          Lista de productos, activar/desactivar.
      product_form_screen.dart     Crear/editar producto (nombre, precio,
                                    foto, activo).
    consumer/               (pendiente) flujo del consumidor.
    driver/                 (pendiente) flujo del repartidor.
```

## Convenciones

- **Un servicio central de API** (`core/services/api_service.dart`): las pantallas no llaman `http` directamente, siempre pasan por `ApiService`.
- **Modelos livianos**: `core/models/` son solo datos (sin logica), con `fromJson`/`toJson` para hablar con el backend.
- **Sin manejo de estado global todavia**: cada pantalla mantiene su propio estado con `StatefulWidget` (`FutureBuilder` para cargas async). Si la complejidad crece, evaluar Riverpod (como se penso originalmente en `projectdescription.md`).
- **Separacion por rol**: nunca mezclar widgets/pantallas de distintos roles en la misma carpeta de `features/`.

Ver tambien: [ARCHITECTURE.md general](../ARCHITECTURE.md) en la raiz del repo.
