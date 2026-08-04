using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Stores;

public enum UpdateStoreStatus
{
    Success,
    NotFound
}

public record UpdateStoreResult(UpdateStoreStatus Status, Store? Store);

public class UpdateStoreDomain(IStoreRepository storeRepo, IUnitOfWork uow)
{
    public async Task<UpdateStoreResult> UpdateAsync(int id, Store changes, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var store = await storeRepo.GetByIdAsync(id, ct);
            if (store is null)
            {
                await uow.RollbackAsync(ct);
                return new UpdateStoreResult(UpdateStoreStatus.NotFound, null);
            }

            store.Name = changes.Name;
            store.Address = changes.Address;
            store.Phone = changes.Phone;
            store.Category = changes.Category;
            store.Latitude = changes.Latitude;
            store.Longitude = changes.Longitude;

            await uow.CommitAsync(ct);
            return new UpdateStoreResult(UpdateStoreStatus.Success, store);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
