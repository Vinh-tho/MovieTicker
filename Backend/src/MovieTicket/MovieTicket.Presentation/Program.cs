using MovieTicket.Infrastructure.AppDbContext;
using MovieTicket.Application.IServices;
using MovieTicket.Application.Services;
using MovieTicket.Domain.IReponsitories.IMovie;
using MovieTicket.Infrastructure.Repositories.CinemaRepository;
using MovieTicket.Infrastructure.Repositories.MovieRespository;
using MovieTicket.Infrastructure.Repositories.AuthRespository;
using MovieTicket.Infrastructure.Services.IServices;
using MovieTicket.Infrastructure.Services.Implementations;
using MovieTicket.Domain.IResponsitories.IAuth;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Data.SqlClient;
using DotNetEnv;
using Serilog;
using MovieTicket.Application.Services.Implementations.Movie;
using MovieTicket.Application.Services.IServices.IMovie;
using MovieTicket.Domain.IResponsitories.ICinema;
using MovieTicket.Application.Services.Implementations.Cinema;
using MovieTicket.Application.Services.IServices.ICinema;

// Load .env from common run locations.
var currentDirectory = Directory.GetCurrentDirectory();
var envCandidates = new[]
{
    Path.Combine(currentDirectory, ".env"),
    Path.GetFullPath(Path.Combine(currentDirectory, "..", ".env")),
    Path.GetFullPath(Path.Combine(currentDirectory, "..", "..", ".env"))
};

var envFile = envCandidates.FirstOrDefault(File.Exists);
if (!string.IsNullOrWhiteSpace(envFile))
{
    Env.Load(envFile);
}

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("Logs/MovieTicketLog-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);
    builder.Host.UseSerilog();

    // Override configuration with environment variables.
    var config = builder.Configuration;
    config.AddEnvironmentVariables();

    // Build connection string: prefer DB_* vars from .env, fallback to appsettings.
    var envDbServer = Environment.GetEnvironmentVariable("DB_SERVER");
    var envDbName = Environment.GetEnvironmentVariable("DB_NAME");
    var envDbUser = Environment.GetEnvironmentVariable("DB_USER");
    var envDbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
    var envDbEncrypt = Environment.GetEnvironmentVariable("DB_ENCRYPT") ?? "false";
    var envTrustedConnection = Environment.GetEnvironmentVariable("DB_TRUSTED_CONNECTION") ?? "false";

    var hasEnvDbConfig = !string.IsNullOrWhiteSpace(envDbServer)
        && !string.IsNullOrWhiteSpace(envDbName);

    var connectionString = hasEnvDbConfig
        ? BuildConnectionStringFromEnv(
            envDbServer!,
            envDbName!,
            envDbUser,
            envDbPassword,
            envDbEncrypt,
            envTrustedConnection)
        : (config.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Thieu cau hinh ConnectionStrings:DefaultConnection hoac bien DB_* trong .env"));

// =====================================================
// DEPENDENCY INJECTION
// =====================================================

// Repositories
builder.Services.AddScoped<IAccountRepository, AccountRepository>();
builder.Services.AddScoped<IOtpRepository, OtpRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
builder.Services.AddScoped<ILoginHistoryRepository, LoginHistoryRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAccountRoleRepository, AccountRoleRepository>();
builder.Services.AddScoped<IRoleRepository, RoleRepository>();

// Services
builder.Services.AddScoped<IPasswordHashService, PasswordHashService>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IOtpService, OtpService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();

builder.Services.AddScoped<IMovieRepository,MovieRepository>();
builder.Services.AddScoped<IMoviePubService, MoviePubService>();

builder.Services.AddScoped<ICinemaRepository, CinemaRepository>();
builder.Services.AddScoped<ICinemaShowtimeRepository, CinemaShowtimeRepository>();
builder.Services.AddScoped<ICinemaPubService, CinemaPubService>();

// Background Tasks
builder.Services.AddHostedService<AccountCleanupService>();

// DbContext
builder.Services.AddDbContext<AppMovieTickerDbContext>(options =>
    options.UseSqlServer(connectionString));

// =====================================================
// AUTHENTICATION - JWT
// =====================================================
var jwtSecretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") ?? 
                   builder.Configuration["Jwt:SecretKey"] ?? 
                   "MyVeryLongSecretKeyForJwtTokenThatIsAtLeast32Characters!@#";
                   
var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER") ?? 
                builder.Configuration["Jwt:Issuer"] ?? 
                "MovieTicketApp";
                
var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE") ?? 
                  builder.Configuration["Jwt:Audience"] ?? 
                  "MovieTicketUsers";

if (string.IsNullOrEmpty(jwtSecretKey))
    throw new InvalidOperationException("JWT SecretKey khÃ´ng Ä‘Æ°á»£c cáº¥u hÃ¬nh");

var key = Encoding.ASCII.GetBytes(jwtSecretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = jwtIssuer,
        ValidateAudience = true,
        ValidAudience = jwtAudience,
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

// =====================================================
// CORS
// =====================================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// =====================================================
// CONTROLLERS & SWAGGER
// =====================================================
builder.Services.AddControllers();
builder.Services.AddMemoryCache();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "MovieTicket API", Version = "v1" });
    
    // Add JWT Authorization to Swagger
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Please enter token",
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        BearerFormat = "JWT",
        Scheme = "bearer"
    });
    
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] { }
        }
    });
});

// =====================================================
// BUILD
// =====================================================
var app = builder.Build();

// Apply EF Core migrations only when explicitly enabled.
var autoMigrate = bool.TryParse(Environment.GetEnvironmentVariable("DB_AUTO_MIGRATE"), out var shouldMigrate)
    && shouldMigrate;

if (autoMigrate)
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppMovieTickerDbContext>();
    dbContext.Database.Migrate();
}

// =====================================================
// MIDDLEWARE
// =====================================================
app.UseStaticFiles();

// Map /assets to the real Backend/Assets folder.
var contentRoot = builder.Environment.ContentRootPath;
var assetsCandidates = new[]
{
    Path.GetFullPath(Path.Combine(contentRoot, "..", "..", "..", "Assets")),
    Path.GetFullPath(Path.Combine(contentRoot, "..", "Assets"))
};

var assetsPath = assetsCandidates.FirstOrDefault(Directory.Exists) ?? assetsCandidates[0];
if (!Directory.Exists(assetsPath))
{
    Directory.CreateDirectory(assetsPath);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(assetsPath),
    RequestPath = "/assets"
});

app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.ConfigObject.PersistAuthorization = true;
});

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

static string BuildConnectionStringFromEnv(
    string server,
    string database,
    string? user,
    string? password,
    string encryptRaw,
    string trustedConnectionRaw)
{
    var useTrustedConnection = bool.TryParse(trustedConnectionRaw, out var trusted) && trusted;
    var encrypt = bool.TryParse(encryptRaw, out var enc) && enc;

    var builder = new SqlConnectionStringBuilder
    {
        DataSource = server,
        InitialCatalog = database,
        Encrypt = encrypt,
        TrustServerCertificate = true
    };

    if (useTrustedConnection)
    {
        builder.IntegratedSecurity = true;
    }
    else
    {
        if (string.IsNullOrWhiteSpace(user) || string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException("DB_USER va DB_PASSWORD bat buoc khi DB_TRUSTED_CONNECTION=false.");
        }

        builder.UserID = user;
        builder.Password = password;
    }

    return builder.ConnectionString;
}

