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
            o => o.DriverId == driverId && o.Status == OrderStatus.Aceptado, ct);

    public async Task<bool> TryClaimAsync(int orderId, int driverId, DateTime acceptedAt, CancellationToken ct)
    {
        var rows = await db.Orders
            .Where(o => o.Id == orderId && o.Status == OrderStatus.Pendiente)
            .ExecuteUpdateAsync(s => s
                .SetProperty(o => o.DriverId, driverId)
                .SetProperty(o => o.Status, OrderStatus.Aceptado)
                .SetProperty(o => o.AcceptedAt, acceptedAt), ct);

        return rows == 1;
    }
}
