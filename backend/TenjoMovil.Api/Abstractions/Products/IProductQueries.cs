using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Products;

public interface IProductQueries
{
    Task<List<Product>> ListByStoreAsync(int storeId, CancellationToken ct);
}
