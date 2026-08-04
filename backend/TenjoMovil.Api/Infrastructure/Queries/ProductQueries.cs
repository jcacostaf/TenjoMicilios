using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Queries;

public class ProductQueries(AppDbContext db) : IProductQueries
{
    public Task<List<Product>> ListByStoreAsync(int storeId, CancellationToken ct) =>
        db.Products.Where(p => p.StoreId == storeId).ToListAsync(ct);
}
