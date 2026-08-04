using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum MarkOrderReadyStatus
{
    Success,
    NotFound,
    InvalidStatus
}

public record MarkOrderReadyResult(MarkOrderReadyStatus Status, Order? Order);

/// <summary>El restaurante marca que ya termino de preparar el pedido, listo para recoger.</summary>
public class MarkOrderReadyDomain(IOrderRepository orderRepo, IUnitOfWork uow)
{
    public async Task<MarkOrderReadyResult> MarkReadyAsync(int orderId, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var order = await orderRepo.GetByIdAsync(orderId, ct);
            if (order is null)
            {
                await uow.RollbackAsync(ct);
                return new MarkOrderReadyResult(MarkOrderReadyStatus.NotFound, null);
            }
            if (order.Status != OrderStatus.Preparando)
            {
                await uow.RollbackAsync(ct);
                return new MarkOrderReadyResult(MarkOrderReadyStatus.InvalidStatus, null);
            }

            order.Status = OrderStatus.Listo;
            order.ReadyAt = DateTime.UtcNow;

            await uow.CommitAsync(ct);
            return new MarkOrderReadyResult(MarkOrderReadyStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
