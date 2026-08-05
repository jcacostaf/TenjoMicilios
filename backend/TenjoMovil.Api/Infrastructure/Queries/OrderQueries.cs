using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Queries;

public class OrderQueries(AppDbContext db) : IOrderQueries
{
    public Task<List<Order>> ListAvailableForDriversAsync(CancellationToken ct) =>
        db.Orders.Include(o => o.Items)
            .Where(o => o.DriverId == null &&
                        (o.Status == OrderStatus.Preparando || o.Status == OrderStatus.Listo))
            .ToListAsync(ct);

    public Task<List<Order>> ListByStoreAsync(int storeId, CancellationToken ct) =>
        db.Orders.Include(o => o.Items)
            .Where(o => o.StoreId == storeId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(ct);

    public Task<Order?> GetByIdAsync(int id, CancellationToken ct) =>
        db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id, ct);
}
