using TenjoMovil.Api.Domains.Drivers;
using TenjoMovil.Api.Domains.Orders;
using TenjoMovil.Api.Domains.Products;
using TenjoMovil.Api.Domains.Stores;
using TenjoMovil.Api.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

builder.Services.AddScoped<StoreListDomain>();
builder.Services.AddScoped<CreateStoreDomain>();
builder.Services.AddScoped<UpdateStoreDomain>();

builder.Services.AddScoped<DriverListDomain>();
builder.Services.AddScoped<CreateDriverDomain>();
builder.Services.AddScoped<UpdateDriverLocationDomain>();

builder.Services.AddScoped<ProductListDomain>();
builder.Services.AddScoped<CreateProductDomain>();
builder.Services.AddScoped<UpdateProductDomain>();
builder.Services.AddScoped<UploadProductPhotoDomain>();

builder.Services.AddScoped<CreateOrderDomain>();
builder.Services.AddScoped<StoreOrdersListDomain>();
builder.Services.AddScoped<AvailableOrdersForDriverDomain>();
builder.Services.AddScoped<ActiveOrderForDriverDomain>();
builder.Services.AddScoped<AcceptOrderDomain>();
builder.Services.AddScoped<CompleteOrderDomain>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors();
app.UseStaticFiles();
app.MapControllers();

app.Run();
