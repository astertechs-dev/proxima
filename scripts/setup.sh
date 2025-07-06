#!/bin/bash

# Proxima Development Environment Setup Script

set -e

echo "🚀 Setting up Proxima development environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs
mkdir -p data/postgres
mkdir -p data/mongodb
mkdir -p data/redis

# Set permissions
chmod +x scripts/*.sh

# Copy environment files if they don't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update the .env file with your configuration before running the services."
fi

# Build and start services
echo "🔨 Building Docker images..."
docker-compose build

echo "🗄️  Starting database services..."
docker-compose up -d postgres mongodb redis

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
sleep 10

# Check database connections
echo "🔍 Checking database connections..."
docker-compose exec postgres pg_isready -U proxima_user -d proxima || echo "⚠️  PostgreSQL not ready yet"
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')" || echo "⚠️  MongoDB not ready yet"
docker-compose exec redis redis-cli ping || echo "⚠️  Redis not ready yet"

echo "✅ Database services are running!"
echo ""
echo "🎯 Next steps:"
echo "1. Update the .env file with your configuration"
echo "2. Run 'docker-compose up' to start all services"
echo "3. Access the application at http://localhost:3000"
echo "4. Access the API Gateway at http://localhost:8080"
echo ""
echo "📚 Available services:"
echo "- Frontend (Next.js): http://localhost:3000"
echo "- API Gateway: http://localhost:8080"
echo "- User Service: http://localhost:8001"
echo "- Job Service: http://localhost:8002"
echo "- Match Service: http://localhost:8003"
echo "- AI Service: http://localhost:8004"
echo "- PostgreSQL: localhost:5432"
echo "- MongoDB: localhost:27017"
echo "- Redis: localhost:6379"
echo ""
echo "🔧 Development commands:"
echo "- Start all services: docker-compose up"
echo "- Start in background: docker-compose up -d"
echo "- Stop all services: docker-compose down"
echo "- View logs: docker-compose logs -f [service-name]"
echo "- Rebuild services: docker-compose build"
echo ""
echo "🎉 Setup completed successfully!"
