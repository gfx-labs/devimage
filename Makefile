.PHONY: build push clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  build   - Build the devimage using Docker"
	@echo "  push    - Push the image to Docker Hub"
	@echo "  clean   - Clean up Docker build cache"
	@echo "  help    - Show this help message"

# Build the Docker image
build:
	@echo "Building devimage with Docker..."
	docker build -t devimage:latest .

# Push the image to Docker Hub (requires login)
push: build
	@echo "Pushing image to Docker Hub..."
	docker push devimage:latest

# Clean up Docker build cache
clean:
	@echo "Cleaning up Docker build cache..."
	docker system prune -f