using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Drivers;

public enum CreateDriverStatus
{
    Success
}

public record CreateDriverResult(CreateDriverStatus Status, Driver Driver);

public class CreateDriverDomain(IDriverRepository driverRepo, IUnitOfWork uow)
{
    public async Task<CreateDriverResult> CreateAsync(string name, CancellationToken ct)
    {
        var driver = new Driver { Name = name };

        await uow.BeginAsync(ct);
        try
        {
            await driverRepo.AddAsync(driver, ct);
            await uow.CommitAsync(ct);
            return new CreateDriverResult(CreateDriverStatus.Success, driver);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
