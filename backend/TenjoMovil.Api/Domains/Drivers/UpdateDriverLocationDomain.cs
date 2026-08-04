using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Drivers;

public enum UpdateDriverLocationStatus
{
    Success
}

public record UpdateDriverLocationResult(UpdateDriverLocationStatus Status, Driver Driver);

public class UpdateDriverLocationDomain(IDriverRepository driverRepo, IUnitOfWork uow)
{
    public async Task<UpdateDriverLocationResult> UpdateAsync(
        int id, double latitude, double longitude, string? name, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var driver = await driverRepo.GetByIdAsync(id, ct);
            if (driver is null)
            {
                driver = new Driver { Id = id, Name = name ?? $"Conductor {id}" };
                await driverRepo.AddAsync(driver, ct);
            }

            driver.Latitude = latitude;
            driver.Longitude = longitude;
            driver.UpdatedAt = DateTime.UtcNow;

            await uow.CommitAsync(ct);
            return new UpdateDriverLocationResult(UpdateDriverLocationStatus.Success, driver);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
