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

    [HttpGet("orders/{id:int}")]
    public async Task<IActionResult> GetById(
        int id, [FromServices] OrderDetailDomain domain, CancellationToken ct)
    {
        var order = await domain.GetByIdAsync(id, ct);
        return order is null ? NotFound() : Ok(order);
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

    [HttpPost("orders/{id:int}/confirm")]
    public async Task<IActionResult> Confirm(
        int id, [FromServices] ConfirmOrderDomain domain, CancellationToken ct)
    {
        var result = await domain.ConfirmAsync(id, ct);
        return result.Status switch
        {
            ConfirmOrderStatus.NotFound => NotFound(),
            ConfirmOrderStatus.InvalidStatus => Problem(detail: "Este pedido ya fue confirmado.", statusCode: StatusCodes.Status409Conflict),
            ConfirmOrderStatus.Success => Ok(result.Order),
            _ => Problem()
        };
    }

    [HttpPost("orders/{id:int}/ready")]
    public async Task<IActionResult> Ready(
        int id, [FromServices] MarkOrderReadyDomain domain, CancellationToken ct)
    {
        var result = await domain.MarkReadyAsync(id, ct);
        return result.Status switch
        {
            MarkOrderReadyStatus.NotFound => NotFound(),
            MarkOrderReadyStatus.InvalidStatus => Problem(detail: "Este pedido no esta en preparacion.", statusCode: StatusCodes.Status409Conflict),
            MarkOrderReadyStatus.Success => Ok(result.Order),
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

    [HttpPost("orders/{id:int}/pickup")]
    public async Task<IActionResult> PickUp(
        int id, [FromBody] OrderDriverRequest request, [FromServices] PickUpOrderDomain domain, CancellationToken ct)
    {
        var result = await domain.PickUpAsync(id, request.DriverId, ct);
        return result.Status switch
        {
            PickUpOrderStatus.NotFound => NotFound(),
            PickUpOrderStatus.NotOwnedByDriver => Problem(detail: "Este pedido no esta asignado a este conductor.", statusCode: StatusCodes.Status409Conflict),
            PickUpOrderStatus.NotReady => Problem(detail: "Este pedido todavia no esta listo para recoger.", statusCode: StatusCodes.Status409Conflict),
            PickUpOrderStatus.Success => Ok(result.Order),
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
            CompleteOrderStatus.NotPickedUp => Problem(detail: "Primero debes marcar que recogiste el pedido.", statusCode: StatusCodes.Status409Conflict),
            CompleteOrderStatus.Success => Ok(result.Order),
            _ => Problem()
        };
    }
}
