namespace TenjoMovil.Api.Entities;

public enum OrderStatus
{
    /// <summary>Recien creado, el restaurante todavia no lo confirmo.</summary>
    Pendiente,

    /// <summary>El restaurante lo confirmo y lo esta preparando. Visible para conductores desde aqui.</summary>
    Preparando,

    /// <summary>El restaurante termino de prepararlo, listo para recoger.</summary>
    Listo,

    /// <summary>El conductor ya lo recogio y va camino al destino.</summary>
    EnCamino,

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
    public DateTime? ConfirmedAt { get; set; }
    public DateTime? ReadyAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
}
