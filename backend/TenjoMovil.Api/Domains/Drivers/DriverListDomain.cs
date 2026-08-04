using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Drivers;

public class DriverListDomain(IDriverQueries driverQueries)
{
    public Task<List<Driver>> GetDriversAsync(CancellationToken ct) =>
        driverQueries.ListAsync(ct);
}
