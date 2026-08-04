using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum PickUpOrderStatus
{
    Success,
    NotFound,
    NotOwnedByDriver,
    NotReady
}

public record PickUpOrderResult(PickUpOrderStatus Status, Order? Order);

/// <summary>El conductor confirma que ya recogio el pedido en la tienda y va camino al destino.</summary>
public class PickUpOrderDomain(IOrderRepository orderRepo, IUnitOfWork uow)
{
    public async Task<PickUpOrderResult> PickUpAsync(int orderId, int driverId, CancellationToken ct)
    {
        var order = await orderRepo.GetByIdAsync(orderId, ct);
        if (order is null)
        {
            return new PickUpOrderResult(PickUpOrderStatus.NotFound, null);
        }
        if (order.DriverId != driverId)
        {
            return new PickUpOrderResult(PickUpOrderStatus.NotOwnedByDriver, null);
        }
        if (order.Status != OrderStatus.Listo)
        {
            return new PickUpOrderResult(PickUpOrderStatus.NotReady, null);
        }

        var pickedUpAt = DateTime.UtcNow;

        await uow.BeginAsync(ct);
        try
        {
            var pickedUp = await orderRepo.TryPickUpAsync(orderId, driverId, pickedUpAt, ct);
            await uow.CommitAsync(ct);

            if (!pickedUp)
            {
                return new PickUpOrderResult(PickUpOrderStatus.NotReady, null);
            }

            order.Status = OrderStatus.EnCamino;
            order.PickedUp = true;
            order.PickedUpAt = pickedUpAt;
            return new PickUpOrderResult(PickUpOrderStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
