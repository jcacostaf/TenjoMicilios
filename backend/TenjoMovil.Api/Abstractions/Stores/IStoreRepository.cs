using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Stores;

public interface IStoreRepository
{
    Task AddAsync(Store store, CancellationToken ct);
    Task<Store?> GetByIdAsync(int id, CancellationToken ct);
}
