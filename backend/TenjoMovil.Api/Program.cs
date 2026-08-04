using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Data;
using TenjoMovil.Api.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=tenjomovil.db"));
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

app.Run();

record DriverLocationUpdate(double Latitude, double Longitude, string? Name);
