using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Infrastructure.Persistence;
using TenjoMovil.Api.Infrastructure.Queries;
using TenjoMovil.Api.Infrastructure.Repositories;
using TenjoMovil.Api.Infrastructure.Storage;

namespace TenjoMovil.Api.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(config.GetConnectionString("DefaultConnection")));

        services.AddScoped<UnitOfWork>();
        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<UnitOfWork>());

        services.AddScoped<IStoreRepository, StoreRepository>();
        services.AddScoped<IStoreQueries, StoreQueries>();

        services.AddScoped<IDriverRepository, DriverRepository>();
        services.AddScoped<IDriverQueries, DriverQueries>();

        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<IProductQueries, ProductQueries>();
        services.AddScoped<IProductImageStorage, ProductImageStorage>();

        return services;
    }
}
