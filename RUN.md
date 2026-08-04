# Cómo correr TenjoMicilios en local

## Requisitos previos
- .NET SDK 10+ (`dotnet --version`)
- Node.js LTS (`node --version`, `npm --version`)
- Herramienta `dotnet-ef`: `dotnet tool install --global dotnet-ef`
- PostgreSQL instalado y corriendo localmente
- Flutter SDK (ver sección "App móvil" más abajo)

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

## App móvil (Flutter)

### Instalación del SDK (una sola vez)
1. Descarga el SDK de Flutter (canal estable) desde https://docs.flutter.dev/get-started/install y extráelo, por ejemplo, a `C:\src\flutter`.
2. Agrega `C:\src\flutter\bin` a tu PATH (o inclúyelo en la sesión actual):
   ```
   $env:PATH = "C:\src\flutter\bin;" + $env:PATH
   ```
3. Verifica la instalación:
   ```
   flutter --version
   flutter doctor -v
   ```
4. Para compilar/correr en un emulador o celular Android necesitas Android Studio (instala el SDK de Android y los emuladores):
   - Descarga e instala Android Studio: https://developer.android.com/studio
   - Ábrelo una vez para completar el asistente inicial (instala el Android SDK, platform-tools y un emulador).
   - Verifica que `flutter doctor` ya no marque error en "Android toolchain".

### Correr la app
```
cd mobile
flutter pub get   # solo la primera vez, o despues de cambios en pubspec.yaml
flutter devices   # ver que dispositivos estan disponibles
```

Opciones para probar sin Android configurado todavía:
- **Windows Desktop** (requiere Visual Studio con el workload "Desktop development with C++"):
  ```
  flutter run -d windows
  ```
- **Navegador (como servidor web, para verla en Chrome/Edge)**:
  ```
  flutter run -d web-server --web-port=8888
  ```
  Luego abre `http://localhost:8888` en el navegador.

Con Android Studio y un emulador/celular conectado:
```
flutter run -d <device-id>   # el id sale de "flutter devices"
```

Comandos útiles mientras `flutter run` está activo: `r` recarga en caliente, `R` reinicio en caliente, `q` para salir.

## Notas
- Los dos deben estar corriendo al mismo tiempo (en terminales separadas) para que la app admin funcione.
- Si cambias `Program.cs` o agregas una migración, reinicia el backend (`dotnet run` no recarga automáticamente cambios de código de nivel superior).
- Si agregas o quitas un modelo, crea una nueva migración antes de correr la app:
  ```
  cd backend/TenjoMovil.Api
  dotnet ef migrations add <NombreMigracion>
  dotnet ef database update
  ```
