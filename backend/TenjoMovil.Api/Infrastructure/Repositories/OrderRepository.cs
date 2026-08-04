using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Repositories;

public class OrderRepository(AppDbContext db) : IOrderRepository
{
    public async Task AddAsync(Order order, CancellationToken ct) =>
        await db.Orders.AddAsync(order, ct);

    public Task<Order?> GetByIdAsync(int id, CancellationToken ct) =>
        db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id, ct);

    public Task<Order?> GetActiveByDriverAsync(int driverId, CancellationToken ct) =>
        db.Orders.Include(o => o.Items).FirstOrDefaultAsync(
            o => o.DriverId == driverId && o.Status != OrderStatus.Entregado, ct);

    public async Task<bool> TryClaimAsync(int orderId, int driverId, DateTime acceptedAt, CancellationToken ct)
    {
        var rows = await db.Orders
            .Where(o => o.Id == orderId && o.DriverId == null &&
                        (o.Status == OrderStatus.Preparando || o.Status == OrderStatus.Listo))
            .ExecuteUpdateAsync(s => s
                .SetProperty(o => o.DriverId, driverId)
                .SetProperty(o => o.AcceptedAt, acceptedAt), ct);

        return rows == 1;
    }

    public async Task<bool> TryPickUpAsync(int orderId, int driverId, DateTime pickedUpAt, CancellationToken ct)
    {
        var rows = await db.Orders
            .Where(o => o.Id == orderId && o.DriverId == driverId && o.Status == OrderStatus.Listo)
            .ExecuteUpdateAsync(s => s
                .SetProperty(o => o.Status, OrderStatus.EnCamino)
                .SetProperty(o => o.PickedUp, true)
                .SetProperty(o => o.PickedUpAt, pickedUpAt), ct);

        return rows == 1;
    }
}
