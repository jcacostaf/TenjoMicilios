using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public record ActiveOrderDto(
    int OrderId,
    int StoreId,
    string StoreName,
    string? StoreAddress,
    string? DeliveryAddressText,
    string? RecipientName,
    string? Note,
    decimal Total,
    List<OrderItemDto> Items,
    OrderStatus Status,
    DateTime CreatedAt,
    DateTime? AcceptedAt);

public class ActiveOrderForDriverDomain(IOrderRepository orderRepo, IStoreRepository storeRepo)
{
    public async Task<ActiveOrderDto?> GetActiveAsync(int driverId, CancellationToken ct)
    {
        var order = await orderRepo.GetActiveByDriverAsync(driverId, ct);
        if (order is null)
        {
            return null;
        }

        var store = await storeRepo.GetByIdAsync(order.StoreId, ct);
        return new ActiveOrderDto(
            order.Id, order.StoreId, store?.Name ?? "Tienda", store?.Address,
            order.DeliveryAddressText, order.RecipientName, order.Note, order.Total,
            order.Items.Select(i => new OrderItemDto(i.ProductName, i.UnitPrice, i.Quantity)).ToList(),
            order.Status, order.CreatedAt, order.AcceptedAt);
    }
}
