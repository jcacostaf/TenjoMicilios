using Microsoft.EntityFrameworkCore;
using TenjoMovil.Api.Models;

namespace TenjoMovil.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Store> Stores => Set<Store>();
    public DbSet<Driver> Drivers => Set<Driver>();
}
