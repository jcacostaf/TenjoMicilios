using Microsoft.AspNetCore.Mvc;
using TenjoMovil.Api.Domains.Orders;

namespace TenjoMovil.Api.Controllers;

public record CreateOrderRequest(
    string? DeliveryAddressText,
    string? RecipientName,
    string? Note,
    List<CreateOrderItemRequest> Items);
public record OrderDriverRequest(int DriverId);

[ApiController]
[Route("api")]
public class OrdersController : ControllerBase
{
    [HttpGet("stores/{storeId:int}/orders")]
    public async Task<IActionResult> ListByStore(
        int storeId, [FromServices] StoreOrdersListDomain domain, CancellationToken ct)
    {
        var orders = await domain.GetByStoreAsync(storeId, ct);
        return Ok(orders);
    }

    [HttpPost("stores/{storeId:int}/orders")]
    public async Task<IActionResult> Create(
        int storeId, [FromBody] CreateOrderRequest request, [FromServices] CreateOrderDomain domain, CancellationToken ct)
    {
        var result = await domain.CreateAsync(
            storeId, request.DeliveryAddressText, request.RecipientName, request.Note, request.Items, ct);

        return result.Status switch
        {
            CreateOrderStatus.EmptyOrder => Problem(detail: "El pedido debe tener al menos un producto.", statusCode: StatusCodes.Status400BadRequest),
            CreateOrderStatus.ProductNotFound => Problem(detail: "Uno de los productos ya no existe.", statusCode: StatusCodes.Status400BadRequest),
            CreateOrderStatus.Success => Created($"/api/orders/{result.Order!.Id}", result.Order),
            _ => Problem()
        };
    }

    [HttpPost("orders/{id:int}/accept")]
    public async Task<IActionResult> Accept(
        int id, [FromBody] OrderDriverRequest request, [FromServices] AcceptOrderDomain domain, CancellationToken ct)
    {
        var result = await domain.AcceptAsync(id, request.DriverId, ct);
        return result.Status switch
        {
            AcceptOrderStatus.NotFound => NotFound(),
            AcceptOrderStatus.AlreadyTaken => Problem(detail: "Este pedido ya no esta disponible.", statusCode: StatusCodes.Status409Conflict),
            AcceptOrderStatus.DriverHasActiveOrder => Problem(detail: "Ya tienes un pedido activo. Entregalo antes de aceptar otro.", statusCode: StatusCodes.Status409Conflict),
            AcceptOrderStatus.Success => Ok(result.Order),
            _ => Problem()
        };
    }

    [HttpPost("orders/{id:int}/complete")]
    public async Task<IActionResult> Complete(
        int id, [FromBody] OrderDriverRequest request, [FromServices] CompleteOrderDomain domain, CancellationToken ct)
    {
        var result = await domain.CompleteAsync(id, request.DriverId, ct);
        return result.Status switch
        {
            CompleteOrderStatus.NotFound => NotFound(),
            CompleteOrderStatus.NotOwnedByDriver => Problem(detail: "Este pedido no esta asignado a este conductor.", statusCode: StatusCodes.Status409Conflict),
            CompleteOrderStatus.NotAccepted => Problem(detail: "Este pedido no esta en curso.", statusCode: StatusCodes.Status409Conflict),
            CompleteOrderStatus.Success => Ok(result.Order),
            _ => Problem()
        };
    }
}
