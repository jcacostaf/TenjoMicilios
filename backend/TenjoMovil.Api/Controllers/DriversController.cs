using Microsoft.AspNetCore.Mvc;
using TenjoMovil.Api.Domains.Drivers;

namespace TenjoMovil.Api.Controllers;

public record DriverLocationUpdate(double Latitude, double Longitude, string? Name);

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
}
