using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Stores;

public class StoreListDomain(IStoreQueries storeQueries)
{
    public Task<List<Store>> GetStoresAsync(CancellationToken ct) =>
        storeQueries.ListAsync(ct);
}
