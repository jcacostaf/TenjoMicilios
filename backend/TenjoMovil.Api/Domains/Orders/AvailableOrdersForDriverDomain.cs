using TenjoMovil.Api.Abstractions.Drivers;
using TenjoMovil.Api.Abstractions.Orders;
using TenjoMovil.Api.Abstractions.Stores;
using TenjoMovil.Api.Entities;

namespace TenjoMovil.Api.Domains.Orders;

public enum AvailableOrdersStatus
{
    Success,
    DriverNotFound
}

public record OrderItemDto(string ProductName, decimal UnitPrice, int Quantity);

public record AvailableOrderDto(
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
    double? DistanceMeters);

public record AvailableOrdersResult(AvailableOrdersStatus Status, List<AvailableOrderDto>? Orders);

public class AvailableOrdersForDriverDomain(
    IDriverRepository driverRepo, IOrderQueries orderQueries, IStoreQueries storeQueries)
{
    public async Task<AvailableOrdersResult> GetAvailableAsync(int driverId, CancellationToken ct)
    {
        var driver = await driverRepo.GetByIdAsync(driverId, ct);
        if (driver is null)
        {
            return new AvailableOrdersResult(AvailableOrdersStatus.DriverNotFound, null);
        }

        var availableOrders = await orderQueries.ListAvailableForDriversAsync(ct);
        var storesById = (await storeQueries.ListAsync(ct)).ToDictionary(s => s.Id);

        var orders = availableOrders
            .Select(order =>
            {
                storesById.TryGetValue(order.StoreId, out var store);
                double? distance = store?.Latitude is not null && store.Longitude is not null
                    ? DistanceMeters(driver.Latitude, driver.Longitude, store.Latitude.Value, store.Longitude.Value)
                    : null;

                return new AvailableOrderDto(
                    order.Id, order.StoreId, store?.Name ?? "Tienda", store?.Address,
                    order.DeliveryAddressText, order.RecipientName, order.Note, order.Total,
                    order.Items.Select(i => new OrderItemDto(i.ProductName, i.UnitPrice, i.Quantity)).ToList(),
                    order.Status, order.CreatedAt, distance);
            })
            .OrderBy(dto => dto.DistanceMeters ?? double.MaxValue)
            .ToList();

        return new AvailableOrdersResult(AvailableOrdersStatus.Success, orders);
    }

    private static double DistanceMeters(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusMeters = 6_371_000;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return earthRadiusMeters * c;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;
}
