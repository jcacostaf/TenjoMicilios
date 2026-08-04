using Microsoft.AspNetCore.Mvc;
using TenjoMovil.Api.Domains.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Controllers;

[ApiController]
[Route("api/stores")]
public class StoresController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromServices] StoreListDomain domain, CancellationToken ct)
    {
        var stores = await domain.GetStoresAsync(ct);
        return Ok(stores);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] Store store, [FromServices] CreateStoreDomain domain, CancellationToken ct)
    {
        var result = await domain.CreateAsync(store, ct);
        return Created($"/api/stores/{result.Store!.Id}", result.Store);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(
        int id, [FromBody] Store changes, [FromServices] UpdateStoreDomain domain, CancellationToken ct)
    {
        var result = await domain.UpdateAsync(id, changes, ct);
        return result.Status switch
        {
            UpdateStoreStatus.NotFound => NotFound(),
            UpdateStoreStatus.Success => Ok(result.Store),
            _ => Problem()
        };
    }
}
