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

app.Run();
