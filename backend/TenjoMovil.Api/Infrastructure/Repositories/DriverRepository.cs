using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Repositories;

public class DriverRepository(AppDbContext db) : IDriverRepository
{
    public async Task<Driver?> GetByIdAsync(int id, CancellationToken ct) =>
        await db.Drivers.FindAsync([id], ct);

    public async Task AddAsync(Driver driver, CancellationToken ct) =>
        await db.Drivers.AddAsync(driver, ct);
}
