.PHONY: help build up down restart logs shell clean migrate collectstatic superuser test

# Default target
help:
	@echo "Available commands:"
	@echo "  build        - Build Docker images"
	@echo "  up           - Start development environment"
	@echo "  up-prod      - Start production environment"
	@echo "  down         - Stop all containers"
	@echo "  restart      - Restart all containers"
	@echo "  logs         - Show logs from all containers"
	@echo "  shell        - Open shell in web container"
	@echo "  clean        - Remove all containers and volumes"
	@echo "  migrate      - Run database migrations"
	@echo "  collectstatic - Collect static files"
	@echo "  superuser    - Create Django superuser"
	@echo "  test         - Run Django tests"

# Build Docker images
build:
	docker-compose -f docker-compose.dev.yml build

# Start development environment
up:
	docker-compose -f docker-compose.dev.yml up -d

# Start production environment
up-prod:
	docker-compose --profile production up -d

# Stop all containers
down:
	docker-compose -f docker-compose.dev.yml down

# Restart all containers
restart:
	docker-compose -f docker-compose.dev.yml restart

# Show logs from all containers
logs:
	docker-compose -f docker-compose.dev.yml logs -f

# Open shell in web container
shell:
	docker-compose -f docker-compose.dev.yml exec web bash

# Remove all containers and volumes
clean:
	docker-compose -f docker-compose.dev.yml down -v
	docker container prune -f
	docker volume prune -f

# Run database migrations
migrate:
	docker-compose -f docker-compose.dev.yml exec web python manage.py migrate

# Collect static files
collectstatic:
	docker-compose -f docker-compose.dev.yml exec web python manage.py collectstatic --noinput

# Create Django superuser
superuser:
	docker-compose -f docker-compose.dev.yml exec web python manage.py createsuperuser

# Run Django tests
test:
	docker-compose -f docker-compose.dev.yml exec web python manage.py test

# Development helpers
dev-shell:
	docker-compose -f docker-compose.dev.yml exec web python manage.py shell

dev-check:
	docker-compose -f docker-compose.dev.yml exec web python manage.py check

dev-makemigrations:
	docker-compose -f docker-compose.dev.yml exec web python manage.py makemigrations

# Database operations
db-backup:
	docker-compose -f docker-compose.dev.yml exec web python manage.py dumpdata > backup_$(shell date +%Y%m%d_%H%M%S).json

db-restore:
	docker-compose -f docker-compose.dev.yml exec web python manage.py loaddata $(file)
