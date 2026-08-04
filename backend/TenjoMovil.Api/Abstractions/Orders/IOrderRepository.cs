using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Orders;

public interface IOrderRepository
{
    Task AddAsync(Order order, CancellationToken ct);
    Task<Order?> GetByIdAsync(int id, CancellationToken ct);
    Task<Order?> GetActiveByDriverAsync(int driverId, CancellationToken ct);

    /// <summary>
    /// Atomically asigna el pedido a un conductor solo si sigue sin asignar
    /// (Preparando o Listo). Devuelve false si otro conductor ya lo tomo.
    /// </summary>
    Task<bool> TryClaimAsync(int orderId, int driverId, DateTime acceptedAt, CancellationToken ct);

    /// <summary>
    /// Atomically marca el pedido como recogido (Listo -> EnCamino) solo si
    /// sigue asignado a este conductor y esta Listo.
    /// </summary>
    Task<bool> TryPickUpAsync(int orderId, int driverId, DateTime pickedUpAt, CancellationToken ct);
}
