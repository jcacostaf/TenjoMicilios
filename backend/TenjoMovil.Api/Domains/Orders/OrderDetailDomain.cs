using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public record OrderDetailDto(
    int Id,
    int StoreId,
    string StoreName,
    OrderStatus Status,
    string? DeliveryAddressText,
    string? RecipientName,
    string? Note,
    decimal Total,
    List<OrderItemDto> Items,
    DateTime CreatedAt,
    DateTime? ConfirmedAt,
    DateTime? ReadyAt,
    DateTime? DeliveredAt);

public class OrderDetailDomain(IOrderQueries orderQueries, IStoreRepository storeRepo)
{
    public async Task<OrderDetailDto?> GetByIdAsync(int id, CancellationToken ct)
    {
        var order = await orderQueries.GetByIdAsync(id, ct);
        if (order is null)
        {
            return null;
        }

        var store = await storeRepo.GetByIdAsync(order.StoreId, ct);
        return new OrderDetailDto(
            order.Id, order.StoreId, store?.Name ?? "Tienda", order.Status,
            order.DeliveryAddressText, order.RecipientName, order.Note, order.Total,
            order.Items.Select(i => new OrderItemDto(i.ProductName, i.UnitPrice, i.Quantity)).ToList(),
            order.CreatedAt, order.ConfirmedAt, order.ReadyAt, order.DeliveredAt);
    }
}
