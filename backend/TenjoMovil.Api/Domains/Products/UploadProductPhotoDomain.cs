using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Products;

public enum UploadProductPhotoStatus
{
    Success,
    NotFound,
    EmptyFile,
    TooLarge,
    UnsupportedFormat
}

public record UploadProductPhotoResult(UploadProductPhotoStatus Status, Product? Product);

public class UploadProductPhotoDomain(
    IProductRepository productRepo,
    IProductImageStorage imageStorage,
    IUnitOfWork uow)
{
    private const long MaxPhotoBytes = 5 * 1024 * 1024; // 5 MB
    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

    public async Task<UploadProductPhotoResult> UploadAsync(
        int productId, Stream content, long contentLength, string fileName, CancellationToken ct)
    {
        if (contentLength == 0)
            return new UploadProductPhotoResult(UploadProductPhotoStatus.EmptyFile, null);

        if (contentLength > MaxPhotoBytes)
            return new UploadProductPhotoResult(UploadProductPhotoStatus.TooLarge, null);

        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
            return new UploadProductPhotoResult(UploadProductPhotoStatus.UnsupportedFormat, null);

        await uow.BeginAsync(ct);
        try
        {
            var product = await productRepo.GetByIdAsync(productId, ct);
            if (product is null)
            {
                await uow.RollbackAsync(ct);
                return new UploadProductPhotoResult(UploadProductPhotoStatus.NotFound, null);
            }

            product.ImageUrl = await imageStorage.SaveAsync(content, productId, extension, ct);

            await uow.CommitAsync(ct);
            return new UploadProductPhotoResult(UploadProductPhotoStatus.Success, product);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
