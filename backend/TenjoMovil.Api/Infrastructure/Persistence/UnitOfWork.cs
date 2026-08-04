using TenjoMovil.Api.Abstractions;

namespace TenjoMovil.Api.Infrastructure.Persistence;

public sealed class UnitOfWork(AppDbContext db) : IUnitOfWork
{
    public async Task BeginAsync(CancellationToken ct)
    {
        if (db.Database.CurrentTransaction is null)
            await db.Database.BeginTransactionAsync(ct);
    }

    public async Task CommitAsync(CancellationToken ct)
    {
        await db.SaveChangesAsync(ct);

        if (db.Database.CurrentTransaction is not null)
            await db.Database.CommitTransactionAsync(ct);
    }

    public async Task RollbackAsync(CancellationToken ct)
    {
        if (db.Database.CurrentTransaction is not null)
            await db.Database.RollbackTransactionAsync(ct);
    }
}
