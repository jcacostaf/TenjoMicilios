using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Repositories;

public class ProductRepository(AppDbContext db) : IProductRepository
{
    public async Task AddAsync(Product product, CancellationToken ct) =>
        await db.Products.AddAsync(product, ct);

    public async Task<Product?> GetByIdAsync(int id, CancellationToken ct) =>
        await db.Products.FindAsync([id], ct);
}
