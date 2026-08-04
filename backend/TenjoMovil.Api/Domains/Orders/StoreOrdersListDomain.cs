using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public class StoreOrdersListDomain(IOrderQueries orderQueries)
{
    public Task<List<Order>> GetByStoreAsync(int storeId, CancellationToken ct) =>
        orderQueries.ListByStoreAsync(storeId, ct);
}
