using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Orders;

public interface IOrderRepository
{
    Task AddAsync(Order order, CancellationToken ct);
    Task<Order?> GetByIdAsync(int id, CancellationToken ct);
    Task<Order?> GetActiveByDriverAsync(int driverId, CancellationToken ct);

    /// <summary>
    /// Atomically asigna el pedido a un conductor solo si sigue Pendiente.
    /// Devuelve false si otro conductor ya lo tomo (o el pedido no existe).
    /// </summary>
    Task<bool> TryClaimAsync(int orderId, int driverId, DateTime acceptedAt, CancellationToken ct);
}

