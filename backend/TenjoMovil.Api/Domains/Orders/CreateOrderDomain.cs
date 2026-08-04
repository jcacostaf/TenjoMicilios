using TenjoMovil.Api.Abstractions;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Abstractions.Products;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum CreateOrderStatus
{
    Success,
    EmptyOrder,
    ProductNotFound
}

public record CreateOrderItemRequest(int? ProductId, string? ProductName, decimal? UnitPrice, int Quantity);
public record CreateOrderResult(CreateOrderStatus Status, Order? Order);

public class CreateOrderDomain(IOrderRepository orderRepo, IProductRepository productRepo, IUnitOfWork uow)
{
    public async Task<CreateOrderResult> CreateAsync(
        int storeId,
        string? deliveryAddressText,
        string? recipientName,
        string? note,
        List<CreateOrderItemRequest> itemRequests,
        CancellationToken ct)
    {
        if (itemRequests.Count == 0)
        {
            return new CreateOrderResult(CreateOrderStatus.EmptyOrder, null);
        }

        var items = new List<OrderItem>();
        foreach (var itemRequest in itemRequests)
        {
            if (itemRequest.ProductId is int productId)
            {
                var product = await productRepo.GetByIdAsync(productId, ct);
                if (product is null)
                {
                    return new CreateOrderResult(CreateOrderStatus.ProductNotFound, null);
                }

                items.Add(new OrderItem
                {
                    ProductId = product.Id,
                    ProductName = product.Name,
                    UnitPrice = product.Price,
                    Quantity = itemRequest.Quantity
                });
            }
            else
            {
                items.Add(new OrderItem
                {
                    ProductId = null,
                    ProductName = itemRequest.ProductName ?? "Item",
                    UnitPrice = itemRequest.UnitPrice ?? 0,
                    Quantity = itemRequest.Quantity
                });
            }
        }

        var order = new Order
        {
            StoreId = storeId,
            DeliveryAddressText = deliveryAddressText,
            RecipientName = recipientName,
            Note = note,
            Total = items.Sum(i => i.UnitPrice * i.Quantity),
            Items = items
        };

        await uow.BeginAsync(ct);
        try
        {
            await orderRepo.AddAsync(order, ct);
            await uow.CommitAsync(ct);
            return new CreateOrderResult(CreateOrderStatus.Success, order);
        }
        catch
        {
            await uow.RollbackAsync(ct);
            throw;
        }
    }
}
