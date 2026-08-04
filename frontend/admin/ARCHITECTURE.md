# Arquitectura del Frontend Admin

App React (Vite), sencilla y de una sola capa por ahora: no hay gestion de estado global, ni carpetas de "features" todavia. Cada pantalla es un componente en `src/`.

```
src/
  App.jsx            Layout raiz: barra de navegacion + selector de pantalla.
  StoresScreen.jsx    Pantalla de mapa, formulario y lista de tiendas (crear/editar).
  LiveDrivers.jsx     Pantalla de ubicacion de conductores (polling cada 5s).
```

## Convenciones actuales

- Cada pantalla llama directo a la API del backend con `fetch` (sin capa de servicio separada todavia).
- La URL del backend esta hardcodeada como constante al inicio de cada archivo (`http://localhost:5145`).
- Estilos con Bootstrap (clases utilitarias), sin CSS a medida salvo lo minimo en `App.css`.

## Cuando crezca

Si el admin gana mas pantallas (ej. gestion de catalogo, pedidos), conviene introducir:
- Una carpeta `services/` con las llamadas a la API (equivalente a `Abstractions`/`Infrastructure` del backend, pero simple).
- Carpetas por feature si el numero de pantallas por area crece (`features/stores/`, `features/drivers/`).

Ver tambien: [ARCHITECTURE.md general](../ARCHITECTURE.md) en la raiz del repo.
