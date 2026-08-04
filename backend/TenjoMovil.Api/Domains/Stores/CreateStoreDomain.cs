using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Stores;

public enum CreateStoreStatus
{
    Success
}

public record CreateStoreResult(CreateStoreStatus Status, Store? Store);

public class CreateStoreDomain(IStoreRepository storeRepo, IUnitOfWork uow)
{
    public async Task<CreateStoreResult> CreateAsync(Store store, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            await storeRepo.AddAsync(store, ct);
            await uow.CommitAsync(ct);
            return new CreateStoreResult(CreateStoreStatus.Success, store);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
