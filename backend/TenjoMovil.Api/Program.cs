using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Data;
using TenjoMovil.Api.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors();
app.UseStaticFiles();

app.MapGet("/api/stores", async (AppDbContext db) =>
    await db.Stores.ToListAsync());

app.MapPost("/api/stores", async (AppDbContext db, Store store) =>
{
    db.Stores.Add(store);
    await db.SaveChangesAsync();
    return Results.Created($"/api/stores/{store.Id}", store);
});

app.MapPut("/api/stores/{id}", async (AppDbContext db, int id, Store updated) =>
{
    var store = await db.Stores.FindAsync(id);
    if (store is null) return Results.NotFound();

    store.Name = updated.Name;
    store.Address = updated.Address;
    store.Phone = updated.Phone;
    store.Category = updated.Category;
    store.Latitude = updated.Latitude;
    store.Longitude = updated.Longitude;

    await db.SaveChangesAsync();
    return Results.Ok(store);
});

app.MapGet("/api/drivers", async (AppDbContext db) =>
    await db.Drivers.ToListAsync());

app.MapPost("/api/drivers/{id}/location", async (AppDbContext db, int id, DriverLocationUpdate update) =>
{
    var driver = await db.Drivers.FindAsync(id);
    if (driver is null)
    {
        driver = new Driver { Id = id, Name = update.Name ?? $"Conductor {id}" };
        db.Drivers.Add(driver);
    }

    driver.Latitude = update.Latitude;
    driver.Longitude = update.Longitude;
    driver.UpdatedAt = DateTime.UtcNow;

    await db.SaveChangesAsync();
    return Results.Ok(driver);
});

app.MapGet("/api/stores/{storeId}/products", async (AppDbContext db, int storeId) =>
    await db.Products.Where(p => p.StoreId == storeId).ToListAsync());

app.MapPost("/api/stores/{storeId}/products", async (AppDbContext db, int storeId, Product product) =>
{
    product.StoreId = storeId;
    db.Products.Add(product);
    await db.SaveChangesAsync();
    return Results.Created($"/api/products/{product.Id}", product);
});

app.MapPut("/api/products/{id}", async (AppDbContext db, int id, Product updated) =>
{
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();

    product.Name = updated.Name;
    product.Description = updated.Description;
    product.Price = updated.Price;
    product.IsActive = updated.IsActive;

    await db.SaveChangesAsync();
    return Results.Ok(product);
});

const long maxPhotoBytes = 5 * 1024 * 1024; // 5 MB
var allowedPhotoExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };

app.MapPost("/api/products/{id}/photo", async (AppDbContext db, int id, IFormFile file) =>
{
    var product = await db.Products.FindAsync(id);
    if (product is null) return Results.NotFound();

    if (file.Length == 0) return Results.BadRequest("Archivo vacio.");
    if (file.Length > maxPhotoBytes) return Results.BadRequest("La foto supera el limite de 5MB.");

    var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
    if (!allowedPhotoExtensions.Contains(extension))
        return Results.BadRequest("Formato no soportado. Usa JPG, PNG o WEBP.");

    var uploadsPath = Path.Combine(AppContext.BaseDirectory, "wwwroot", "uploads");
    Directory.CreateDirectory(uploadsPath);

    var fileName = $"product-{id}-{Guid.NewGuid()}{extension}";
    var filePath = Path.Combine(uploadsPath, fileName);

    using (var stream = File.Create(filePath))
    {
        await file.CopyToAsync(stream);
    }

    product.ImageUrl = $"/uploads/{fileName}";
    await db.SaveChangesAsync();
    return Results.Ok(product);
}).DisableAntiforgery();

app.Run();

record DriverLocationUpdate(double Latitude, double Longitude, string? Name);
