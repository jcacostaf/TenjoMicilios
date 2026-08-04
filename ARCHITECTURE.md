# Arquitectura de TenjoMicilios

Este repo tiene tres proyectos independientes. Cada uno tiene su propio `ARCHITECTURE.md` con el detalle de su estructura y convenciones:

- **[backend/TenjoMovil.Api/ARCHITECTURE.md](backend/TenjoMovil.Api/ARCHITECTURE.md)** — API en ASP.NET Core. Sigue una arquitectura por capas (Entities / Abstractions / Domains / Infrastructure / Controllers), con una clase por caso de uso. **Toda funcionalidad nueva del backend debe seguir este patron.**
- **[frontend/admin/ARCHITECTURE.md](frontend/admin/ARCHITECTURE.md)** — Panel de administracion en React. Estructura simple por pantalla, todavia sin capas formales.
- **[mobile/ARCHITECTURE.md](mobile/ARCHITECTURE.md)** — App movil en Flutter, un solo codigo dividido por rol (`features/consumer`, `features/driver`, `features/restaurant`) con un `core/` compartido.

Para levantar cada proyecto en local, ver [RUN.md](RUN.md).
