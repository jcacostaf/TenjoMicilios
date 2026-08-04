namespace TenjoMovil.Api.Entities;

public class Driver
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
