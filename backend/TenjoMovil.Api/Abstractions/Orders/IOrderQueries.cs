using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Orders;

public interface IOrderQueries
{
    Task<List<Order>> ListPendingAsync(CancellationToken ct);
    Task<List<Order>> ListByStoreAsync(int storeId, CancellationToken ct);
}
