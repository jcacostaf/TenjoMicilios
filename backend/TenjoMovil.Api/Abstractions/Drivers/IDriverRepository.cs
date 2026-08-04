using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Drivers;

public interface IDriverRepository
{
    Task<Driver?> GetByIdAsync(int id, CancellationToken ct);
    Task AddAsync(Driver driver, CancellationToken ct);
}
