using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum AcceptOrderStatus
{
    Success,
    NotFound,
    AlreadyTaken,
    DriverHasActiveOrder
}

public record AcceptOrderResult(AcceptOrderStatus Status, Order? Order);

public class AcceptOrderDomain(IOrderRepository orderRepo, IUnitOfWork uow)
{
    public async Task<AcceptOrderResult> AcceptAsync(int orderId, int driverId, CancellationToken ct)
    {
        var order = await orderRepo.GetByIdAsync(orderId, ct);
        if (order is null)
        {
            return new AcceptOrderResult(AcceptOrderStatus.NotFound, null);
        }
        if (order.Status != OrderStatus.Pendiente)
        {
            return new AcceptOrderResult(AcceptOrderStatus.AlreadyTaken, null);
        }

        var activeOrder = await orderRepo.GetActiveByDriverAsync(driverId, ct);
        if (activeOrder is not null)
        {
            return new AcceptOrderResult(AcceptOrderStatus.DriverHasActiveOrder, null);
        }

        var acceptedAt = DateTime.UtcNow;

        await uow.BeginAsync(ct);
        try
        {
            // Update atomico condicionado a Status == Pendiente: si dos conductores
            // aceptan al mismo tiempo, solo uno gana la carrera (ver escenario 12
            // en docs/especificacion-logistica-repartidores.md).
            var claimed = await orderRepo.TryClaimAsync(orderId, driverId, acceptedAt, ct);
            await uow.CommitAsync(ct);

            if (!claimed)
            {
                return new AcceptOrderResult(AcceptOrderStatus.AlreadyTaken, null);
            }

            order.DriverId = driverId;
            order.Status = OrderStatus.Aceptado;
            order.AcceptedAt = acceptedAt;
            return new AcceptOrderResult(AcceptOrderStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
