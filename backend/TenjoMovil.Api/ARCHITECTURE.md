# Arquitectura del Backend (TenjoMovil.Api)

Este proyecto sigue una arquitectura por capas. Es un solo proyecto `.csproj` (no una solución multi-proyecto), organizado en carpetas que separan responsabilidades.

**Toda funcionalidad nueva debe seguir este mismo patron.** No agregar endpoints como Minimal API (`app.MapGet(...)` lambdas) directamente en `Program.cs`.

## Capas

```
Entities/           Entidades planas (POCOs), sin logica. Ej: Store, Driver, Product.

Abstractions/
  <Area>/
    I<Area>Repository.cs   Interfaz de escritura: Add, GetById, Remove.
    I<Area>Queries.cs      Interfaz de lectura: List, filtros.
  Persistence/
    IUnitOfWork.cs          BeginAsync / CommitAsync / RollbackAsync.

Domains/
  <Area>/
    <Verbo><Area>Domain.cs  Una clase por caso de uso. Ej: CreateProductDomain,
                            UpdateProductDomain, ProductListDomain.
                            Cada una expone un enum <Verbo><Area>Status y un
                            record <Verbo><Area>Result(Status, Entity?).
                            Aqui vive la logica de negocio, envuelta en
                            uow.BeginAsync/CommitAsync/RollbackAsync.

Infrastructure/
  Persistence/
    AppDbContext.cs         DbContext de EF Core.
    UnitOfWork.cs            Implementacion de IUnitOfWork.
  Repositories/              Implementaciones EF Core de I<Area>Repository.
  Queries/                   Implementaciones EF Core de I<Area>Queries.
  Storage/                   Otras abstracciones de infraestructura (ej. fotos).
  DependencyInjection.cs     AddInfrastructure(services, config): registra
                              DbContext, UnitOfWork, repositorios y queries.

Controllers/
  <Area>Controller.cs        Controladores MVC ([ApiController]), no Minimal API.
                              Inyectan los Domains via [FromServices] y traducen
                              el Result.Status a respuestas HTTP con un switch.
```

## Ejemplo de flujo (crear un producto)

1. `POST /api/stores/{storeId}/products` llega a `ProductsController.Create`.
2. El controller llama a `CreateProductDomain.CreateAsync(storeId, product, ct)`.
3. `CreateProductDomain` usa `IProductRepository` (via `IUnitOfWork`) para guardar.
4. El controller mapea `CreateProductResult.Status` a la respuesta HTTP (`Created`, etc).

## Program.cs

Debe quedar delgado: registra `AddControllers()`, `AddInfrastructure(...)`, cada `Domain` como `AddScoped<...>()`, y `MapControllers()`. No debe tener logica de negocio ni queries de EF directas.

## Por que este patron

- Separa la logica de negocio (Domains) de los detalles de HTTP (Controllers) y de persistencia (Infrastructure).
- Cada caso de uso es una clase pequeña y facil de testear de forma aislada.

Ver también: [ARCHITECTURE.md general](../../ARCHITECTURE.md) en la raiz del repo.
