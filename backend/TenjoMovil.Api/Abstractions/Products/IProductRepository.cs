using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Products;

public interface IProductRepository
{
    Task AddAsync(Product product, CancellationToken ct);
    Task<Product?> GetByIdAsync(int id, CancellationToken ct);
}
