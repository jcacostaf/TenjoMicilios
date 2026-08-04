# Arquitectura de TenjoMicilios

Este repo tiene tres proyectos independientes. Cada uno tiene su propio `ARCHITECTURE.md` con el detalle de su estructura y convenciones:

- **[backend/TenjoMovil.Api/ARCHITECTURE.md](backend/TenjoMovil.Api/ARCHITECTURE.md)** — API en ASP.NET Core. Sigue una arquitectura por capas (Entities / Abstractions / Domains / Infrastructure / Controllers), con una clase por caso de uso. **Toda funcionalidad nueva del backend debe seguir este patron.**
- **[frontend/admin/ARCHITECTURE.md](frontend/admin/ARCHITECTURE.md)** — Panel de administracion en React. Estructura simple por pantalla, todavia sin capas formales.
- **[mobile/ARCHITECTURE.md](mobile/ARCHITECTURE.md)** — App movil en Flutter, un solo codigo dividido por rol (`features/consumer`, `features/driver`, `features/restaurant`) con un `core/` compartido.

Para levantar cada proyecto en local, ver [RUN.md](RUN.md).

## Documentos de diseño

- **[docs/especificacion-logistica-repartidores.md](docs/especificacion-logistica-repartidores.md)** — Especificacion formal del sistema de pedidos y repartidores (maquinas de estado, eventos, sincronizacion offline, reasignacion, fases de implementacion). **Referencia obligatoria para cualquier trabajo futuro en el modulo de pedidos/repartidores.**
- **[docs/Delivery logistics.md](<docs/Delivery logistics.md>)** — Notas de analisis originales que dieron origen al documento anterior.
