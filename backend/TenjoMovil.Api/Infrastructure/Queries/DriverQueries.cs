using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Entities;
using TenjoMovil.Api.Infrastructure.Persistence;

namespace TenjoMovil.Api.Infrastructure.Queries;

public class DriverQueries(AppDbContext db) : IDriverQueries
{
    public Task<List<Driver>> ListAsync(CancellationToken ct) =>
        db.Drivers.ToListAsync(ct);
}
