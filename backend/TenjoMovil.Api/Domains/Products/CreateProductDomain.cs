using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Products;

public enum CreateProductStatus
{
    Success
}

public record CreateProductResult(CreateProductStatus Status, Product? Product);

public class CreateProductDomain(IProductRepository productRepo, IUnitOfWork uow)
{
    public async Task<CreateProductResult> CreateAsync(int storeId, Product product, CancellationToken ct)
    {
        product.StoreId = storeId;

        await uow.BeginAsync(ct);
        try
        {
            await productRepo.AddAsync(product, ct);
            await uow.CommitAsync(ct);
            return new CreateProductResult(CreateProductStatus.Success, product);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
