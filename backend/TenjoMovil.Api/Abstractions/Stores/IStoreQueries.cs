using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Stores;

public interface IStoreQueries
{
    Task<List<Store>> ListAsync(CancellationToken ct);
}
