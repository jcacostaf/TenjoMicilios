using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Products;

public enum UpdateProductStatus
{
    Success,
    NotFound
}

public record UpdateProductResult(UpdateProductStatus Status, Product? Product);

public class UpdateProductDomain(IProductRepository productRepo, IUnitOfWork uow)
{
    public async Task<UpdateProductResult> UpdateAsync(int id, Product changes, CancellationToken ct)
    {
        await uow.BeginAsync(ct);
        try
        {
            var product = await productRepo.GetByIdAsync(id, ct);
            if (product is null)
            {
                await uow.RollbackAsync(ct);
                return new UpdateProductResult(UpdateProductStatus.NotFound, null);
            }

            product.Name = changes.Name;
            product.Description = changes.Description;
            product.Price = changes.Price;
            product.IsActive = changes.IsActive;

            await uow.CommitAsync(ct);
            return new UpdateProductResult(UpdateProductStatus.Success, product);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
