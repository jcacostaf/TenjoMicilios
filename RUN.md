# Running TenjoMicilios Locally

## Prerequisites
- .NET SDK 10+ (`dotnet --version`)
- Node.js LTS (`node --version`, `npm --version`)
- `dotnet-ef` tool: `dotnet tool install --global dotnet-ef`

## Backend (API)

Uses PostgreSQL. Copy the example config and set your local password:

```
cd backend/TenjoMovil.Api
cp appsettings.Development.json.example appsettings.Development.json
# edit appsettings.Development.json and set your real PostgreSQL password
```

Then create the database (if it doesn't exist yet) and run:

```
dotnet ef database update   # only needed the first time, or after new migrations
dotnet run --urls http://localhost:5145
```

The API will be available at `http://localhost:5145`. Endpoints:
- `GET /api/stores`
- `POST /api/stores`
- `PUT /api/stores/{id}`
- `GET /api/drivers`
- `POST /api/drivers/{id}/location`

Data is stored in a local SQLite file (`tenjomovil.db`) created inside `backend/TenjoMovil.Api`.

## Frontend (Admin)

```
cd frontend/admin
npm install   # only needed the first time, or after dependency changes
npm run dev
```

The admin app will be available at `http://localhost:5173`. It expects the backend to be running at `http://localhost:5145`.

## Notes
- Both must run at the same time (in separate terminals) for the admin app to work.
- If you change `Program.cs` or add a migration, restart the backend (`dotnet run` does not hot-reload top-level code changes).
- If you add/remove a model, create a new migration before running the app:
  ```
  cd backend/TenjoMovil.Api
  dotnet ef migrations add <MigrationName>
  dotnet ef database update
  ```
