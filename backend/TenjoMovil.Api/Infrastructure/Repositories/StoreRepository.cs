using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Repositories;

public class StoreRepository(AppDbContext db) : IStoreRepository
{
    public async Task AddAsync(Store store, CancellationToken ct) =>
        await db.Stores.AddAsync(store, ct);

    public async Task<Store?> GetByIdAsync(int id, CancellationToken ct) =>
        await db.Stores.FindAsync([id], ct);
}
