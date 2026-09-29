# terraform {
#   required_providers {
#     docker = {
#       source  = "kreuzwerker/docker"
#       version = "~> 3.0.2"
#     }
#   }
# }

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
  required_version = "~> 1.7"
}

provider "docker" {
  # For Windows & macOS, the provider automatically locates the local Docker Desktop daemon.
  # If you hit connection issues on Linux/macOS, uncomment the line below:
  # host = "unix:///var/run/docker.sock"
  host = "npipe:////.//pipe//docker_engine"
}

# Pulls the image
resource "docker_image" "web" {
  # name         = "nginx:alpine"
  name         = var.image_name
  keep_locally = true
}

# Creates the container
resource "docker_container" "web" {
  image = docker_image.web.image_id
  # name  = "tutorial-nginx-container"
  name = var.container_name

  ports {
    internal = 80
    # external = 8081
    external = var.external_port
  }

  # Pass environment variables as a list of "KEY=VALUE" strings
  env = [
    "APP_ENV=production",
    "API_SECRET_KEY=${var.api_key}"
  ]
}
