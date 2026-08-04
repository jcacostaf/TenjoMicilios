using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Queries;

public class StoreQueries(AppDbContext db) : IStoreQueries
{
    public Task<List<Store>> ListAsync(CancellationToken ct) =>
        db.Stores.ToListAsync(ct);
}
