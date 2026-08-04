using Microsoft.AspNetCore.Mvc;
using TenjoMovil.Api.Domains.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Controllers;

[ApiController]
[Route("api")]
public class ProductsController : ControllerBase
{
    [HttpGet("stores/{storeId:int}/products")]
    public async Task<IActionResult> ListByStore(
        int storeId, [FromServices] ProductListDomain domain, CancellationToken ct)
    {
        var products = await domain.GetByStoreAsync(storeId, ct);
        return Ok(products);
    }

    [HttpPost("stores/{storeId:int}/products")]
    public async Task<IActionResult> Create(
        int storeId, [FromBody] Product product, [FromServices] CreateProductDomain domain, CancellationToken ct)
    {
        var result = await domain.CreateAsync(storeId, product, ct);
        return Created($"/api/products/{result.Product!.Id}", result.Product);
    }

    [HttpPut("products/{id:int}")]
    public async Task<IActionResult> Update(
        int id, [FromBody] Product changes, [FromServices] UpdateProductDomain domain, CancellationToken ct)
    {
        var result = await domain.UpdateAsync(id, changes, ct);
        return result.Status switch
        {
            UpdateProductStatus.NotFound => NotFound(),
            UpdateProductStatus.Success => Ok(result.Product),
            _ => Problem()
        };
    }

    [HttpPost("products/{id:int}/photo")]
    [DisableRequestSizeLimit]
    public async Task<IActionResult> UploadPhoto(
        int id, IFormFile file, [FromServices] UploadProductPhotoDomain domain, CancellationToken ct)
    {
        await using var stream = file.OpenReadStream();
        var result = await domain.UploadAsync(id, stream, file.Length, file.FileName, ct);

        return result.Status switch
        {
            UploadProductPhotoStatus.NotFound => NotFound(),
            UploadProductPhotoStatus.EmptyFile => Problem(detail: "Archivo vacio.", statusCode: StatusCodes.Status400BadRequest),
            UploadProductPhotoStatus.TooLarge => Problem(detail: "La foto supera el limite de 5MB.", statusCode: StatusCodes.Status400BadRequest),
            UploadProductPhotoStatus.UnsupportedFormat => Problem(detail: "Formato no soportado. Usa JPG, PNG o WEBP.", statusCode: StatusCodes.Status400BadRequest),
            UploadProductPhotoStatus.Success => Ok(result.Product),
            _ => Problem()
        };
    }
}
