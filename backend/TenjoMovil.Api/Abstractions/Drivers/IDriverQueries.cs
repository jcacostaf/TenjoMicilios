using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Abstractions.Drivers;

public interface IDriverQueries
{
    Task<List<Driver>> ListAsync(CancellationToken ct);
}
