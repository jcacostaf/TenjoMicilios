namespace TenjoMovil.Api.Entities;

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }

    /// <summary>Null si es un item suelto que no viene del catalogo.</summary>
    public int? ProductId { get; set; }

    /// <summary>Copia del nombre al momento del pedido, no cambia si el producto cambia despues.</summary>
    public string ProductName { get; set; } = string.Empty;

    /// <summary>Copia del precio al momento del pedido, no cambia si el producto cambia despues.</summary>
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
}
