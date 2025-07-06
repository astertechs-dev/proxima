package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/proxima/user-service/internal/config"
	"github.com/proxima/user-service/internal/database"
	"github.com/proxima/user-service/internal/handlers"
	"github.com/proxima/user-service/internal/middleware"
	"github.com/proxima/user-service/internal/repository"
	"github.com/proxima/user-service/internal/service"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Initialize Redis
	redisClient := database.ConnectRedis(cfg.RedisURL)

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	freelancerRepo := repository.NewFreelancerRepository(db)
	companyRepo := repository.NewCompanyRepository(db)

	// Initialize services
	authService := service.NewAuthService(userRepo, redisClient, cfg.JWTSecret)
	userService := service.NewUserService(userRepo, freelancerRepo, companyRepo)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	userHandler := handlers.NewUserHandler(userService, authService)

	// Setup router
	router := setupRouter(authHandler, userHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	log.Printf("User Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func setupRouter(authHandler *handlers.AuthHandler, userHandler *handlers.UserHandler) *gin.Engine {
	router := gin.Default()

	// Middleware
	router.Use(middleware.CORS())
	router.Use(middleware.Logger())
	router.Use(middleware.ErrorHandler())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "user-service",
		})
	})

	// API routes
	api := router.Group("/api/v1")
	{
		// Authentication routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", middleware.AuthRequired(), authHandler.Logout)
		}

		// User routes
		users := api.Group("/users")
		users.Use(middleware.AuthRequired())
		{
			users.GET("/profile", userHandler.GetProfile)
			users.PUT("/profile", userHandler.UpdateProfile)
			users.POST("/skills", userHandler.AddSkills)
			users.DELETE("/skills/:skillId", userHandler.RemoveSkill)
			users.GET("/availability", userHandler.GetAvailability)
			users.PUT("/availability", userHandler.UpdateAvailability)
		}

		// Admin routes
		admin := api.Group("/admin")
		admin.Use(middleware.AuthRequired())
		admin.Use(middleware.AdminRequired())
		{
			admin.GET("/users", userHandler.ListUsers)
			admin.GET("/users/:id", userHandler.GetUserByID)
			admin.PUT("/users/:id/status", userHandler.UpdateUserStatus)
		}
	}

	return router
}
