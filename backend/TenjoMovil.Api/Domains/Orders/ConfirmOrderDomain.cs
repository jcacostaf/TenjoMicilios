using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum ConfirmOrderStatus
{
    Success,
    NotFound,
    InvalidStatus
}

public record ConfirmOrderResult(ConfirmOrderStatus Status, Order? Order);

/// <summary>El restaurante confirma que recibio el pedido y lo empieza a preparar.</summary>
public class ConfirmOrderDomain(IOrderRepository orderRepo, IUnitOfWork uow)
{
    public async Task<ConfirmOrderResult> ConfirmAsync(int orderId, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var order = await orderRepo.GetByIdAsync(orderId, ct);
            if (order is null)
            {
                await uow.RollbackAsync(ct);
                return new ConfirmOrderResult(ConfirmOrderStatus.NotFound, null);
            }
            if (order.Status != OrderStatus.Pendiente)
            {
                await uow.RollbackAsync(ct);
                return new ConfirmOrderResult(ConfirmOrderStatus.InvalidStatus, null);
            }

            order.Status = OrderStatus.Preparando;
            order.ConfirmedAt = DateTime.UtcNow;

            await uow.CommitAsync(ct);
            return new ConfirmOrderResult(ConfirmOrderStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
