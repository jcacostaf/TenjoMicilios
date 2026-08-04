# Cómo correr TenjoMicilios en local

## Requisitos previos
- .NET SDK 10+ (`dotnet --version`)
- Node.js LTS (`node --version`, `npm --version`)
- Herramienta `dotnet-ef`: `dotnet tool install --global dotnet-ef`
- PostgreSQL instalado y corriendo localmente

## Backend (API)

Usa PostgreSQL. Copia el archivo de configuración de ejemplo y pon tu contraseña local:

```
cd backend/TenjoMovil.Api
cp appsettings.Development.json.example appsettings.Development.json
# edita appsettings.Development.json y pon tu contraseña real de PostgreSQL
```

Luego crea la base de datos (si no existe todavía) y corre el backend:

```
dotnet ef database update   # solo la primera vez, o despues de nuevas migraciones
dotnet run --urls http://localhost:5145
```

La API quedará disponible en `http://localhost:5145`. Endpoints:
- `GET /api/stores`
- `POST /api/stores`
- `PUT /api/stores/{id}`
- `GET /api/drivers`
- `POST /api/drivers/{id}/location`

Los datos se guardan en una base de datos PostgreSQL local llamada `tenjomovil`.

## Frontend (Admin)

```
cd frontend/admin
npm install   # solo la primera vez, o despues de cambios en dependencias
npm run dev
```

La app de administración quedará disponible en `http://localhost:5173`. Necesita que el backend esté corriendo en `http://localhost:5145`.

## Notas
- Los dos deben estar corriendo al mismo tiempo (en terminales separadas) para que la app admin funcione.
- Si cambias `Program.cs` o agregas una migración, reinicia el backend (`dotnet run` no recarga automáticamente cambios de código de nivel superior).
- Si agregas o quitas un modelo, crea una nueva migración antes de correr la app:
  ```
  cd backend/TenjoMovil.Api
  dotnet ef migrations add <NombreMigracion>
  dotnet ef database update
  ```
