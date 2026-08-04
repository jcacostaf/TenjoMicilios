using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum CompleteOrderStatus
{
    Success,
    NotFound,
    NotOwnedByDriver,
    NotPickedUp
}

public record CompleteOrderResult(CompleteOrderStatus Status, Order? Order);

public class CompleteOrderDomain(IOrderRepository orderRepo, IUnitOfWork uow)
{
    public async Task<CompleteOrderResult> CompleteAsync(int orderId, int driverId, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var order = await orderRepo.GetByIdAsync(orderId, ct);
            if (order is null)
            {
                await uow.RollbackAsync(ct);
                return new CompleteOrderResult(CompleteOrderStatus.NotFound, null);
            }
            if (order.DriverId != driverId)
            {
                await uow.RollbackAsync(ct);
                return new CompleteOrderResult(CompleteOrderStatus.NotOwnedByDriver, null);
            }
            if (order.Status != OrderStatus.EnCamino)
            {
                await uow.RollbackAsync(ct);
                return new CompleteOrderResult(CompleteOrderStatus.NotPickedUp, null);
            }

            order.Status = OrderStatus.Entregado;
            order.DeliveredAt = DateTime.UtcNow;

            await uow.CommitAsync(ct);
            return new CompleteOrderResult(CompleteOrderStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
