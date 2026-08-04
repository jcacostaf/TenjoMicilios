using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Products;

public class ProductListDomain(IProductQueries productQueries)
{
    public Task<List<Product>> GetByStoreAsync(int storeId, CancellationToken ct) =>
        productQueries.ListByStoreAsync(storeId, ct);
}
