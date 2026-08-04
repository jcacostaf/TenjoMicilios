using Microsoft.AspNetCore.Hosting;
using TenjoMovil.Api.Abstractions.Products;

namespace TenjoMovil.Api.Infrastructure.Storage;

public class ProductImageStorage(IWebHostEnvironment env) : IProductImageStorage
{
    public async Task<string> SaveAsync(Stream content, int productId, string extension, CancellationToken ct)
    {
        var uploadsPath = Path.Combine(env.WebRootPath, "uploads");
        Directory.CreateDirectory(uploadsPath);

        var fileName = $"product-{productId}-{Guid.NewGuid()}{extension}";
        var filePath = Path.Combine(uploadsPath, fileName);

        await using var stream = File.Create(filePath);
        await content.CopyToAsync(stream, ct);

        return $"/uploads/{fileName}";
    }
}
