namespace TenjoMovil.Api.Entities;

public enum OrderStatus
{
    Pendiente,
    Aceptado,
    Entregado
}

public class Order
{
    public int Id { get; set; }
    public int StoreId { get; set; }
    public int? DriverId { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pendiente;
    public bool PickedUp { get; set; }
    public string? DeliveryAddressText { get; set; }
    public string? RecipientName { get; set; }
    public string? Note { get; set; }
    public decimal Total { get; set; }
    public List<OrderItem> Items { get; set; } = [];
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? AcceptedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
}
