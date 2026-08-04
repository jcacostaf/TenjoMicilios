using Microsoft.AspNetCore.Mvc;
using TenjoMovil.Api.Domains.Drivers;
using TenjoMovil.Api.Domains.Orders;

namespace TenjoMovil.Api.Controllers;

public record DriverLocationUpdate(double Latitude, double Longitude, string? Name);
public record CreateDriverRequest(string Name);

[ApiController]
[Route("api/drivers")]
public class DriversController : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List([FromServices] DriverListDomain domain, CancellationToken ct)
    {
        var drivers = await domain.GetDriversAsync(ct);
        return Ok(drivers);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateDriverRequest request, [FromServices] CreateDriverDomain domain, CancellationToken ct)
    {
        var result = await domain.CreateAsync(request.Name, ct);
        return Created($"/api/drivers/{result.Driver.Id}", result.Driver);
    }

    [HttpPost("{id:int}/location")]
    public async Task<IActionResult> UpdateLocation(
        int id,
        [FromBody] DriverLocationUpdate update,
        [FromServices] UpdateDriverLocationDomain domain,
        CancellationToken ct)
    {
        var result = await domain.UpdateAsync(id, update.Latitude, update.Longitude, update.Name, ct);
        return Ok(result.Driver);
    }

    [HttpGet("{id:int}/available-orders")]
    public async Task<IActionResult> AvailableOrders(
        int id, [FromServices] AvailableOrdersForDriverDomain domain, CancellationToken ct)
    {
        var result = await domain.GetAvailableAsync(id, ct);
        return result.Status switch
        {
            AvailableOrdersStatus.DriverNotFound => NotFound(),
            AvailableOrdersStatus.Success => Ok(result.Orders),
            _ => Problem()
        };
    }

    [HttpGet("{id:int}/active-order")]
    public async Task<IActionResult> ActiveOrder(
        int id, [FromServices] ActiveOrderForDriverDomain domain, CancellationToken ct)
    {
        var order = await domain.GetActiveAsync(id, ct);
        return Ok(order);
    }
}
