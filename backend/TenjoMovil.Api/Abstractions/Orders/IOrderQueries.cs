using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Orders;

public interface IOrderQueries
{
    /// <summary>Pedidos sin conductor asignado que ya fueron confirmados por el restaurante (Preparando o Listo).</summary>
    Task<List<Order>> ListAvailableForDriversAsync(CancellationToken ct);
    Task<List<Order>> ListByStoreAsync(int storeId, CancellationToken ct);
}
