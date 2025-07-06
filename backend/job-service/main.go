package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/proxima/job-service/internal/config"
	"github.com/proxima/job-service/internal/database"
	"github.com/proxima/job-service/internal/handlers"
	"github.com/proxima/job-service/internal/middleware"
	"github.com/proxima/job-service/internal/repository"
	"github.com/proxima/job-service/internal/service"
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
	jobRepo := repository.NewJobRepository(db)
	applicationRepo := repository.NewApplicationRepository(db)
	contractRepo := repository.NewContractRepository(db)
	skillRepo := repository.NewSkillRepository(db)

	// Initialize services
	jobService := service.NewJobService(jobRepo, skillRepo)
	applicationService := service.NewApplicationService(applicationRepo, jobRepo)
	contractService := service.NewContractService(contractRepo)

	// Initialize handlers
	jobHandler := handlers.NewJobHandler(jobService)
	applicationHandler := handlers.NewApplicationHandler(applicationService)
	contractHandler := handlers.NewContractHandler(contractService)

	// Setup router
	router := setupRouter(jobHandler, applicationHandler, contractHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8002"
	}

	log.Printf("Job Service starting on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func setupRouter(
	jobHandler *handlers.JobHandler,
	applicationHandler *handlers.ApplicationHandler,
	contractHandler *handlers.ContractHandler,
) *gin.Engine {
	router := gin.Default()

	// Middleware
	router.Use(middleware.CORS())
	router.Use(middleware.Logger())
	router.Use(middleware.ErrorHandler())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "job-service",
		})
	})

	// API routes
	api := router.Group("/api/v1")
	{
		// Job routes
		jobs := api.Group("/jobs")
		{
			jobs.GET("", jobHandler.ListJobs)
			jobs.GET("/:id", jobHandler.GetJob)
			jobs.POST("", middleware.AuthRequired(), jobHandler.CreateJob)
			jobs.PUT("/:id", middleware.AuthRequired(), jobHandler.UpdateJob)
			jobs.DELETE("/:id", middleware.AuthRequired(), jobHandler.DeleteJob)
			jobs.GET("/search", jobHandler.SearchJobs)
			jobs.GET("/featured", jobHandler.GetFeaturedJobs)
		}

		// Application routes
		applications := api.Group("/applications")
		applications.Use(middleware.AuthRequired())
		{
			applications.GET("", applicationHandler.ListApplications)
			applications.GET("/:id", applicationHandler.GetApplication)
			applications.POST("", applicationHandler.CreateApplication)
			applications.PUT("/:id", applicationHandler.UpdateApplication)
			applications.DELETE("/:id", applicationHandler.DeleteApplication)
			applications.PUT("/:id/status", applicationHandler.UpdateApplicationStatus)
		}

		// Contract routes
		contracts := api.Group("/contracts")
		contracts.Use(middleware.AuthRequired())
		{
			contracts.GET("", contractHandler.ListContracts)
			contracts.GET("/:id", contractHandler.GetContract)
			contracts.POST("", contractHandler.CreateContract)
			contracts.PUT("/:id", contractHandler.UpdateContract)
			contracts.PUT("/:id/status", contractHandler.UpdateContractStatus)
		}

		// Skills routes
		skills := api.Group("/skills")
		{
			skills.GET("", jobHandler.ListSkills)
			skills.GET("/categories", jobHandler.GetSkillCategories)
		}

		// Admin routes
		admin := api.Group("/admin")
		admin.Use(middleware.AuthRequired())
		admin.Use(middleware.AdminRequired())
		{
			admin.GET("/jobs", jobHandler.AdminListJobs)
			admin.GET("/applications", applicationHandler.AdminListApplications)
			admin.GET("/contracts", contractHandler.AdminListContracts)
			admin.GET("/stats", jobHandler.GetJobStats)
		}
	}

	return router
}
