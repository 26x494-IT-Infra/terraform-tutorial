variable "image_name" {
  type        = string
  description = "The Docker image name and tag to pull"
  default     = "nginx:alpine"
}

variable "container_name" {
  type        = string
  description = "The custom name for the local container"
  default     = "we-server"
}

variable "external_port" {
  type        = number
  description = "The local host port to map to the container"
  default     = 8088
}

variable "api_key" {
  type        = string
  description = "The secret API key for the application"
  sensitive   = true # Blocks terminal logging
}
