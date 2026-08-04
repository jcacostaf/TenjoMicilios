namespace TenjoMovil.Api.Abstractions.Products;

public interface IProductImageStorage
{
    Task<string> SaveAsync(Stream content, int productId, string extension, CancellationToken ct);
}
